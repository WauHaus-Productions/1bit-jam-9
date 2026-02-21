extends CharacterBody2D

@export var movement_speed = 50
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var logic: Node2D = $Logic

func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(on_velocity_computed)
	logic.change_state.connect(on_state_changed)

func _physics_process(delta: float) -> void:
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

func on_state_changed(state: int):
	if state == logic.States.SLACKING:
		# TODO: cerca postazione slacking
		navigation_agent_2d.target_position = global_position + Vector2(100, 0)
