extends Control
class_name BaseMenu

signal next_scene(game_scene: PackedScene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(get_tree())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_next_scene(game_scene: PackedScene) -> void:	
	emit_signal("next_scene", game_scene, _default_constructor)

func _default_constructor(scene):
	pass
