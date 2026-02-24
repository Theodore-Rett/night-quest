extends CharacterBody2D

@export var speed : float = 400
@export var starting_direction : Vector2 = Vector2(0,1)
@export var max_health : int = 50
@export var current_health : int = 50
@export var attack_range : float = 80.0
@export var attack_damage : int = 10

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var animation_player = $AnimationPlayer

signal health_changed(new_health : int)

var knockback_timer : float = 0.0
var knockback_duration : float = 0.0
var knockback_velocity : Vector2 = Vector2.ZERO
var is_attacking : bool = false
var attack_timer : float = 0.0
var facing_direction : Vector2 = Vector2(0, 1)

func _ready():
	update_animation_parameters(starting_direction)
	facing_direction = starting_direction

func _physics_process(_delta):
	if knockback_timer > 0.0:
		knockback_timer -= _delta
		# Ease-out (quadratic): progress from 1 to 0
		var progress = knockback_timer / knockback_duration
		var eased_progress = progress * progress
		velocity = knockback_velocity * eased_progress
		move_and_slide()
		pick_new_state()
		return

	if is_attacking:
		attack_timer -= _delta
		velocity = Vector2.ZERO
		move_and_slide()
		if attack_timer > 0.0:
			return
		is_attacking = false
		pick_new_state()
		return

	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if Input.is_action_just_pressed("attack"):
		attack()
		return
	
	update_animation_parameters(input_direction)
	velocity = input_direction * speed
	
	move_and_slide()
	pick_new_state()

func attack():
	var mouse_position := get_global_mouse_position()
	var raw_direction := (mouse_position - global_position).normalized()
	if raw_direction == Vector2.ZERO:
		raw_direction = facing_direction

	var attack_direction := raw_direction
	if abs(raw_direction.x) >= abs(raw_direction.y):
		attack_direction = Vector2(sign(raw_direction.x), 0)
	else:
		attack_direction = Vector2(0, sign(raw_direction.y))

	var attack_animation_name := "attack_front"
	if attack_direction.x > 0:
		attack_animation_name = "attack_right"
	elif attack_direction.x < 0:
		attack_animation_name = "attack_left"
	elif attack_direction.y < 0:
		attack_animation_name = "attack_back"

	var selected_attack_animation = animation_player.get_animation(attack_animation_name)
	attack_timer = selected_attack_animation.length if selected_attack_animation else 0.1

	update_animation_parameters(attack_direction)
	state_machine.travel("Attack")
	is_attacking = true

	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_position
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit_results := get_world_2d().direct_space_state.intersect_point(query, 8)
	if hit_results.is_empty():
		return

	var best_target : Node2D = null
	var best_distance := INF

	for hit in hit_results:
		var collider = hit.collider
		if collider is Node2D and collider.is_in_group("enemies") and collider.has_method("take_damage"):
			var distance_to_target = global_position.distance_to(collider.global_position)
			if distance_to_target <= attack_range and distance_to_target < best_distance:
				best_distance = distance_to_target
				best_target = collider

	if best_target == null:
		return

	best_target.take_damage(attack_damage, global_position)
	

func update_animation_parameters(move_input : Vector2):
	#don't change if no input
	if(move_input != Vector2.ZERO):
		facing_direction = move_input
		animation_tree.set("parameters/Idle/blend_position", move_input)
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Attack/blend_position", move_input)

# switches between walk and idle animations
func pick_new_state():
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func take_damage(amount : int, attacker_position : Vector2 = Vector2.ZERO) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	knockback(attacker_position, 400)
	
	# Check if player died
	if current_health <= 0:
		get_tree().change_scene_to_file("res://Levels/GameOver.tscn")

func heal(amount : int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func knockback(attacker_position : Vector2, kb_force : float = 300):
	knockback_duration = 0.2
	var kb_direction = (global_position - attacker_position).normalized() * kb_force
	knockback_velocity = kb_direction
	knockback_timer = knockback_duration
