extends AnimatedSprite2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	play("default")

func _process(delta):
	self.get_parent().global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			play("click")
		else:
			play("default")

func _on_animation_finished():
	if animation == "click":
		play("default")
