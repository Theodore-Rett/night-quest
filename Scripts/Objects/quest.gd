extends Resource

class_name Quest

enum QuestState {
	LOCKED,
	ACTIVE,
	COMPLETED,
}

@export var id: String = ""
@export var title: String = ""
@export var state: QuestState = QuestState.LOCKED

func is_visible() -> bool:
	return state != QuestState.LOCKED

func is_completed() -> bool:
	return state == QuestState.COMPLETED

func get_status_text() -> String:
	match state:
		QuestState.ACTIVE:
			return "Active"
		QuestState.COMPLETED:
			return "Completed"
		_:
			return "Locked"
