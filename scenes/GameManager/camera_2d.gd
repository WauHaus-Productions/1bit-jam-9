extends Camera2D

@onready var overlay = get_node("GameOverlay")

@export var blink_time_sec: float

@export var target_zoom: Vector2

@export var transition_time: float

var time_counter = 0


func start_zoom_animation(target_zoom: Vector2, duration: float):
	var tweenCamera = get_tree().create_tween()
	tweenCamera.tween_property(self, "zoom", target_zoom, duration)
	tweenCamera.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_tween_zoom_completed():
	align_camera_and_overlay()


func align_camera_and_overlay():
	overlay.size = get_viewport().get_visible_rect().size
	overlay.scale.x = 1/self.zoom.x
	overlay.scale.y = 1/self.zoom.y
	
	overlay.position.x = -(get_viewport().get_visible_rect().size.x / self.zoom.x / 2)
	overlay.position.y = -(get_viewport().get_visible_rect().size.y / self.zoom.y / 2)

	overlay.z_index = 20
	
	
func change_camera_name(new_name: String):
	var camera_name = overlay.get_node("Camera")
	camera_name.text = new_name


func _ready() -> void:
	align_camera_and_overlay()
	


func _process(delta: float) -> void:
	align_camera_and_overlay()
	var rec_icon = overlay.get_node("Rec")
	if time_counter < blink_time_sec:
		time_counter += delta
	else:
		rec_icon.visible = !rec_icon.visible
		time_counter = 0
	
