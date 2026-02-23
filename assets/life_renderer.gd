class_name LifeRenderer extends Node2D

@onready var life_container: LifeContainer = get_parent()
@onready var life_canvas: SubViewport = life_container.life_canvas

var mouse_pos: Vector2 = Vector2.ZERO
var slide_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("Draw", true)
