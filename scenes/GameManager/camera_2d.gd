extends Camera2D

@onready var rec_icon = get_node("Rec")

@export var blink_time_sec: float

var time_counter = 0

func _process(delta: float) -> void:
	if time_counter < blink_time_sec:
		time_counter += delta
	else:
		rec_icon.visible = !rec_icon.visible
		time_counter = 0
	
