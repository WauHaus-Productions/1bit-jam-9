extends Node2D

# @export var LOW_MORALE: int = 200
@export var HIGH_MORALE: int = 40
@export var MAX_MORALE: int = 50
@export var MIN_MORALE: int = 0
@export var TIMER_DURATION: int = 5
@export var SCARED_TIMER_FACTOR: int = 2
@export var States = {SCARED = -4, WORKING = -2, MOVING = 0, SLACKING = 1}
@export var DEBUG: bool = false
var MORALE_NORMALIZER: float = MAX_MORALE
@export var Morale: float = MAX_MORALE
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
	# Morale = MAX_MORALE
	timer.timeout.connect(_on_timer_timeout)
	move(States.WORKING)
	timer.start(0.1)


func _on_timer_timeout() -> void:
	debug("Timeout! Morale: ", Morale)
	debug_state()
	if State == States.SLACKING and Morale < MAX_MORALE:
		# debug("Slacking with morale: ", Morale)
		start_timer()
		return

	if Morale >= HIGH_MORALE:
		debug("Working morale")
		move_or_continue(States.WORKING)
		debug("Finished move_or_continue")
		debug_state()

	# elif Morale <= LOW_MORALE:
	# 	debug("Slacking morale")
	# 	move_or_continue(States.SLACKING)
	# 	debug("Finished move_or_continue")
	# 	debug_state()

	else:
		roll()
		debug("Rolled new state")
		debug_state()

	# Do not set timer until reaching dest
	if State == States.MOVING:
		return

	start_timer()


func _physics_process(delta: float) -> void:
	Morale += morale_diff(delta)
	Morale = clamp(Morale, MIN_MORALE, MAX_MORALE)
	# Morale = min(Morale, MAX_MORALE)
	# Morale = max(Morale, MIN_MORALE)
	
	if Morale == 0:
		die()
		return
	
	# debug(Morale)


func morale_diff(delta: float) -> float:
	return State * delta


func die() -> void:
	debug("Dead")
	#var sprite = self.get_parent().get_node("AnimatedSprite2D")
	#sprite.play("die")
	#await sprite.animation_finished("die")
	dying.emit(self.get_parent(), to_profit(State))


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
		
	var old_profit: int = to_profit(State)
	var profit: int = to_profit(desired_state)
	debug("profit: ", profit)
	switching.emit(profit, self.get_parent(), old_profit)
	State = desired_state


func start_timer() -> void:
	var waiting_time: float
	match State:
		States.SCARED:
			waiting_time = TIMER_DURATION * SCARED_TIMER_FACTOR
		States.WORKING:
			waiting_time = TIMER_DURATION * Morale / MORALE_NORMALIZER
		States.SLACKING:
			waiting_time = TIMER_DURATION + TIMER_DURATION * (1 - Morale / MORALE_NORMALIZER)

	debug("restarting timer, expiring in: ", waiting_time)
	timer.start(waiting_time)


func arrived() -> void:
	debug("arrived!")
	debug_state()
	update_state(DesiredState)
	start_timer()


func set_scared() -> void:
	timer.stop()
	DesiredState = States.SCARED
	update_state(States.SCARED)
	moving.emit(DesiredState)
	start_timer()


func print_state(state: int, state_name: String) -> void:
	match state:
		States.SCARED:
			debug(state_name, ": SCARED")
		States.WORKING:
			debug(state_name, ": WORKING")
		States.MOVING:
			debug(state_name, ": MOVING")
		States.SLACKING:
			debug(state_name, ": SLACKING")


func debug_state() -> void:
	print_state(State, "State")
	print_state(DesiredState, "DesiredState")


func debug(...args) -> void:
	if DEBUG:
		print(args)
