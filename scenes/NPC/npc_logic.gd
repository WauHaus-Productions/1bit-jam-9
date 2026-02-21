extends Node2D

@export var SPEED = 130.0
@export var JUMP_VELOCITY = -200.0
@export var LOW_MORALE = 200
@export var HIGH_MORALE = 800
@export var MAX_MORALE = 1000
@export var MIN_MORALE = 0
@export var TIMER_DURATION = 5
@export var States = {SCARED = -4, WORKING = -2, MOVING = 0, SLACKING = 1}
var MORALE_NORMALIZER: float = MAX_MORALE
var Morale: float
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
var DesiredState: int = States.WORKING

signal change_state
signal producing
signal slacking

@onready var timer: Timer = $Timer

# TODO: trigger SCARED state + timer.start()
# TODO: when morale == 0 do something
# TODO: when scared produce more

func _ready() -> void:
	Morale = MAX_MORALE
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	# print("Timeout! Morale: ", Morale)
	# print("State: ", State)
	# print("Desired State: ", DesiredState)
	if State == States.SLACKING and Morale < MAX_MORALE:
		# print("Slacking with morale: ", Morale)
		timer.start(TIMER_DURATION)
		return

	if Morale >= HIGH_MORALE:
		# print("Working morale")
		State = move_or_continue(States.WORKING)
		# print("Finished move_or_continue, State: ", State, ", Desired State: ", DesiredState)

	elif Morale <= LOW_MORALE:
		# print("Slacking morale")
		State = move_or_continue(States.SLACKING)
		# print("Finished move_or_continue, State: ", State, ", Desired State: ", DesiredState)

	else:
		State = switch_state()
		# print("Rolled new state: ", State, ", desired: ", DesiredState)

	# Do not set timer until reaching dest
	if State == States.MOVING:
		return

	var waiting_time = round(TIMER_DURATION * Morale / MORALE_NORMALIZER)
	# print("Starting timer, expiring in: ", waiting_time, ", not rounded: ", TIMER_DURATION * Morale / MORALE_NORMALIZER)
	timer.start(waiting_time)

func _physics_process(delta: float) -> void:
	Morale += morale_diff(delta)
	Morale = min(Morale, MAX_MORALE)
	Morale = max(Morale, MIN_MORALE)
	# print(Morale)
	act()

func morale_diff(delta: float) -> float:
	return State * delta

func act() -> void:
	match State:
		States.SLACKING:
			slack()
		_:
			work()

# TODO?
func work() -> void:
	producing.emit(abs(State))

# TODO?
func slack():
	slacking.emit(abs(State))

func switch_state() -> int:
	if State == States.SCARED:
		return State
	
	if rng.randf() <= 0.5:
		return move_or_continue(States.WORKING)

	return move_or_continue(States.SLACKING)

func move_or_continue(desired_state: int) -> int:
	if State == desired_state:
		return State

	DesiredState = desired_state
	change_state.emit(DesiredState)
	return States.MOVING

func arrived():
	print("arrived!")
	State = DesiredState
	var waiting_time = round(TIMER_DURATION * Morale / MORALE_NORMALIZER)
	# print("restarting timer, expiring in: ", waiting_time)
	timer.start(waiting_time)