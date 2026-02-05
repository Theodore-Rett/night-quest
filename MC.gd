extends CharacterBody2D

@export var speed : float = 400
@export var starting_direction : Vector2 = Vector2(0,1)
@export var max_health : int = 50
@export var current_health : int = 50

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

signal health_changed(new_health : int)

func _ready():
	update_animation_parameters(starting_direction)

func _physics_process(_delta):
	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	update_animation_parameters(input_direction)
	velocity = input_direction * speed
	
	move_and_slide()
	pick_new_state()

func update_animation_parameters(move_input : Vector2):
	#don't change if no input
	if(move_input != Vector2.ZERO):
		animation_tree.set("parameters/Idle/blend_position", move_input)
		animation_tree.set("parameters/Walk/blend_position", move_input)

# switches between walk and idel animations
func pick_new_state():
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func take_damage(amount : int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	# Check if player died
	if current_health <= 0:
		get_tree().change_scene_to_file("res://Levels/GameOver.tscn")

func heal(amount : int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)
