extends CharacterBody2D

enum MovementState {NAVIGATION, DRAG, LAUNCH}

@export var movement_speed = 50
@export var launch_deceleration = 0.1
@export var launch_threshold = 100
@export var DEBUG: bool = false

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var logic: Node2D = $Logic
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var npc_sounds: NewWAUAudioPlayer = $Sounds



var last_mouse_positions: Array[Vector2]
var mouse_positions_index: int = 0
var movement_state: MovementState = MovementState.NAVIGATION
var drag_offset: Vector2
var physics_delta: float
var is_dying = false


signal dead
signal death_animation_finished

func _ready() -> void:
	# Connect callbacks to signals
	navigation_agent_2d.velocity_computed.connect(on_velocity_computed)
	navigation_agent_2d.navigation_finished.connect(idle_on_finished)
	logic.moving.connect(on_moving)
	input_event.connect(_on_input_event)
	
	# Initialize auxiliary variables
	last_mouse_positions = Array([], TYPE_VECTOR2, "", null)
	navigation_agent_2d.navigation_finished.connect(logic.arrived)
	
	#animated_sprite.animation_finished.connect(_on_death_finished)

func _physics_process(delta: float) -> void:
	if self.global_position != self.position:
		debug('\n\nGLOBAL POSITION ', self.global_position)
		debug('LOCAL POSITION ', self.position)
		debug('\n\n')
	physics_delta = delta
	
	# debug("Movement state: ", movement_state)
	
	# Handle launch when dragging and dropping
	if movement_state == MovementState.LAUNCH:
		velocity += -velocity * launch_deceleration
		move_and_slide()
		if velocity.length() <= launch_threshold:
			velocity = Vector2(0, 0)
			movement_state = MovementState.NAVIGATION
			
			# Force path recomputation
			if !navigation_agent_2d.is_navigation_finished():
				# navigation_agent_2d.target_position = navigation_agent_2d.get_final_position()
				move_to_closest_area("work")
	
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
	
	animated_sprite.play("walk")
	if velocity.x < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	move_and_slide()


func get_closest_from_group(group: StringName):
	var min_dist = 0
	var closest = null
	
	var group_elements = get_tree().get_nodes_in_group(group)
	for elem in group_elements:
		if elem.is_reserved():
			continue
		var dist = (global_position - elem.global_position).length()
		if dist < min_dist or closest == null:
			closest = elem
			min_dist = dist
	
	return closest

# Used for avoiding other NPCs when in NAVIGATION mode
func on_velocity_computed(safe_velocity: Vector2):
	if movement_state == MovementState.NAVIGATION:
		velocity = safe_velocity

func get_area_by_pos(pos: Vector2) -> Node:
	for node in get_tree().get_nodes_in_group("work"):
		if node.global_position == pos:
			return node
	for node in get_tree().get_nodes_in_group("distraction"):
		if node.global_position == pos:
			return node
	return null

	
func move_to_closest_area(group: String) -> void:
	_leave_position()
	
	var area = get_closest_from_group(group)
	if area != null:
		debug("found ", group)
		area.reserve()
		navigation_agent_2d.target_position = area.global_position

func on_moving(state: int):
	if state == logic.States.SLACKING:
		move_to_closest_area("distraction")
	elif state == logic.States.WORKING or state == logic.States.SCARED:
		move_to_closest_area("work")

func idle_on_finished():
	animated_sprite.play("idle")

func _leave_position():
	if navigation_agent_2d.target_position != null:
		var node = get_area_by_pos(navigation_agent_2d.target_position)
		if node != null:
			node.leave()

# -------------------
# DRAG AND DROP
# -------------------

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# if event is InputEventMouseMotion:
	#	debug("Mouse Motion at: ", event.position)
	# if event is InputEventMouseButton:
	#	debug("Mouse Button Action: ", event.button_index, " at: ", event.position)
	#	debug("Mouse Button Pressed: ", event.pressed)
	#	debug("Mouse Button Double Click: ", event.double_click)
	#	debug("Mouse Button Factor: ", event.factor)
	#	debug("Mouse Button Mask: ", event.button_mask)
	#	debug("Mouse Button Position: ", event.position)
	#	debug("Mouse Button Global Position: ", event.global_position)
	# if event is InputEventMouseButton and event.pressed:
	#	match event.button_index:
	#		MOUSE_BUTTON_LEFT:
	#			debug("Left mouse button")
	#		MOUSE_BUTTON_RIGHT:
	#			debug("Right mouse button")
	#		MOUSE_BUTTON_WHEEL_UP:
	#			debug("Scroll wheel up")
	#		MOUSE_BUTTON_WHEEL_DOWN:
	#			debug("Scroll wheel down")
	if event is not InputEventMouseButton:
		return

	if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	# Start dragging the npc
	movement_state = MovementState.DRAG
	velocity = Vector2(0, 0)
	drag_offset = get_global_mouse_position() - global_position
	
	# Set state to MOVING and then SCARED when arrived
	logic.move(logic.States.SCARED)
	
	# Play grabbed animation
	animated_sprite.play("grabbed")
	npc_sounds.play_sound_now("SCREAM", true)
	npc_sounds.play_sound_now("GRAB", false)


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
		debug('\n\nMOVEMENT: ')
		debug('event: ', event.global_position)

		# If dragging, move the NPC along with the mouse
		#global_position = event.global_position - drag_offset
		self.global_position = get_global_mouse_position() - drag_offset
		
		debug('goblin global: ', global_position)
		debug('goblin local: ', position)

		
		debug('EVENT LOCAL: ', event.position)
	# Record mouse positions for launch direction normalization
	last_mouse_positions.push_back(get_global_mouse_position())
	if last_mouse_positions.size() > 10:
		last_mouse_positions.pop_front()


func debug(...args) -> void:
	if DEBUG:
		print(args)
		
#func _on_death_finished():
	#if animated_sprite.current_animation == "die" and is_dying == true:
		#death_animation_finished.emit(self)


func _on_logic_dying() -> void:
	_leave_position()
	pass # Replace with function body.
