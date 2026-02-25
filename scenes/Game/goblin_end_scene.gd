extends BaseMenu
class_name DeathEndScene

@export var goblins: Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect/HBoxContainer/MemorialContainer.visible = false
	AddGoblins()
	pass # Replace with function body.


func AddGoblins() -> void:
	if (goblins.size() < 1):
		return
	
	$ColorRect/HBoxContainer/MemorialContainer.visible = true
	$ColorRect/HBoxContainer/MemorialContainer/Goblins.AddGoblins(goblins)
	pass
