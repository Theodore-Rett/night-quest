extends CharacterBody2D

@export var speed : float = 250
@export var stop_distance : float = 10
@export var detection_distance : float = 400
@export var max_health : int = 10
@export var current_health : int = 10

@export var attack_distance : float = 15
@export var attack_cooldown : float = 4.0
@export var attack_amount : float = 2.0

@export var player : Node2D

var attack_timer : float = 0.0

func _ready():
	add_to_group("enemies")

func _physics_process(_delta):
	if player:
		# Calculate direction vector towards player
		var direction = global_position.direction_to(player.global_position)
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var distance = global_position.distance_to(player.global_position)

		# Move only if outside the stopping distance
		if distance > stop_distance && distance < detection_distance:
			velocity = direction * speed
			move_and_slide()
		elif distance < stop_distance:
			# Back off a bit if overlapping to avoid sticking
			velocity = Vector2.ZERO
			move_and_slide()
		else:
			# Stop moving if close enough
			velocity = Vector2.ZERO

		# Attack if within attack distance
		attack_timer -= _delta
		if distance <= attack_distance && attack_timer <= 0:
			attack()
	
func attack() -> void:
	player.take_damage(attack_amount, global_position)
	attack_timer = attack_cooldown

func take_damage(amount : int, attacker_position : Vector2 = Vector2.ZERO) -> void:
	current_health = max(0, current_health - amount)
	if current_health <= 0:
		queue_free()
