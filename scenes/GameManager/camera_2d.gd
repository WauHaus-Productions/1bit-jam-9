extends Camera2D

@onready var overlay = get_node("GameOverlay")

@export var blink_time_sec: float

@export var target_zoom: Vector2

@export var transition_time: float

var time_counter = 0

func start_zoom_animation():
	var tweenCamera = get_tree().create_tween()
	tweenCamera.finished.connect(_on_tween_zoom_completed)
	tweenCamera.tween_property(self, "zoom", Vector2(2,2), transition_time/2)
	tweenCamera.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_tween_zoom_completed():#object: Object, property: String):
	align_camera_and_overlay()
	var tweenOverlay = get_tree().create_tween()
	tweenOverlay.tween_property(overlay, "modulate:a", 1, transition_time/4)
	tweenOverlay.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func align_camera_and_overlay():
	#var target_position = Vector2(-(get_viewport().get_visible_rect().size.x / self.target_zoom.x / 2),-(get_viewport().get_visible_rect().size.y / self.target_zoom.y / 2))
	#
	#var tweenOverlay = get_tree().create_tween()
	#tweenOverlay.tween_property(overlay, "position", target_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	#overlay.position.x = -(get_viewport().get_visible_rect().size.x / self.zoom.x / 2)
	#overlay.position.y = -(get_viewport().get_visible_rect().size.y / self.zoom.y / 2)
	
	overlay.position.x = -(get_viewport().get_visible_rect().size.x / self.target_zoom.x / 2)
	overlay.position.y = -(get_viewport().get_visible_rect().size.y / self.target_zoom.y / 2)
	
	#overlay.position = target_position
	overlay.z_index = 20
	
	
func change_camera_name(new_name: String):
	var camera_name = overlay.get_node("Camera")
	camera_name.text = new_name

func _ready() -> void:
	overlay.size = get_viewport().get_visible_rect().size
	#overlay.scale.x = 1/self.zoom.x
	#overlay.scale.y = 1/self.zoom.y
	
	overlay.scale.x = 1/self.target_zoom.x
	overlay.scale.y = 1/self.target_zoom.y
	overlay.modulate.a = 0


func _process(delta: float) -> void:
	var rec_icon = overlay.get_node("Rec")
	if time_counter < blink_time_sec:
		time_counter += delta
	else:
		rec_icon.visible = !rec_icon.visible
		time_counter = 0
	
