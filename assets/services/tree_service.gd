class_name TreeService extends Node

func _ready() -> void:
	Services.register("tree", self)
