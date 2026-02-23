extends HBoxContainer
class_name AudioSlider

@export var bus_name : String
@export var label_text :String
var bus_index
var max_volume

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	if label_text != null and !label_text.is_empty():
		$LabelContainer/Label.text = label_text
	else:
		$LabelContainer/Label.text = name
	bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, 0.)
	$SliderContainer/Volume.value = AudioServer.get_bus_volume_db(bus_index)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, value)
