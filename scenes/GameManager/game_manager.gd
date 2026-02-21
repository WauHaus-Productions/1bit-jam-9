extends Node

@export var map : PackedScene
@export var npc : PackedScene
@onready var camera = $Camera2D
@onready var revenue_ui = $Camera2D/Revenue

@export var npc_counter : int
#TO CHANGE
@export var NPC_REVENUES = 100

var map_instance
var spawn_positions

var total_revenues: float = 0.0

var names : Array[String] = ["Grizzle Profitgrub", "Snark Ledgerfang", "Boggle Spreadsheet", "Krimp Bonusclaw", "Snik KPI-Snatcher", "Murgle Coffeestain", "Zibble Paperjam", "Grint Marginchewer", "Blort Deadlinegnaw", "Skaggy Synergytooth", "Nibwick Microgrind", "Crindle Stocksniff", "Wizzle Cubiclebane", "Throg Expensefang", "Splug Overtimebelch", "Drabble Taskmangler", "Klix Compliancegrime", "Mizzle Workflowrot", "Gorp Staplechewer", "Snibble Budgetbruise", "Kraggy Meetinglurker", "Blim Forecastfumble", "Zonk Assetgnash", "Triggle Slidereviser", "Vorny Timesheetterror", "Glim Auditnibble", "Brakka Breakroomraider", "Sprock Redtapewriggler", "Nurgle Powerpointhex", "Grizzleback Clawculator", "Snaggle Metricsmash", "Plib Shareholdershriek", "Drox Inboxhoarder", "Fizzle Ladderclimb", "Krumble Deskgnarl", "Wretchy Watercoolerspy", "Blix Quarterlyquiver", "Grottin Promotionpounce", "Skibble Faxmachinebane", "Zraggy Corporatecackle"]
var active_npcs: Dictionary[String, Node2D] = {}

var working_npcs: Dictionary[String, Node2D] = {}
var slacking_npcs: Dictionary[String, Node2D] = {}



func determine_spawn_positions(map_instance) -> Array[Vector2i]:
	var tilemap =  map_instance.get_node("TileMap")
	var ground_layer : TileMapLayer = tilemap.get_node("Ground")
	var ground_positions : Array[Vector2i] = ground_layer.get_used_cells()
	
	print(ground_positions)
	
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
	add_child(map_instance)
	

	# GET SPAWNABLE POSITIONS
	var spawnable_positions = determine_spawn_positions(map_instance)
	print(spawnable_positions)
	
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
		
		active_npcs[name] = new_npc
		
		map_instance.add_child(new_npc)
		
	# SET WORKING AND SLACKING NPCs
	working_npcs = active_npcs.duplicate()
	slacking_npcs = {}
	
	var camera_marker = map_instance.get_node("Cameras/Stanza1")
	camera.global_position = camera_marker.global_position

func _process(delta: float) -> void:
	update_revenues(delta)
		
	revenue_ui.text = str(roundi(total_revenues))
		
		
		
	
