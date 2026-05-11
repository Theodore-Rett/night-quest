extends CharacterBody2D

@export var speed : float = 400
@export var starting_direction : Vector2 = Vector2(0,1)
@export var max_health : int = 50
@export var current_health : int = 50
@export var attack_range : float = 80.0
@export var attack_damage : int = 10
@export var inv: Inventory
@export var quest_log: QuestLog
@export var default_walk_stream : AudioStream
@export var walk_stream_overrides : Dictionary = {}
@export var attack_stream : AudioStream

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var walk_audio_player: AudioStreamPlayer2D = $WalkAudio
@onready var attack_audio_player: AudioStreamPlayer2D = $AttackAudio
@onready var dialogue_controller = get_node_or_null("PlayerOverlay/DialougeBoxInstance")

signal health_changed(new_health : int)

var knockback_timer : float = 0.0
var knockback_duration : float = 0.0
var knockback_velocity : Vector2 = Vector2.ZERO
var is_attacking : bool = false
var current_attack_animation_name : StringName = &""
var facing_direction : Vector2 = Vector2(0, 1)
var current_walk_surface : StringName = &"default"
var controls_locked : bool = false

func _ready():
	add_to_group("player")
	update_animation_parameters(starting_direction)
	facing_direction = starting_direction
	ensure_walk_stream_looping()
	refresh_walk_audio()
	attack_audio_player.stream = attack_stream
	if not animation_tree.animation_finished.is_connected(_on_animation_tree_animation_finished):
		animation_tree.animation_finished.connect(_on_animation_tree_animation_finished)
	_bind_dialogue_lock()

func _bind_dialogue_lock() -> void:
	if dialogue_controller == null:
		return
	var started_callable := Callable(self, "_on_dialogue_started")
	var finished_callable := Callable(self, "_on_dialogue_finished")
	if not dialogue_controller.is_connected("dialogue_started", started_callable):
		dialogue_controller.connect("dialogue_started", started_callable)
	if not dialogue_controller.is_connected("dialogue_finished", finished_callable):
		dialogue_controller.connect("dialogue_finished", finished_callable)

func _on_dialogue_started() -> void:
	controls_locked = true
	velocity = Vector2.ZERO
	stop_walk_audio()
	state_machine.travel("Idle")

func _on_dialogue_finished() -> void:
	controls_locked = false

func _physics_process(_delta):
	if controls_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		state_machine.travel("Idle")
		stop_walk_audio()
		return

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
		velocity = Vector2.ZERO
		move_and_slide()
		pick_new_state()
		return

	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if Input.is_action_just_pressed("attack"):
		attack()
		pick_new_state()
		return
	
	update_animation_parameters(input_direction)
	velocity = input_direction * speed
	
	move_and_slide()
	pick_new_state()

func attack():
	if controls_locked:
		return

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

	current_attack_animation_name = StringName(attack_animation_name)
	update_animation_parameters(attack_direction)
	play_attack_audio()
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

func _on_animation_tree_animation_finished(anim_name : StringName) -> void:
	if not is_attacking:
		return
	if anim_name != current_attack_animation_name:
		return
	is_attacking = false
	pick_new_state()
	

func update_animation_parameters(move_input : Vector2):
	#don't change if no input
	if(move_input != Vector2.ZERO):
		facing_direction = move_input
		animation_tree.set("parameters/Idle/blend_position", move_input)
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Attack/blend_position", move_input)

# switches between walk and idle animations
func pick_new_state():
	if is_attacking:
		state_machine.travel("Attack")
		stop_walk_audio()
		return

	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if(input_direction != Vector2.ZERO):
		state_machine.travel("Walk")
		play_walk_audio()
	else:
		state_machine.travel("Idle")
		stop_walk_audio()

func set_walk_surface(surface_name : StringName) -> void:
	current_walk_surface = surface_name if surface_name != &"" else &"default"
	refresh_walk_audio()

func get_walk_stream_for_surface(surface_name : StringName = &"default") -> AudioStream:
	if surface_name != &"default" and walk_stream_overrides.has(surface_name):
		return walk_stream_overrides[surface_name]
	if walk_stream_overrides.has(&"default"):
		return walk_stream_overrides[&"default"]
	return default_walk_stream

func ensure_walk_stream_looping() -> void:
	if default_walk_stream is AudioStreamMP3:
		(default_walk_stream as AudioStreamMP3).loop = true
	for stream in walk_stream_overrides.values():
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true

func refresh_walk_audio() -> void:
	ensure_walk_stream_looping()
	var walk_stream := get_walk_stream_for_surface(current_walk_surface)
	if walk_audio_player.stream == walk_stream:
		return
	walk_audio_player.stream = walk_stream
	if state_machine and state_machine.get_current_node() == "Walk" and walk_stream != null:
		play_walk_audio()

func play_walk_audio() -> void:
	if walk_audio_player.stream == null:
		return
	if not walk_audio_player.playing:
		walk_audio_player.play()

func stop_walk_audio() -> void:
	if walk_audio_player.playing:
		walk_audio_player.stop()

func play_attack_audio() -> void:
	if attack_audio_player.stream == null:
		return
	attack_audio_player.play()

func take_damage(amount : int, attacker_position : Vector2 = Vector2.ZERO) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	knockback(attacker_position, 400)
	
	# Check if player died
	if current_health <= 0:
		get_tree().change_scene_to_file("res://Scenes/World/Screens/GameOver.tscn")

func heal(amount : int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func knockback(attacker_position : Vector2, kb_force : float = 300):
	knockback_duration = 0.2
	var kb_direction = (global_position - attacker_position).normalized() * kb_force
	knockback_velocity = kb_direction
	knockback_timer = knockback_duration
