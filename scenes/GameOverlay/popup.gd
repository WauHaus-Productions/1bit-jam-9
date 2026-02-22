extends Control


# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	pass # Replace with function body.

signal resume

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("Resume"):
		resume.emit()
	pass
