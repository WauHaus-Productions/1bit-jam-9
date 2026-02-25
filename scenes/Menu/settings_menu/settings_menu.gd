extends BaseMenu
signal settings_switched

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make all tree invisible
	var children = get_children()
	for child in children:
		child.visible = false
	# move the settings scene up
	_switch_visibility(false)
	# make it visible again
	await get_tree().create_timer(0.5).timeout
	for child in children:
		child.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_settings_switched() -> void:
	#get_tree().paused = !visible
	_switch_visibility(!visible)
	emit_signal("settings_switched")

func _switch_visibility(new_visiblity: bool):
	if new_visiblity:
		_move_down()
	else:
		_move_up()
			
	self.visible = new_visiblity

		
func _move_down():
	var canvas_layer = self.get_child(0)
	var tween = get_tree().create_tween()
	tween.tween_property(canvas_layer, "offset", $MarkerDown.position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _move_up():
	var canvas_layer = self.get_child(0)
	var tween = get_tree().create_tween()
	tween.tween_property(canvas_layer, "offset", $MarkerUp.position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

			
func _on_next_scene(game_scene: PackedScene) -> void:
	super._on_next_scene(game_scene)
	_on_settings_switched()
