extends Node

var high : int:#最高分
	get:
		return high
	set(value):
		if value > high:
			high = value

func _ready() -> void:
	SaveLoad.load()
