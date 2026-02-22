extends Area2D

@export var reserved: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reserved = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func reserve() -> void:
	reserved = true

func leave() -> void:
	reserved = false

func is_reserved() -> bool:
	return reserved