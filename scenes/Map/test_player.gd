extends CharacterBody2D

@export var movement_speed = 50
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(on_velocity_computed)

func _physics_process(delta: float) -> void:
	var mouse_position =  get_global_mouse_position()
	navigation_agent_2d.target_position = mouse_position
	
	if navigation_agent_2d.is_navigation_finished():
		return
	
	var current_position = global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	var new_velocity = current_position.direction_to(next_path_position) * movement_speed
	
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.velocity = new_velocity
	else:
		on_velocity_computed(new_velocity)

	move_and_slide()

func on_velocity_computed(safe_velocity : Vector2):
	velocity = safe_velocity
