extends StaticBody2D

@export var chest_state: CHEST_STATE = CHEST_STATE.OPEN
@export var loot_item: InventoryItem
@export var prompt_distance: float = 100

enum CHEST_STATE {OPEN, LOCKED, LOOTED}

@onready var prompt_label: Label = $Label
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var chest_sprite: Sprite2D = $Sprite2D

var player: Node2D
var is_opening: bool = false

func _get_player_inventory() -> Inventory:
	if player == null or not is_instance_valid(player):
		print("[Chest] _get_player_inventory failed: player missing/invalid")
		return null

	var player_node := player as CharacterBody2D
	if player_node == null:
		print("[Chest] _get_player_inventory failed: player is not CharacterBody2D")
		return null

	if not ("inv" in player_node):
		print("[Chest] _get_player_inventory failed: player has no inv property")
		return null

	if player_node.inv == null:
		print("[Chest] _get_player_inventory failed: player.inv is null")
		return null

	return player_node.inv

func _ready() -> void:
	player = _find_player()
	print("[Chest] ready: player=", player, " loot_item=", loot_item)
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
		if player != null:
			print("[Chest] player reacquired: ", player)

	if Input.is_action_just_pressed("object_interaction") and _can_interact():
		print("[Chest] interaction accepted -> opening")
		_open_chest()

	_update_prompt_visibility()

func _can_interact() -> bool:
	if chest_state == CHEST_STATE.LOOTED or is_opening:
		if chest_state == CHEST_STATE.LOOTED:
			print("[Chest] _can_interact blocked: already looted")
		if is_opening:
			print("[Chest] _can_interact blocked: currently opening")
		return false

	var inventory := _get_player_inventory()
	if inventory == null:
		print("[Chest] _can_interact blocked: no inventory")
		return false
	
	# Check if inventory is full
	if not inventory.can_add_item(loot_item):
		if loot_item == null:
			print("[Chest] _can_interact blocked: loot_item is null")
		else:
			print("[Chest] _can_interact blocked: no free slot for ", loot_item.name)
		return false

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player > prompt_distance:
		print("[Chest] _can_interact blocked: distance=", distance_to_player, " prompt_distance=", prompt_distance)
	return distance_to_player <= prompt_distance


func _open_chest() -> void:
	var inventory := _get_player_inventory()
	if inventory == null:
		print("[Chest] _open_chest aborted: inventory missing")
		return

	if loot_item == null:
		print("[Chest] _open_chest aborted: loot_item null")
		return

	if not inventory.can_add_item(loot_item):
		print("[Chest] _open_chest aborted: can_add_item false for ", loot_item.name)
		return

	print("[Chest] opening chest for item: ", loot_item.name)

	is_opening = true
	prompt_label.visible = false
	state_machine.travel("Open")
	var open_duration := 0.1
	var open_animation := animation_player.get_animation("open_chest")
	if open_animation:
		open_duration = open_animation.length
	await get_tree().create_timer(open_duration).timeout
	
	# Transfer item to player's inventory
	if not inventory.add_item(loot_item):
		print("[Chest] transfer failed after animation")
		is_opening = false
		state_machine.travel("Closed")
		_update_prompt_visibility()
		return

	print("[Chest] transfer succeeded")

	loot_item = null
	
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
