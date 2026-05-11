extends Control

@onready var quest_log: QuestLog = preload("res://Resources/quests_player.tres")
@onready var quest_list: VBoxContainer = $Panel/VBoxContainer

var is_open := false

func _ready() -> void:
	if quest_log != null:
		var updated_callable := Callable(self, "_on_quest_log_changed")
		if not quest_log.quests_updated.is_connected(updated_callable):
			quest_log.quests_updated.connect(updated_callable)
	update_quests()
	close()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_journal"):
		if is_open:
			close()
		else:
			open()

	if is_open:
		update_quests()

func _on_quest_log_changed() -> void:
	if is_open:
		update_quests()

func open() -> void:
	update_quests()
	visible = true
	is_open = true

func close() -> void:
	visible = false
	is_open = false

func update_quests() -> void:
	if quest_list == null:
		return

	for child in quest_list.get_children():
		child.queue_free()

	if quest_log == null:
		var empty_label := Label.new()
		empty_label.text = "No quests available."
		quest_list.add_child(empty_label)
		return

	var visible_quests := quest_log.get_visible_quests()
	if visible_quests.is_empty():
		var empty_state_label := Label.new()
		empty_state_label.text = "No active quests."
		quest_list.add_child(empty_state_label)
		return

	for quest in visible_quests:
		var quest_label := Label.new()
		var quest_name := quest.title if quest.title != "" else quest.id.capitalize()
		quest_label.text = "%s - %s" % [quest_name, quest.get_status_text()]
		if quest.is_completed():
			quest_label.modulate = Color(0.82, 1.0, 0.82)
		quest_list.add_child(quest_label)
