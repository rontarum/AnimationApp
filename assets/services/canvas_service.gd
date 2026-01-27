## CanvasService - Управление холстом
##
## Отвечает за операции рисования, работу с пикселями и изображениями слоёв.
## Координирует взаимодействие между инструментами и слоями.

class_name CanvasService
extends Node

# Размер холста по умолчанию
const CANVAS_SIZE := Vector2(32, 32)

# Ссылка на DrawCanvas (SubViewport)
var draw_canvas: SubViewport = null

# Кэш DrawLayer по layer_id
var draw_layers: Dictionary = {}

func _ready() -> void:
	Services.register("canvas", self)
	
	# Подписка на события
	EventBus.canvas_pixel_changed.connect(_on_pixel_changed)
	EventBus.canvas_cleared.connect(_on_canvas_cleared)
	EventBus.layer_created.connect(_on_layer_created)
	EventBus.layer_deleted.connect(_on_layer_deleted)
	EventBus.tool_action_updated.connect(_on_tool_action_updated)

## Инициализация с DrawCanvas
func initialize(canvas: SubViewport) -> void:
	draw_canvas = canvas
	print("[CanvasService] Initialized with canvas")

## Установка пикселя на активном слое
func set_pixel(position: Vector2i, color: Color) -> void:
	var active_layer_id = AppState.active_layer_id
	if active_layer_id == -1:
		return
	
	var draw_layer = draw_layers.get(active_layer_id)
	if draw_layer and draw_layer.has_method("set_pixel"):
		draw_layer.set_pixel(position, color)
		EventBus.canvas_pixel_changed.emit(position, color)

## Получение цвета пикселя на активном слое
func get_pixel(position: Vector2i) -> Color:
	var active_layer_id = AppState.active_layer_id
	if active_layer_id == -1:
		return Color.TRANSPARENT
	
	var draw_layer = draw_layers.get(active_layer_id)
	if draw_layer and draw_layer.has_method("get_pixel"):
		return draw_layer.get_pixel(position)
	
	return Color.TRANSPARENT

## Создание DrawLayer для слоя
func create_draw_layer(layer_id: int, size: Vector2i, layer_ui: Node = null) -> Node:
	if not draw_canvas:
		push_error("[CanvasService] DrawCanvas not initialized")
		return null
	
	# Создаём DrawLayer (extends TextureRect)
	var draw_layer = DrawLayer.new(size, layer_id)
	draw_canvas.add_child(draw_layer)
	draw_layer.name = "DrawLayer_" + str(layer_id)
	
	draw_layers[layer_id] = draw_layer
	
	return draw_layer

## Удаление DrawLayer
func delete_draw_layer(layer_id: int) -> void:
	var draw_layer = draw_layers.get(layer_id)
	if draw_layer:
		draw_layer.queue_free()
		draw_layers.erase(layer_id)

## Очистка холста
func clear_canvas() -> void:
	for draw_layer in draw_layers.values():
		if draw_layer:
			draw_layer.queue_free()
	draw_layers.clear()
	EventBus.canvas_cleared.emit()

## Получение DrawLayer по layer_id
func get_draw_layer(layer_id: int):
	return draw_layers.get(layer_id)

# === ОБРАБОТЧИКИ СОБЫТИЙ ===

func _on_pixel_changed(position: Vector2i, color: Color) -> void:
	pass  # Можно добавить логику для истории изменений

func _on_canvas_cleared() -> void:
	print("[CanvasService] Canvas cleared")

func _on_layer_created(layer_data: Dictionary) -> void:
	# Создаём DrawLayer для нового слоя
	var layer_id = layer_data.get("id", -1)
	if layer_id != -1:
		create_draw_layer(layer_id, AppState.canvas_size)

func _on_layer_deleted(layer_id: int) -> void:
	# Удаляем DrawLayer
	delete_draw_layer(layer_id)

func _on_tool_action_updated(position: Vector2) -> void:
	# Обработка действия инструмента (рисование)
	var tool_type = AppState.current_tool
	var pos_int = Vector2i(floor(position.x), floor(position.y))
	
	# Проверка границ
	if pos_int.x < 0 or pos_int.y < 0:
		return
	if pos_int.x >= AppState.canvas_size.x or pos_int.y >= AppState.canvas_size.y:
		return
	
	match tool_type:
		ToolType.Type.BRUSH:
			if AppState.is_drawing:
				set_pixel(pos_int, AppState.primary_color)
		ToolType.Type.ERASER:
			if AppState.is_drawing:
				set_pixel(pos_int, Color.TRANSPARENT)
