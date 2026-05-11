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
@export var default_move_stream : AudioStream

@onready var move_audio_player: AudioStreamPlayer2D = $MoveAudio

var attack_timer : float = 0.0
var knockback_timer : float = 0.0
var knockback_duration : float = 0.0
var knockback_velocity : Vector2 = Vector2.ZERO

func _ready():
	add_to_group("enemies")
	ensure_move_stream_looping()
	refresh_move_audio()

func _physics_process(_delta):
	if player:
		# knockback from any attacks
		if knockback_timer > 0.0:
			knockback_timer -= _delta
			# Ease-out (quadratic): progress from 1 to 0
			var progress = knockback_timer / knockback_duration
			var eased_progress = progress * progress
			velocity = knockback_velocity * eased_progress
			move_and_slide()
			stop_move_audio()
			return

		# Calculate direction vector towards player
		var direction = global_position.direction_to(player.global_position)
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var distance = global_position.distance_to(player.global_position)

		# Move only if outside the stopping distance
		if distance > stop_distance && distance < detection_distance:
			velocity = direction * speed
			move_and_slide()
			play_move_audio()
		elif distance < stop_distance:
			# Back off a bit if overlapping to avoid sticking
			velocity = Vector2.ZERO
			move_and_slide()
			stop_move_audio()
		else:
			# Stop moving if close enough
			velocity = Vector2.ZERO
			stop_move_audio()

		# Attack if within attack distance
		attack_timer -= _delta
		if distance <= attack_distance && attack_timer <= 0:
			attack()
	
func attack() -> void:
	player.take_damage(attack_amount, global_position)
	attack_timer = attack_cooldown

func take_damage(amount : int, attacker_position : Vector2 = Vector2.ZERO) -> void:
	current_health = max(0, current_health - amount)
	knockback(attacker_position, 400)
	if current_health <= 0:
		queue_free()

func knockback(attacker_position : Vector2, kb_force : float = 300):
	knockback_duration = 0.2
	var kb_direction = (global_position - attacker_position).normalized() * kb_force
	knockback_velocity = kb_direction
	knockback_timer = knockback_duration

func ensure_move_stream_looping() -> void:
	if default_move_stream is AudioStreamMP3:
		(default_move_stream as AudioStreamMP3).loop = true

func refresh_move_audio() -> void:
	ensure_move_stream_looping()
	move_audio_player.stream = default_move_stream

func play_move_audio() -> void:
	if move_audio_player.stream == null:
		return
	if not move_audio_player.playing:
		move_audio_player.play()

func stop_move_audio() -> void:
	if move_audio_player.playing:
		move_audio_player.stop()
