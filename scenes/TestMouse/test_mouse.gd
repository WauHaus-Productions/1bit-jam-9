extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var is_dragging: bool = false
var drag_offset: Vector2


func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
	#	velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
	#	velocity.x = direction * SPEED
	#else:
	#	velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseMotion:
		print("Mouse Motion at: ", event.position)
	if event is InputEventMouseButton:
		print("Mouse Button Action: ", event.button_index, " at: ", event.position)
		print("Mouse Button Pressed: ", event.pressed)
		print("Mouse Button Double Click: ", event.double_click)
		print("Mouse Button Factor: ", event.factor)
		print("Mouse Button Mask: ", event.button_mask)
		print("Mouse Button Position: ", event.position)
		print("Mouse Button Global Position: ", event.global_position)
	#if event is InputEventMouseButton and event.pressed:
	#	match event.button_index:
	#		MOUSE_BUTTON_LEFT:
	#			print("Left mouse button")
	#		MOUSE_BUTTON_RIGHT:
	#			print("Right mouse button")
	#		MOUSE_BUTTON_WHEEL_UP:
	#			print("Scroll wheel up")
	#		MOUSE_BUTTON_WHEEL_DOWN:
	#			print("Scroll wheel down")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		global_position = event.position - drag_offset
	
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_dragging:
			is_dragging = false
			velocity = Input.get_last_mouse_velocity() #event.screen_velocity 
	elif event is InputEventMouseMotion and is_dragging:
		global_position = event.position - drag_offset
