class_name SwatchPicker extends ColorPicker

static var instance: SwatchPicker

signal color_picked(col: Color, from: Node)

var last_node: Node

func _init() -> void:
	instance = self

func _ready() -> void:
	visible = false
	color_changed.connect(_on_color_pick)

func toggle(col: Color, from: Node) -> void:
	color = col
	if visible and last_node == from:
		visible = false
		return
	visible = true
	last_node = from

func _on_color_pick(col: Color) -> void:
	color_picked.emit(col, last_node)
