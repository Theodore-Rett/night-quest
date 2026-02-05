extends CharacterBody2D

@export var speed : float = 75
@export var stop_distance : float = 45
@export var detection_distance : float = 400

@export var attack_distance : float = 15
@export var attack_cooldown : float = 5
@export var attack_amount : float = 5

@export var player : Node2D

@onready var animation_tree = $AnimationTree
@onready var terror_shape: Shape2D = $CollisionShape2D.shape

var attack_timer : float = 0.0

func _physics_process(_delta):
	if player:
		# Calculate direction vector towards player
		var direction = global_position.direction_to(player.global_position)
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var distance = global_position.distance_to(player.global_position)
		
		var player_collision: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
		var player_shape: Shape2D = player_collision.shape if player_collision else null

		var min_distance := stop_distance
		if terror_shape and player_shape and terror_shape is CapsuleShape2D and player_shape is CapsuleShape2D:
			min_distance = (terror_shape as CapsuleShape2D).radius + (player_shape as CapsuleShape2D).radius + 4.0

		# Move only if outside the stopping distance
		if distance > min_distance && distance < detection_distance:
			velocity = direction * speed
			move_and_slide()
		elif distance < min_distance:
			# Back off a bit if overlapping to avoid sticking
			velocity = Vector2.ZERO
			move_and_slide()
		else:
			# Stop moving if close enough
			velocity = Vector2.ZERO
		update_animation_parameters(velocity)
	
		# Attack if within attack distance
		attack_timer -= _delta
		if distance <= attack_distance && attack_timer <= 0:
			attack()
			
func update_animation_parameters(move_input : Vector2):
	#don't change if no input
	if(move_input != Vector2.ZERO):
		animation_tree.set("parameters/float/blend_position", move_input)
		
func attack() -> void:
	player.take_damage(attack_amount)
	attack_timer = attack_cooldown
