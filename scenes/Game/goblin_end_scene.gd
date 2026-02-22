extends BaseMenu

@export var goblins : Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AddGoblins(goblins)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func AddGoblins(goblins: Array[String]) -> void:
	$ColorRect/HBoxContainer/VBoxContainer/Goblins.AddGoblins(goblins)
	pass
