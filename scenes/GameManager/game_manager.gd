extends BaseScene

@export var map : PackedScene
@export var npc : PackedScene
@onready var camera = $Camera2D
@onready var revenue_ui = $Camera2D/Revenue

@export var npc_counter : int
#TO CHANGE
const NPC_REVENUES = 100

var map_instance
var spawn_positions

var tot_rooms = 4
var current_camera_idx = 1


var total_revenues: float = 0.0

var names : Array[String] = ["Grizzle Profitgrub", "Snark Ledgerfang", "Boggle Spreadsheet", "Krimp Bonusclaw", "Snik KPI-Snatcher", "Murgle Coffeestain", "Zibble Paperjam", "Grint Marginchewer", "Blort Deadlinegnaw", "Skaggy Synergytooth", "Nibwick Microgrind", "Crindle Stocksniff", "Wizzle Cubiclebane", "Throg Expensefang", "Splug Overtimebelch", "Drabble Taskmangler", "Klix Compliancegrime", "Mizzle Workflowrot", "Gorp Staplechewer", "Snibble Budgetbruise", "Kraggy Meetinglurker", "Blim Forecastfumble", "Zonk Assetgnash", "Triggle Slidereviser", "Vorny Timesheetterror", "Glim Auditnibble", "Brakka Breakroomraider", "Sprock Redtapewriggler", "Nurgle Powerpointhex", "Grizzleback Clawculator", "Snaggle Metricsmash", "Plib Shareholdershriek", "Drox Inboxhoarder", "Fizzle Ladderclimb", "Krumble Deskgnarl", "Wretchy Watercoolerspy", "Blix Quarterlyquiver", "Grottin Promotionpounce", "Skibble Faxmachinebane", "Zraggy Corporatecackle"]
var active_npcs: Dictionary[String, Node2D] = {}

var working_npcs: Dictionary[String, Node2D] = {}
var slacking_npcs: Dictionary[String, Node2D] = {}

var memorial : Array[String] = []

var States = {SCARED = 2, WORKING = 1, MOVING = -2, SLACKING = -1}



func determine_spawn_positions(map_instance) -> Array[Vector2i]:
	var tilemap =  map_instance.get_node("TileMap")
	var ground_layer : TileMapLayer = tilemap.get_node("Ground")
	var ground_positions : Array[Vector2i] = ground_layer.get_used_cells_by_id(-1,Vector2i(0,0))
		
	var obstacle_layer : TileMapLayer = tilemap.get_node("Obstacles")
	var obstacle_positions : Array[Vector2i] = obstacle_layer.get_used_cells()
	
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
	

func update_revenues(delta):
	for npc in self.working_npcs:
		self.total_revenues += NPC_REVENUES*delta

func _ready() -> void:
	# SET RANDOMIZER
	randomize()
	
	# SPAWN MAP
	map_instance = map.instantiate()
	map_instance.global_position = Vector2(0,0)
	add_child(map_instance)
	

	# GET SPAWNABLE POSITIONS
	var spawnable_positions = determine_spawn_positions(map_instance)
	
	# SPAWN NPCs
	for n in npc_counter:
		var name = names.pick_random()
		print("Spawning Goblin ", name)
		var new_npc = npc.instantiate()
		
		var random_spawn_position = spawnable_positions.pick_random()
		spawnable_positions.erase(random_spawn_position)
		
		new_npc.global_position = random_spawn_position
		print("in position ", random_spawn_position)
		new_npc.name = name
		
		# SUBSCRIBE TO SIGNALS
		new_npc.get_node("Logic").switching.connect(_on_change_state)
		new_npc.get_node("Logic").dying.connect(_on_death)
		
		active_npcs[name] = new_npc
		
		map_instance.add_child(new_npc)
		
	# SET WORKING AND SLACKING NPCs
	working_npcs = active_npcs.duplicate()
	slacking_npcs = {}
	
	var camera_marker = map_instance.get_node("Cameras/Stanza1")
	camera.global_position = camera_marker.global_position

func change_camera(direction):
	if direction == "foreward" and current_camera_idx < tot_rooms:
		current_camera_idx += 1
		var camera_name = "Cameras/Stanza"+str(current_camera_idx)
		var camera_marker = map_instance.get_node(camera_name)
		camera.global_position = camera_marker.global_position
		
	elif direction == "backwards" and current_camera_idx != 1:
		current_camera_idx -= 1
		var camera_name = "Cameras/Stanza"+str(current_camera_idx)
		var camera_marker = map_instance.get_node(camera_name)
		camera.global_position = camera_marker.global_position
	else:
		return
		
func _process(delta: float) -> void:
	update_revenues(delta)
		
	revenue_ui.text = str(roundi(total_revenues))
	
	if active_npcs.size() == 0:
		print(memorial)
	
	if Input.is_action_just_pressed("camera_fwd"):
		print("Camera Foreward")
		change_camera("foreward")
		
	if Input.is_action_just_pressed("camera_bwd"):
		print("Camera Backwards")
		change_camera("backwards")
		

func _on_death(dying_npc: Node2D):
	var dying_name = active_npcs.find_key(dying_npc)
	print("STA MORENDO ", dying_name)
	if dying_name != null:
		active_npcs.erase(dying_name)
		
	if dying_name in working_npcs.keys():
		working_npcs.erase(dying_name)
		
	if dying_npc in slacking_npcs.keys():
		slacking_npcs.erase(dying_name)
	
	dying_npc.queue_free()
	memorial.append(dying_name)
	
func _on_change_state(new_action_enum: int, emitting_npc: Node2D):
	var npc_name = active_npcs.find_key(emitting_npc)
	print("\nCAMBIO AZIONE ", npc_name)
	if new_action_enum == States.WORKING:
		print('working')
	elif new_action_enum == States.SLACKING:
		print('slacking')
	elif new_action_enum == States.SCARED:
		print('scared')
	elif new_action_enum == States.MOVING:
		print('moving')
	else:
		print('unknown action')
