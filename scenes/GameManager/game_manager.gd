extends BaseScene

@export var map: PackedScene
@export var npc: PackedScene
@export var pointer: PackedScene

@onready var camera = $Camera2D
@onready var revenue_ui = $Camera2D/GameOverlay/Revenue
@onready var date_label: Label = $Camera2D/GameOverlay/Date
@onready var goblin_counter: Label = $Camera2D/GameOverlay/GoblinCounter
@onready var goal_label: Label = $Camera2D/GameOverlay/Goal
@onready var level_popup: Control = $Camera2D/GameOverlay/Popup

@onready var fiscal_year_timer: Timer = $DayTimer


@onready var bg_music = $BGMusic
@onready var bg_office_sound: AudioStreamPlayer = $BGOfficeSound

@export var npc_counter: int = 10
@export var DEBUG: bool = false

@export var death_cam: PackedScene

@export var game_over: PackedScene

@export var starting_goal: int = 1000
@export var year_len_seconds: int = 30
var current_goal: int

const NPC_REVENUES: int = 100
const NPC_COST: int = 40
const DAYS_IN_YEAR = 365

var map_instance
var spawn_positions

var tot_rooms: int = 4
var current_camera_idx: int = 1


var total_revenues: float = 0.0
var elapsed_time := 0.0
@export var current_fiscal_year: int = 2026

const names: Array[String] = ["Fabio Losavio", "Cristiano Neroni", "Samuele Lo Iacono", "Hakim El Achak", "Vittorio Terzi", "Oscar Pindaro", "Matteo Mangioni", "Margherita Pindaro", "Francesco Maffezzoli", "Enka Lamaj", "Roberto Maligni",
	"Grizzle Profitgrub", "Snark Ledgerfang", "Boggle Spreadsheet", "Krimp Bonusclaw", "Snik KPI-Snatcher", "Murgle Coffeestain", "Zibble Paperjam", "Grint Marginchewer", "Blort Deadlinegnaw", "Skaggy Synergytooth", "Nibwick Microgrind", "Crindle Stocksniff", "Wizzle Cubiclebane", "Throg Expensefang", "Splug Overtimebelch", "Drabble Taskmangler", "Klix Compliancegrime", "Mizzle Workflowrot", "Gorp Staplechewer", "Snibble Budgetbruise", "Kraggy Meetinglurker", "Blim Forecastfumble", "Zonk Assetgnash", "Triggle Slidereviser", "Vorny Timesheetterror", "Glim Auditnibble", "Brakka Breakroomraider", "Sprock Redtapewriggler", "Nurgle Powerpointhex", "Grizzleback Clawculator", "Snaggle Metricsmash", "Plib Shareholdershriek", "Drox Inboxhoarder", "Fizzle Ladderclimb", "Krumble Deskgnarl", "Wretchy Watercoolerspy", "Blix Quarterlyquiver", "Grottin Promotionpounce", "Skibble Faxmachinebane", "Zraggy Corporatecackle"]
var active_npcs: Dictionary[String, Node2D] = {}

var working_npcs: int
var scared_npcs: int

var memorial: Array[String] = []

var States = {SCARED = 2, WORKING = 1, MOVING = -2, SLACKING = -1}


func determine_spawn_positions(current_map) -> Array[Vector2i]:
	var tilemap = current_map.get_node("TileMap")
	var ground_layer: TileMapLayer = tilemap.get_node("Ground")
	var ground_positions: Array[Vector2i] = ground_layer.get_used_cells_by_id(-1, Vector2i(0, 0))
		
	var obstacle_layer: TileMapLayer = tilemap.get_node("Obstacles")
	var obstacle_positions: Array[Vector2i] = obstacle_layer.get_used_cells()
	
	ground_positions = ground_positions.filter(
		func(value):
			return not obstacle_positions.has(value)
	)
	
	# Convert all the positions to global coordinates
	var global_spawnable_positions: Array[Vector2i] = []
	
	for pos in ground_positions:
		global_spawnable_positions.append(
			tilemap.to_global(
				ground_layer.map_to_local(pos)
				)
			)
		
	return global_spawnable_positions
	

