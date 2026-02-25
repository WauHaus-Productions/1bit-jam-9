extends ButtonWrapper

class_name SceneChangeButton

@export var next_scene: PackedScene

signal scene_button_pressed(game_scene: PackedScene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_down() -> void:
	super._on_button_down()
	print("NextScene: ", next_scene)
	emit_signal("scene_button_pressed", next_scene)
	pass # Replace with function body.
