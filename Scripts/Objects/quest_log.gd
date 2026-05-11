extends Resource

class_name QuestLog

signal quests_updated

@export var quests: Array[Quest] = []

func _find_quest(quest_id: String) -> Quest:
	for quest in quests:
		if quest != null and quest.id == quest_id:
			return quest
	return null

func ensure_quest(quest_id: String, title: String = "") -> Quest:
	var quest := _find_quest(quest_id)
	if quest != null:
		if title != "" and quest.title == "":
			quest.title = title
		return quest

	quest = Quest.new()
	quest.id = quest_id
	quest.title = title if title != "" else quest_id.capitalize()
	quests.append(quest)
	quests_updated.emit()
	return quest

func start_quest(quest_id: String, title: String = "") -> Quest:
	var quest := ensure_quest(quest_id, title)
	if quest.state == Quest.QuestState.COMPLETED:
		return quest

	if quest.state != Quest.QuestState.ACTIVE:
		quest.state = Quest.QuestState.ACTIVE
		quests_updated.emit()

	return quest

func complete_quest(quest_id: String, title: String = "") -> Quest:
	var quest := ensure_quest(quest_id, title)
	if quest.state != Quest.QuestState.COMPLETED:
		quest.state = Quest.QuestState.COMPLETED
		quests_updated.emit()
	return quest

func get_visible_quests() -> Array[Quest]:
	var visible_quests: Array[Quest] = []
	for quest in quests:
		if quest != null and quest.is_visible():
			visible_quests.append(quest)
	return visible_quests
