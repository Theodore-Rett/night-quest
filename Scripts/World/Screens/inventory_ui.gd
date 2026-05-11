extends Control

@onready var inv: Inventory = preload("res://Resources/inventory_player.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()

var is_open = false

func _ready():
	update_slots()
	close()

func update_slots():
	for i in range(min(inv.items.size(), slots.size())):
		slots[i].update(inv.items[i])

func _process(_delta):
	if Input.is_action_just_pressed("open_inventory"):
		if is_open:
			close()
		else:
			open()

	if is_open:
		update_slots()
	
func open():
	update_slots()
	visible = true
	is_open = true
	
func close():
	visible = false
	is_open = false
