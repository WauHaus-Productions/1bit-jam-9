extends BaseMenu

@export var transition_duration: float = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Hand.modulate.a = 0
	var tweenHand = get_tree().create_tween()
	tweenHand.tween_property($Hand, "modulate:a", 1, transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