func update_revenues(delta) -> void:
	var working_npcs_revenue: float = States.WORKING * working_npcs * NPC_REVENUES * delta
	var scared_npcs_revenue: float = States.SCARED * scared_npcs * NPC_REVENUES * delta
	var costs: float = active_npcs.size() * NPC_COST * delta
	# debug("working_npcs_revenue ", working_npcs_revenue, ", scared_npcs_revenue ", scared_npcs_revenue, ", costs", costs)
	self.total_revenues += working_npcs_revenue + scared_npcs_revenue - costs


func get_available_name() -> String:
	name = names.pick_random()
	while name in active_npcs.keys():
		name = names.pick_random()
	return name

func get_current_day() -> int:
	var year_progress = elapsed_time / fiscal_year_timer.wait_time
	return int(year_progress * DAYS_IN_YEAR) + 1
	
func day_to_date(day: int) -> Dictionary:
	var month_lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

	var month = 0
	while day > month_lengths[month]:
		day -= month_lengths[month]
		month += 1
		if month == 12:
			debug('Fine Anno Fiscale')
			month = 0
			current_fiscal_year += 1
			elapsed_time = 0.0
			# day = 0
		

	return {
		"month": month + 1,
		"day": day
	}
	
func update_date_display():
	var day_of_year = get_current_day()
	var date = day_to_date(day_of_year)

	date_label.text = "%02d/%02d/%04d" % [date.day, date.month, current_fiscal_year]
	
func _ready() -> void:
	current_goal = starting_goal
	goal_label.text = str(current_goal)
	
	# SET RANDOMIZER
	randomize()
	
	# ACTIVATE POINTER
	var pointer_instance = pointer.instantiate()
	add_child(pointer_instance)
	
	# SPAWN MAP
	map_instance = map.instantiate()
	map_instance.global_position = Vector2(0, 0)
	add_child(map_instance)
	
	# GET SPAWNABLE POSITIONS
	var spawnable_positions = determine_spawn_positions(map_instance)
	
	# SPAWN NPCs
	for n in npc_counter:
		spawn_npc(spawnable_positions)
		
	
	# SET CAMERA ON FIRST ROOM
	var camera_marker = map_instance.get_node("Cameras/Stanza1")
	
	camera.global_position = camera_marker.global_position
	#camera.align_camera_and_overlay()
	camera.start_zoom_animation(camera.target_zoom, camera.transition_time)
	
	# START BG MUSIC
	bg_music.play()
	bg_office_sound.play()
	
	#START YEAR TIMER
	$DayTimer.wait_time = year_len_seconds
	$DayTimer.start()
	

func spawn_npc(spawnable_positions) -> void:
	var npc_name = get_available_name()
	debug("Spawning Goblin ", npc_name)
	var new_npc = npc.instantiate()
	
	var random_spawn_position = spawnable_positions.pick_random()
	spawnable_positions.erase(random_spawn_position)
	
	new_npc.global_position = random_spawn_position
	debug("in position ", random_spawn_position)
	new_npc.name = npc_name
	
	# SUBSCRIBE TO SIGNALS
	new_npc.get_node("Logic").switching.connect(_on_change_state)
	new_npc.get_node("Logic").dying.connect(_on_dying)
	
	active_npcs[npc_name] = new_npc
	
	map_instance.add_child(new_npc)


func hire_npc() -> void:
	var spawnable_positions = determine_spawn_positions(map_instance)
	spawn_npc(spawnable_positions)

func change_camera(direction):
	if direction == "foreward":
		if current_camera_idx == tot_rooms:
			current_camera_idx = 1
		else:
			current_camera_idx += 1
			
	elif direction == "backwards":
		if current_camera_idx == 1:
			current_camera_idx = tot_rooms
		else:
			current_camera_idx -= 1
			
	else:
		return
	
	var camera_name = "Cameras/Stanza" + str(current_camera_idx)
	var camera_marker = map_instance.get_node(camera_name)
	camera.global_position = camera_marker.global_position
	camera.change_camera_name("Camera " + str(current_camera_idx))
	
	# POSSIBLE CAMERA TWEEN????
	#var tweenCamera = get_tree().create_tween()
	#tweenCamera.tween_property(camera, "global_position", camera_marker.global_position, 0.25)
	#tweenCamera.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
