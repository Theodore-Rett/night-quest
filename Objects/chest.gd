extends StaticBody2D

@export var chest_state: CHEST_STATE = CHEST_STATE.OPEN
@export var loot_amount: int = 0
@export var loot_type: LOOT_TYPE = LOOT_TYPE.GOLD
@export var prompt_distance: float = 100

enum CHEST_STATE {OPEN, LOCKED, LOOTED}
enum LOOT_TYPE {GOLD}

@onready var prompt_label: Label = $Label
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var chest_sprite: Sprite2D = $Sprite2D

var player: Node2D
var is_opening: bool = false

func _ready() -> void:
	player = _find_player()
	animation_tree.active = true
	if chest_state == CHEST_STATE.LOOTED:
		state_machine.travel("Open")
		chest_sprite.frame = 3
	else:
		state_machine.travel("Closed")
	_update_prompt_visibility()

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = _find_player()

	if Input.is_action_just_pressed("object_interaction") and _can_interact():
		_open_chest()

	_update_prompt_visibility()

func _can_interact() -> bool:
	if chest_state == CHEST_STATE.LOOTED or is_opening:
		return false

	if player == null or not is_instance_valid(player):
		return false

	var distance_to_player := global_position.distance_to(player.global_position)
	return distance_to_player <= prompt_distance


func _open_chest() -> void:
	is_opening = true
	prompt_label.visible = false
	state_machine.travel("Open")
	var open_duration := 0.1
	var open_animation := animation_player.get_animation("open_chest")
	if open_animation:
		open_duration = open_animation.length
	await get_tree().create_timer(open_duration).timeout
	chest_state = CHEST_STATE.LOOTED
	is_opening = false
	_update_prompt_visibility()


func _update_prompt_visibility() -> void:
	if chest_state == CHEST_STATE.LOOTED or is_opening:
		prompt_label.visible = false
		return

	if player == null or not is_instance_valid(player):
		prompt_label.visible = false
		return

	var distance_to_player := global_position.distance_to(player.global_position)
	prompt_label.visible = distance_to_player <= prompt_distance

func _find_player() -> Node2D:
	var grouped_player = get_tree().get_first_node_in_group("player")
	if grouped_player is Node2D:
		return grouped_player

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return null

	var named_player = current_scene.find_child("player", true, false)
	if named_player is Node2D:
		return named_player

	return null
