extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = ""
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func AddGoblins(goblins: Array[String]) -> void:
	
	for goblin in goblins:
		text += goblin + "\n"	
	text += "\n"
	print (text)
	pass
