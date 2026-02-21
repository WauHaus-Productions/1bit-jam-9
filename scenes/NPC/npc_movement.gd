extends CharacterBody2D

enum MovementState {NAVIGATION, DRAG, LAUNCH}

@export var movement_speed = 50
@export var launch_deceleration = 0.1
@export var launch_threshold = 100

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var logic: Node2D = $Logic

var last_mouse_positions: Array[Vector2]
var mouse_positions_index: int = 0
var movement_state: MovementState = MovementState.NAVIGATION
var drag_offset: Vector2
var physics_delta: float

func _ready() -> void:
	# Connect callbacks to signals
	navigation_agent_2d.velocity_computed.connect(on_velocity_computed)
	logic.change_state.connect(on_state_changed)
	input_event.connect(_on_input_event)
	
	# Initialize auxiliary variables
	last_mouse_positions = Array([], TYPE_VECTOR2, "", null)
	navigation_agent_2d.navigation_finished.connect(logic.arrived)

func _physics_process(delta: float) -> void:
	physics_delta = delta
	
	# Handle launch when dragging and dropping
	if movement_state == MovementState.LAUNCH:
		velocity += -velocity * launch_deceleration
		move_and_slide()
		if velocity.length() <= launch_threshold:
			velocity = Vector2(0, 0)
			movement_state = MovementState.NAVIGATION
			
			# Force path recomputation
			if !navigation_agent_2d.is_navigation_finished():
				navigation_agent_2d.target_position = navigation_agent_2d.get_final_position()
	
	# If not in navigation state / not having a target, stop
	if movement_state != MovementState.NAVIGATION or navigation_agent_2d.is_navigation_finished():
		return
	
	# Move on navigation path
	var current_position = global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	var new_velocity = current_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.velocity = new_velocity
	else:
		on_velocity_computed(new_velocity)
		
	move_and_slide()

func get_closest_from_group(group: StringName):
	var min_dist = 0
	var closest = null
	
	var group_elements = get_tree().get_nodes_in_group(group)
	for elem in group_elements:
		var dist = (global_position - elem.global_position).length()
		if dist < min_dist or closest == null:
			closest = elem
			min_dist = dist
	
	return closest

# Used for avoiding other NPCs when in NAVIGATION mode
func on_velocity_computed(safe_velocity: Vector2):
	if movement_state == MovementState.NAVIGATION:
		velocity = safe_velocity

func move_to_closest_distraction():
	var distraction = get_closest_from_group("distraction")
	if distraction != null:
		navigation_agent_2d.target_position = distraction.global_position
	
func move_to_closest_work():
	var work_station = get_closest_from_group("work")
	if work_station != null:
		navigation_agent_2d.target_position = work_station.global_position

func on_state_changed(state: int):
	if state == logic.States.SLACKING:
		move_to_closest_distraction()
	elif state == logic.States.WORKING:
		move_to_closest_work()

# -------------------
# DRAG AND DROP
# -------------------

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# if event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)
	# if event is InputEventMouseButton:
	#	print("Mouse Button Action: ", event.button_index, " at: ", event.position)
	#	print("Mouse Button Pressed: ", event.pressed)
	#	print("Mouse Button Double Click: ", event.double_click)
	#	print("Mouse Button Factor: ", event.factor)
	#	print("Mouse Button Mask: ", event.button_mask)
	#	print("Mouse Button Position: ", event.position)
	#	print("Mouse Button Global Position: ", event.global_position)
	# if event is InputEventMouseButton and event.pressed:
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
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			movement_state = MovementState.DRAG
			velocity = Vector2(0, 0)
			drag_offset = get_global_mouse_position() - global_position
	
	pass

func _input(event: InputEvent) -> void:
	# If drag released, go to LAUNCH state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and movement_state == MovementState.DRAG:
		movement_state = MovementState.LAUNCH
		
		# Compute average direction of mouse movement in last 10 frames
		var new_velocity = Vector2(0, 0)
		for i in range(1, last_mouse_positions.size()):
			new_velocity += last_mouse_positions[i] - last_mouse_positions[i - 1]
		new_velocity = new_velocity.normalized()
		
		velocity = new_velocity * Input.get_last_mouse_velocity().length() # event.screen_velocity
	elif event is InputEventMouseMotion and movement_state == MovementState.DRAG:
		# If dragging, move the NPC along with the mouse
		global_position = event.position - drag_offset
	
	# Record mouse positions for launch direction normalization
	last_mouse_positions.push_back(get_global_mouse_position())
	if last_mouse_positions.size() > 10:
		last_mouse_positions.pop_front()
