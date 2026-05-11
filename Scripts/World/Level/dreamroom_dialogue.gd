extends Node2D

# Short one-off dialogue to run when the scene loads
@export var speaker_name: String = "???"
@export var portrait_path: String = "res://Assets/Entity/NPC/The Wizen Wizard/TheWizenWizardHeadshot.png"
@export var chunks: Array = ["Wake.....", "Wake..... up...", "Find me.", "Free me."]

func _ready() -> void:
	var dial = await _get_dialogue_box()
	if dial == null:
		return

	var finished_callable := Callable(self, "_on_intro_dialogue_finished")
	if not dial.dialogue_finished.is_connected(finished_callable):
		dial.dialogue_finished.connect(finished_callable, CONNECT_ONE_SHOT)

	var data := {
		"name": speaker_name,
		"portrait": load(portrait_path),
		"chunks": chunks,
	}
	dial.start_dialogue(data)

func _on_intro_dialogue_finished() -> void:
	var quest_log := _get_player_quest_log()
	if quest_log != null:
		quest_log.start_quest("escape", "Escape")

func _get_dialogue_box() -> Node:
	for i in range(20):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dial = player.get_node_or_null("PlayerOverlay/DialougeBoxInstance")
			if dial:
				return dial
		await get_tree().create_timer(0.1).timeout

	return null

func _get_player_quest_log() -> QuestLog:
	var player := _find_player()
	if player == null:
		return null

	return player.get("quest_log") as QuestLog

func _find_player() -> Node:
	var grouped_player = get_tree().get_first_node_in_group("player")
	if grouped_player != null:
		return grouped_player

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return null

	var named_player = current_scene.find_child("MC", true, false)
	if named_player != null:
		return named_player

	var fallback_player = current_scene.find_child("player", true, false)
	if fallback_player != null:
		return fallback_player

	return null
