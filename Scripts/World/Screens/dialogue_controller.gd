
extends Node

signal dialogue_started
signal dialogue_finished
signal chunk_changed(current_index)

@export var lock_player_movement: bool = true

# chunking
@export var chunk_char_limit: int = 240

# typewriter options
@export var typewriter_enabled: bool = false
@export var typewriter_speed: float = 0.02 # seconds per character

var is_open: bool = false
var _chunks: Array = []
var _index: int = 0
var _speaker: Dictionary = {}

# typewriter runtime
var _typewriter_active: bool = false
var _typewriter_cancel: bool = false

@onready var panel: Control = get_node_or_null("Panel") as Control
@onready var portrait: TextureRect = panel.find_child("Portrait", true, false) as TextureRect if panel else null
@onready var speaker_name: Label = panel.find_child("SpeakerName", true, false) as Label if panel else null
@onready var text_label: RichTextLabel = panel.find_child("DialogueText", true, false) as RichTextLabel if panel else null

func open() -> void:
	if panel:
		panel.visible = true
	is_open = true
	emit_signal("dialogue_started")

func close() -> void:
	if panel:
		panel.visible = false
	is_open = false
	_chunks = []
	_index = 0
	_speaker = {}
	_typewriter_active = false
	_typewriter_cancel = false
	emit_signal("dialogue_finished")

func start_dialogue(speaker_data: Dictionary) -> void:
	# speaker_data may contain: { "portrait": Texture, "name": String, "chunks": Array, "text": String }
	_speaker = speaker_data
	if speaker_data.has("chunks"):
		_chunks = speaker_data["chunks"]
	elif speaker_data.has("text"):
		_chunks = _chunk_text(str(speaker_data["text"]))
	else:
		_chunks = []

	_index = 0
	_apply_speaker()
	open()
	_show_current_chunk()

func _apply_speaker() -> void:
	if portrait and _speaker.has("portrait"):
		portrait.texture = _speaker["portrait"]
	if speaker_name and _speaker.has("name"):
		speaker_name.text = str(_speaker["name"])

func _chunk_text(text: String) -> Array:
	# Split by sentence-like boundaries, then merge into chunks by char limit
	var re := RegEx.new()
	var err := re.compile(r"(?<=[.!?])\s+")
	if err != OK:
		return [text]

	var parts: PackedStringArray = re.split(text)
	var chunks: Array = []
	var current := ""
	for part in parts:
		var p = str(part).strip_edges()
		if p.is_empty():
			continue
		if current == "":
			current = p
		else:
			if current.length() + 1 + p.length() <= chunk_char_limit:
				current += " " + p
			else:
				chunks.append(current.strip_edges())
				current = p

	if current != "":
		chunks.append(current.strip_edges())

	return chunks

func _show_current_chunk() -> void:
	if _index >= _chunks.size():
		close()
		return

	var chunk := str(_chunks[_index])
	if text_label:
		if typewriter_enabled:
			_start_typewriter(chunk)
		else:
			text_label.bbcode_text = chunk

	emit_signal("chunk_changed", _index)

func _start_typewriter(chunk: String) -> void:
	_typewriter_active = true
	_typewriter_cancel = false
	text_label.bbcode_text = ""

	var length := chunk.length()
	for i in range(length):
		if _typewriter_cancel:
			break
		text_label.bbcode_text += chunk.substr(i, 1)
		var t = get_tree().create_timer(typewriter_speed)
		await t.timeout

	if _typewriter_cancel:
		text_label.bbcode_text = chunk

	_typewriter_active = false
	_typewriter_cancel = false

func advance() -> void:
	if not is_open:
		return
	if _typewriter_active:
		# cancel typewriter and reveal immediately
		_typewriter_cancel = true
		return

	_index += 1
	_show_current_chunk()

func _unhandled_input(event) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		# if typewriter is active, cancel; otherwise advance
		if _typewriter_active:
			_typewriter_cancel = true
		else:
			advance()
