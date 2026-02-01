class_name SwatchPicker extends ColorPicker

static var instance: SwatchPicker

signal color_picked(col: Color, from: Node)

var last_node: Node

func _init() -> void:
	instance = self

func _ready() -> void:
	visible = false
	color_changed.connect(_on_color_pick)
	
	# Новая архитектура: подписка на события цветов
	EventBus.primary_color_changed.connect(_on_primary_color_changed)
	EventBus.secondary_color_changed.connect(_on_secondary_color_changed)

func _on_primary_color_changed(new_color: Color) -> void:
	# Обновляем picker если он открыт для primary swatch
	if visible and last_node and last_node.order == 0:
		color = new_color

func _on_secondary_color_changed(new_color: Color) -> void:
	# Обновляем picker если он открыт для secondary swatch
	if visible and last_node and last_node.order == 1:
		color = new_color

func toggle(col: Color, from: Node) -> void:
	color = col
	if visible and last_node == from:
		visible = false
		return
	visible = true
	last_node = from

func _on_color_pick(col: Color) -> void:
	# Эмитим только если есть активный swatch
	if last_node:
		color_picked.emit(col, last_node)
