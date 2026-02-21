extends Node2D

@export var SPEED = 130.0
@export var JUMP_VELOCITY = -200.0
@export var LOW_MORALE = 200
@export var HIGH_MORALE = 800
@export var States = {SCARED = -4, WORKING = -2, MOVING = 0, SLACKING = 1}
@export var Morale: float = 1000
@export var TIMER_DURATION = 5
@export var is_seated: bool = false
# @export var MORALE_DEGRADATION_PER_SEC = 5
# @export var MORALE_RECOVER_PER_SEC = 2

# const SPEED = 130.0
# const JUMP_VELOCITY = -200.0
# const LOW_MORALE = 20
# const HIGH_MORALE = 80
# const MORALE_DEGRADATION_PER_SEC = 5
# const MORALE_RECOVER_PER_SEC = 2
# const MEDIUM_MORALE = 50
# enum States {SCARED = -4, WORKING = -2, MOVING = 0, SLACKING = 1}

var rng = RandomNumberGenerator.new()
var State: int = States.WORKING

signal change_state

@onready var timer: Timer = $Timer

# TODO: ogni frame, se stato == woRKING or SCARED manda segnale???
# TODO: trigger state when reaching coffee machine or desk + timer.start()
# TODO: trigger SCARED state + timer.start()

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	print("Timeout!")
	if Morale >= HIGH_MORALE:
		State = move_or_continue(States.WORKING)

	elif Morale <= LOW_MORALE:
		State = move_or_continue(States.SLACKING)

	else:
		State = switch_state()

	# Do not set timer until reaching dest
	if State == States.MOVING:
		return

	var waiting_time = round(TIMER_DURATION * Morale / 1000.0)
	print("Starting timer, expiring in: ", waiting_time)
	timer.start(waiting_time)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	# if not is_on_floor():
	# 	velocity += get_gravity() * delta
	Morale += morale_diff(delta)
	print(Morale)
	act()
	

func morale_diff(delta: float) -> float:
	# print("morale diff: ", State * delta, ", rounded to: ", round(State * delta))
	return State * delta

func act() -> void:
	match State:
		States.MOVING:
			# move_and_slide()
			pass
		States.SLACKING:
			slack()
		_:
			work()


# TODO?
func work():
	pass

# TODO?
func slack():
	pass

func switch_state() -> int:
	if State == States.SCARED:
		return State
	
	if rng.randf() <= 0.5:
		return move_or_continue(States.WORKING)

	return move_or_continue(States.SLACKING)

func move_or_continue(desired_state: int) -> int:
	if State == desired_state:
		return State

	change_state.emit(desired_state)
	return States.MOVING