func _process(delta: float) -> void:
	camera.align_camera_and_overlay()
	
	update_revenues(delta)
	goblin_counter.text = str(active_npcs.size())
		
	revenue_ui.text = str(roundi(total_revenues))
	
	if active_npcs.size() == 0:
		debug(memorial)
	
	if Input.is_action_just_pressed("camera_fwd"):
		change_camera("foreward")
		
	if Input.is_action_just_pressed("camera_bwd"):
		change_camera("backwards")

	if Input.is_action_just_pressed("Hire"):
		hire_npc()
		
	if Input.is_action_just_pressed("zoom"):
		if camera.zoom == camera.target_zoom:
			camera.start_zoom_animation(Vector2(1,1), 1)
		else:
			camera.start_zoom_animation(camera.target_zoom, camera.transition_time)
		
	elapsed_time += delta

	# Clamp so we don't overflow past the year
	elapsed_time = min(elapsed_time, fiscal_year_timer.wait_time)
		
	update_date_display()


func _on_dying(dying_npc: Node2D, state: int) -> void:
	if dying_npc.is_dying:
		return
		
	var dying_name = active_npcs.find_key(dying_npc)
	if dying_name != null:
		active_npcs.erase(dying_name)
	debug("STA MORENDO ", dying_name)
	
	match state:
		States.WORKING:
			working_npcs = decrease_npcs(working_npcs)
		States.SCARED:
			scared_npcs = decrease_npcs(scared_npcs)
		_:
			debug("Error, dying npc in state: ", state)
			
	#var sprite = dying_npc.get_node("AnimatedSprite2D")
	#dying_npc.death_animation_finished.connect(_on_death_finished)
	memorial.append(dying_name)
	var pos = dying_npc.position
	dying_npc.queue_free()
	var instance = death_cam.instantiate()
	add_child(instance)
	instance.position = pos

	#sprite.play("die")

#
#func _on_death_finished(dying_npc):
	#dying_npc.is_dying = false
	#print("\n\nfinished death")
	#dying_npc.queue_free()
	#
func decrease_npcs(npcs: int, decrement := 1) -> int:
	npcs -= decrement
	npcs = max(npcs, 0)
	return npcs


func _on_change_state(new_action_enum: int, emitting_npc: Node2D, old_action: int) -> void:
	var npc_name = active_npcs.find_key(emitting_npc)
	debug("\nCAMBIO AZIONE ", npc_name)
	
	match old_action:
		States.WORKING:
			working_npcs = decrease_npcs(working_npcs)
			debug(npc_name, ': stopped working, total working: ', working_npcs)
		States.SCARED:
			scared_npcs = decrease_npcs(scared_npcs)
			debug(npc_name, ': stopped being scared, total scared: ', scared_npcs)
	
	match new_action_enum:
		States.WORKING:
			working_npcs += 1
			debug(npc_name, ': started working, total working: ', working_npcs)
		States.SCARED:
			scared_npcs += 1
			debug(npc_name, ': is scared, total scared: ', scared_npcs)
		States.SLACKING:
			debug(npc_name, ': slacking')
		States.MOVING:
			debug(npc_name, ': moving')
		_:
			debug(npc_name, ': unknown action')


func debug(...args) -> void:
	if DEBUG:
		print(args)
		
func _on_day_end():
	debug("DAY END")
	debug("memorial: ", memorial)
	if (total_revenues >= current_goal):		
		level_popup.visible = true
		$PopoupTimer.start()
		current_goal = roundi(total_revenues * 1.25)
		goal_label.text = str(current_goal)
		total_revenues = 0.0
		hire_npc()
		pass
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal("next_scene", game_over, _construct_memorial)
		pass
	
func _construct_memorial(endScene: DeathEndScene):
	endScene.goblins.append_array(memorial)
	pass


func _on_popoup_timer_timeout() -> void:
	level_popup.visible = false
