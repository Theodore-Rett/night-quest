extends ProgressBar

@export var player: Node2D

func _ready() -> void:
	# Auto-find player if not assigned
	if not player:
		# ProgressBar > Camera2D > Player
		player = get_parent().get_parent()
	
	# Initialize the progress bar with player's current health
	max_value = player.max_health
	value = player.current_health
	
	# Connect to player's health_changed signal
	player.health_changed.connect(_on_health_changed)

	_on_health_changed(player.current_health)

func _on_health_changed(new_health : int) -> void:
	value = new_health
	
	# adjust colors
	var style = StyleBoxFlat.new()
	if(value >= max_value*.75):
		style.bg_color = Color.GREEN
	elif(value >= max_value*.5):
		style.bg_color = Color.YELLOW
	elif(value >= max_value*.25):
		style.bg_color = Color.ORANGE
	else:
		style.bg_color = Color.RED
	
	add_theme_stylebox_override("fill", style)
