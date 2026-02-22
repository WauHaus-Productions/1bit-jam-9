extends Node2D

@export var LOW_MORALE: int = 200
@export var HIGH_MORALE: int = 800
@export var MAX_MORALE: int = 1000
@export var MIN_MORALE: int = 0
@export var TIMER_DURATION: int = 5
@export var SCARED_TIMER_FACTOR: int = 2
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

const TO_PROFIT_COEFFICIENT: int = 2

var rng = RandomNumberGenerator.new()
var State: int
var DesiredState: int

signal moving
signal dying
signal switching

@onready var timer: Timer = $Timer
@onready var sounds: NewWAUAudioPlayer = $"../Sounds"


func _ready() -> void:
	Morale = MAX_MORALE
	timer.timeout.connect(_on_timer_timeout)
	move(States.WORKING)
	timer.start(0.1)


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
		roll()
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
		return
	
	# print(Morale)


func morale_diff(delta: float) -> float:
	return State * delta


func die() -> void:
	print("Dead")
	dying.emit(self.get_parent())


func roll() -> void:
	if rng.randf() <= 0.5:
		move_or_continue(States.WORKING)
		return

	move_or_continue(States.SLACKING)


func move_or_continue(desired_state: int) -> void:
	if State == desired_state:
		return

	move(desired_state)


func move(desired_state: int) -> void:
	timer.stop()

	DesiredState = desired_state
	update_state(States.MOVING)
	moving.emit(DesiredState)


func to_profit(state: int) -> int:
	if state < 0:
		return abs(state) / TO_PROFIT_COEFFICIENT
	return state - TO_PROFIT_COEFFICIENT


func update_state(desired_state: int) -> void:
	if desired_state == States.SCARED:
		sounds.play_sound_now("WORKING", false)
	if State == States.SCARED and desired_state != States.SCARED:
		sounds.stop_sound("WORKING")
		
	State = desired_state
	var profit: int = to_profit(desired_state)
	print("profit: ", profit)
	switching.emit(profit, self.get_parent())


func arrived() -> void:
	print("arrived!")
	debug_state()
	update_state(DesiredState)

	var waiting_time: int = round(TIMER_DURATION * Morale / MORALE_NORMALIZER)

	if State == States.SCARED:
		waiting_time *= SCARED_TIMER_FACTOR
	
	print("restarting timer, expiring in: ", waiting_time)
	timer.start(waiting_time)


func set_scared() -> void:
	timer.stop()
	DesiredState = States.SCARED
	update_state(States.SCARED)
	moving.emit(DesiredState)
	var waiting_time: int = round(TIMER_DURATION * Morale / MORALE_NORMALIZER) * SCARED_TIMER_FACTOR
	timer.start(waiting_time)


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
