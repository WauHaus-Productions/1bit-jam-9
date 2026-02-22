extends Node

@export var first_scene: PackedScene
@export var settings_button: PackedScene

signal level_started
signal level_ended
signal settings_switched

var paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_next_scene(first_scene, _default_constructor)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_next_scene(game_scene: PackedScene, constructor: Callable) -> void:
	var instance
	print(game_scene)
	if game_scene != null:
		instance = game_scene.instantiate()
		print("Scene pre ctor: ", instance)
		if (constructor != null):
			constructor.call(instance)
	else:
		instance = first_scene.instantiate()
		print("Load Default Scene: ", instance)
	
	print("Scene post ctor: ", instance)
	instance.next_scene.connect(_on_next_scene)
	print("Scene post connect: ", instance)
	
	#get_tree().change_scene_to(instance)	
	var activeScenes = get_children()
	
	if instance.is_in_group("level"):
		emit_signal("level_started")
	else:
		if activeScenes.size() > 0 and activeScenes[0].is_in_group("level"):
			emit_signal("level_ended")
		
	for scene in activeScenes:
		remove_child(scene) # Remove the child from the parent node
		scene.queue_free()
	
	var button = settings_button.instantiate()
		
	instance.add_child(button)
	button.settings_switched.connect(_switch_settings)
	
	add_child(instance)
	
func _default_constructor(scene):
	pass
	
func _switch_settings():
	emit_signal("settings_switched")


func _on_settings_switched() -> void:
	#var activeScenes = get_children()
	#print("Paused was: ", get_tree().paused)
	#for scene in activeScenes:
		#print(scene)
		#print(scene.get_tree().paused)
		#if scene.get_tree().paused:
			#scene.get_tree().paused = false
		#else:
			#scene.get_tree().paused = true
			#
	#print("Paused is: ", get_tree().paused)
	#var activeScenes = get_children()
	#for scene in activeScenes:
		#print(scene)
		#if paused:
			#scene.get_tree().paused = false
			#paused = false
		#else:
			#scene.get_tree().paused = true
			#paused = true
	pass
