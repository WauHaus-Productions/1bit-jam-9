extends Node2D

@export var LOW_MORALE = 200
@export var HIGH_MORALE = 800
@export var MAX_MORALE = 1000
@export var MIN_MORALE = 0
@export var TIMER_DURATION = 5
@export var SCARED_TIMER_FACTOR = 2
@export var States = {SCARED = -4, WORKING = -2, MOVING = 0, SLACKING = 1}
var MORALE_NORMALIZER: float = MAX_MORALE
var Morale: float
# @export var MORALE_DEGRADATION_PER_SEC = 5
# @export var MORALE_RECOVER_PER_SEC = 2

# const LOW_MORALE = 20
# const HIGH_MORALE = 80
# const MORALE_DEGRADATION_PER_SEC = 5
# const MORALE_RECOVER_PER_SEC = 2
# const MEDIUM_MORALE = 50
# enum States {SCARED = -4, WORKING = -2, MOVING = 0, SLACKING = 1}

var rng = RandomNumberGenerator.new()
var State: int
var DesiredState: int

signal change_state
signal working
signal slacking
signal turbo_working
signal dying

@onready var timer: Timer = $Timer

# TODO: when scared produce more

func _ready() -> void:
	Morale = MAX_MORALE
	timer.timeout.connect(_on_timer_timeout)
	State = States.MOVING
	DesiredState = States.WORKING
	change_state.emit(DesiredState)

func print_state(state: int, state_name: String) -> void:
	match state:
		States.SCARED:
			print(state_name, ": SCARED")
		States.WORKING:
			print(state_name, ": WORKING")
		States.MOVING:
			print(state_name, ": MOVING")
		States.SLACKING:
			print(state_name, ": SLACKING")

func debug_state() -> void:
	print_state(State, "State")
	print_state(DesiredState, "DesiredState")

func _on_timer_timeout() -> void:
	print("Timeout! Morale: ", Morale)
	debug_state()
	if State == States.SLACKING and Morale < MAX_MORALE:
		# print("Slacking with morale: ", Morale)
		timer.start(TIMER_DURATION)
		return

	if Morale >= HIGH_MORALE:
		print("Working morale")
		move_or_continue(States.WORKING)
		print("Finished move_or_continue")
		debug_state()

	elif Morale <= LOW_MORALE:
		print("Slacking morale")
		move_or_continue(States.SLACKING)
		print("Finished move_or_continue")
		debug_state()

	else:
		switch_state()
		print("Rolled new state")
		debug_state()

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
	
	if Morale == 0:
		die()
	
	# print(Morale)
	act()

func morale_diff(delta: float) -> float:
	return State * delta

func die() -> void:
	print("Dead")
	dying.emit()
	queue_free()

func act() -> void:
	match State:
		States.SLACKING:
			slack()
		States.SCARED:
			turbo_work()
		_:
			work()

# TODO?
func work() -> void:
	working.emit(abs(State))

# TODO?
func slack() -> void:
	slacking.emit(abs(State))

func turbo_work() -> void:
	turbo_working.emit(abs(State))

func switch_state() -> void:
	if rng.randf() <= 0.5:
		move_or_continue(States.WORKING)
		return

	move_or_continue(States.SLACKING)


func move_or_continue(desired_state: int) -> void:
	if State == desired_state:
		return

	move(desired_state)


func move(desired_state):
	timer.stop()

	DesiredState = desired_state
	change_state.emit(DesiredState)
	State = States.MOVING


func arrived() -> void:
	print("arrived!")
	debug_state()
	State = DesiredState

	var waiting_time: int = round(TIMER_DURATION * Morale / MORALE_NORMALIZER)

	if State == States.SCARED:
		waiting_time *= SCARED_TIMER_FACTOR
	
	print("restarting timer, expiring in: ", waiting_time)
	timer.start(waiting_time)


func set_scared() -> void:
	timer.stop()
	DesiredState = States.SCARED
	State = States.SCARED
	change_state.emit(DesiredState)
	var waiting_time: int = round(TIMER_DURATION * Morale / MORALE_NORMALIZER) * SCARED_TIMER_FACTOR
	timer.start(waiting_time)