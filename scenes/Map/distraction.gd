extends Area2D

@export var reserved: bool

func _ready() -> void:
	reserved = false


func reserve() -> void:
	reserved = true

func leave() -> void:
	reserved = false

func is_reserved() -> bool:
	return reserved
