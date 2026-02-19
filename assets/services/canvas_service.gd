## CanvasService - Управление холстом
##
## Отвечает за операции рисования, работу с пикселями и изображениями слоёв.
## Координирует взаимодействие между инструментами и слоями.

class_name CanvasService
extends Node

# Ссылка на DrawCanvas (SubViewport)
var draw_canvas: SubViewport = null

# Кэш DrawLayer по layer_id
var draw_layers: Dictionary = {}

func _ready() -> void:
	Services.register("canvas", self)
	
	# Подписка на события
	EventBus.layer_created.connect(_on_layer_created)
	EventBus.layer_deleted.connect(_on_layer_deleted)
	EventBus.canvas_resized.connect(_on_canvas_resized)
	EventBus.layer_clear_requested.connect(_on_layer_clear_requested)
	
## Инициализация с DrawCanvas
func initialize(canvas: SubViewport) -> void:
	draw_canvas = canvas

func resize_canvas(new_size: Vector2i) -> void:
	if new_size.x < 1 or new_size.y < 1 \
	or new_size.x > 640 or new_size.y > 640:
		return
	AppState.canvas_size = new_size

func import_image(image: Image, path: String) -> void:
	resize_canvas(image.get_size())
	var layer_service := Services.layer
	var layer_name: String = path.get_file().get_basename()
	layer_service.create_layer(layer_name)
	set_draw_layer_image(0, image)

func save_canvas_image(path: String) -> void:
	var canvas_size := AppState.canvas_size
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for dr: DrawLayer in draw_layers.values():
		var img := dr.get_image()
		image.blend_rect(img, Rect2(Vector2.ZERO, img.get_size()), Vector2.ZERO)
	
	image.save_png(path)

func save_layers_as_pngs(dir: String) -> void:
	for dr: DrawLayer in draw_layers.values():
		var img := dr.get_image()
		var layers: LayerService = Services.layer
		var nam: String = layers.get_layer_name(dr.layer_id)
		img.save_png(dir + "/%s-%s.png" % [dr.get_index(), nam])

## Создание DrawLayer для слоя
func create_draw_layer(layer_id: int, size: Vector2i) -> Node:
	if not draw_canvas:
		push_error("[CanvasService] DrawCanvas not initialized")
		return null
	
	# Создаём DrawLayer (extends TextureRect)
	var draw_layer = DrawLayer.new(size, layer_id)
	draw_canvas.add_child(draw_layer)
	draw_layer.name = "DrawLayer" + str(layer_id)
	
	draw_layers[layer_id] = draw_layer
	
	return draw_layer

func update_draw_layer(layer_id: int, size: Vector2i) -> void:
	var draw_layer = draw_layers.get(layer_id)
	if draw_layer:
		draw_layer.resize_layer(size)

func set_draw_layer_image(layer_id: int, image: Image) -> void:
	var draw_layer: DrawLayer = draw_layers.get(layer_id)
	if draw_layer:
		draw_layer.set_image(image)

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

func _on_canvas_resized(new_size: Vector2i) -> void:
	for layer_id: int in draw_layers.keys():
		update_draw_layer(layer_id, new_size)

func _on_layer_created(layer_data: Dictionary) -> void:
	# Создаём DrawLayer для нового слоя
	var layer_id = layer_data.get("id", -1)
	if layer_id != -1:
		create_draw_layer(layer_id, AppState.canvas_size)

func _on_layer_clear_requested(layer_id: int) -> void:
	var draw_layer: DrawLayer = draw_layers.get(layer_id)
	if draw_layer:
		draw_layer.clear_image()
		EventBus.layer_cleared.emit(layer_id)

func _on_layer_deleted(layer_id: int) -> void:
	# Удаляем DrawLayer
	delete_draw_layer(layer_id)
