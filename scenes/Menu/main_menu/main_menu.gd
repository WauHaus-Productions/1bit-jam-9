extends BaseMenu

@export var transition_duration: float = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Art/Manager.modulate.a = 0
	var tweenManager = get_tree().create_tween()
	var tweenHand = get_tree().create_tween()
	tweenManager.tween_property($Art/Manager, "modulate:a", 1, transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tweenHand.tween_property($Art/Hand, "position", $Art/Manager.position, transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
