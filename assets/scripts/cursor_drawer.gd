class_name CursorDrawer extends Node2D

static var instance: CursorDrawer

var is_selecting: bool = false
var selection_rect: Rect2

func _init() -> void:
	instance = self

func draw_selection(rect: Rect2) -> void:
	selection_rect = rect
	is_selecting = true
	queue_redraw()

func _draw() -> void:
	if is_selecting:
		return
		draw_rect(selection_rect, Color(0.482, 0.699, 0.867, 0.494), true)
