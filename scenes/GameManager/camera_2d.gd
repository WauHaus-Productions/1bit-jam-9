extends Camera2D

@onready var overlay = get_node("GameOverlay")

@export var blink_time_sec: float

var time_counter = 0

func align_camera_and_overlay():
	print('\n\ncamera pos: ', self.global_position)
	print('viewport size: ', get_viewport().get_visible_rect().size)

	overlay.position.x = -(get_viewport().get_visible_rect().size.x / self.zoom.x / 2)
	overlay.position.y = -(get_viewport().get_visible_rect().size.y / self.zoom.y / 2)
	print('overlay_pos: ', overlay.position)
	
	
func change_camera_name(new_name: String):
	var camera_name = overlay.get_node("Camera")
	camera_name.text = new_name

func _ready() -> void:
	overlay.size = get_viewport().get_visible_rect().size
	overlay.scale.x = 1/self.zoom.x
	overlay.scale.y = 1/self.zoom.y


func _process(delta: float) -> void:
	var rec_icon = overlay.get_node("Rec")
	if time_counter < blink_time_sec:
		time_counter += delta
	else:
		rec_icon.visible = !rec_icon.visible
		time_counter = 0
	
