extends ButtonWrapper


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_down() -> void:
	super._on_button_down()
	get_tree().quit()
	pass # Replace with function body.
