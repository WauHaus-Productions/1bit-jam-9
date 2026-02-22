extends BaseScene

@export var map: PackedScene
@export var npc: PackedScene
@onready var camera = $Camera2D
@onready var revenue_ui = $Camera2D/Revenue

@onready var bg_music = $BGMusic
@onready var bg_office_sound: AudioStreamPlayer = $BGOfficeSound

@export var npc_counter: int = 10
@export var DEBUG: bool = false

#TO CHANGE
const NPC_REVENUES = 100

var map_instance
var spawn_positions

var tot_rooms = 4
var current_camera_idx = 1


var total_revenues: float = 0.0

const names: Array[String] = ["Grizzle Profitgrub", "Snark Ledgerfang", "Boggle Spreadsheet", "Krimp Bonusclaw", "Snik KPI-Snatcher", "Murgle Coffeestain", "Zibble Paperjam", "Grint Marginchewer", "Blort Deadlinegnaw", "Skaggy Synergytooth", "Nibwick Microgrind", "Crindle Stocksniff", "Wizzle Cubiclebane", "Throg Expensefang", "Splug Overtimebelch", "Drabble Taskmangler", "Klix Compliancegrime", "Mizzle Workflowrot", "Gorp Staplechewer", "Snibble Budgetbruise", "Kraggy Meetinglurker", "Blim Forecastfumble", "Zonk Assetgnash", "Triggle Slidereviser", "Vorny Timesheetterror", "Glim Auditnibble", "Brakka Breakroomraider", "Sprock Redtapewriggler", "Nurgle Powerpointhex", "Grizzleback Clawculator", "Snaggle Metricsmash", "Plib Shareholdershriek", "Drox Inboxhoarder", "Fizzle Ladderclimb", "Krumble Deskgnarl", "Wretchy Watercoolerspy", "Blix Quarterlyquiver", "Grottin Promotionpounce", "Skibble Faxmachinebane", "Zraggy Corporatecackle"]
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

	self.total_revenues += working_npcs_revenue + scared_npcs_revenue


func get_available_name() -> String:
	name = names.pick_random()
	while name in active_npcs.keys():
		name = names.pick_random()
	return name

func _ready() -> void:
	# SET RANDOMIZER
	randomize()
	
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
	
	# START BG MUSIC
	bg_music.play()
	bg_office_sound.play()


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
	new_npc.get_node("Logic").dying.connect(_on_death)
	
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
			
		var camera_name = "Cameras/Stanza" + str(current_camera_idx)
		var camera_marker = map_instance.get_node(camera_name)
		camera.global_position = camera_marker.global_position
		
	elif direction == "backwards":
		if current_camera_idx == 1:
			current_camera_idx = tot_rooms
		else:
			current_camera_idx -= 1
			
		var camera_name = "Cameras/Stanza" + str(current_camera_idx)
		var camera_marker = map_instance.get_node(camera_name)
		camera.global_position = camera_marker.global_position
	else:
		return
		
func _process(delta: float) -> void:
	update_revenues(delta)
		
	revenue_ui.text = str(roundi(total_revenues))
	
	if active_npcs.size() == 0:
		debug(memorial)
	
	if Input.is_action_just_pressed("camera_fwd"):
		change_camera("foreward")
		
	if Input.is_action_just_pressed("camera_bwd"):
		change_camera("backwards")

	if Input.is_action_just_pressed("Hire"):
		hire_npc()


func _on_death(dying_npc: Node2D, state: int) -> void:
	var dying_name = active_npcs.find_key(dying_npc)
	debug("STA MORENDO ", dying_name)
	if dying_name != null:
		active_npcs.erase(dying_name)
	
	match state:
		States.WORKING:
			working_npcs = decrease_npcs(working_npcs)
		States.SCARED:
			scared_npcs = decrease_npcs(scared_npcs)
		_:
			debug("Error, dying npc in state: ", state)
	
	dying_npc.queue_free()
	memorial.append(dying_name)


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