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
	# Конвертируем изображение в RGBA8 формат
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	
	var layer_service := Services.layer
	var layer_name: String = path.get_file().get_basename()
	
	# Проверяем, есть ли уже слои (проект создан)
	if layer_service.layers.size() > 0:
		# Проект уже существует - создаём новый слой и вставляем изображение в центр
		var layer_id: int = layer_service.create_layer(layer_name)
		var draw_layer: DrawLayer = draw_layers.get(layer_id)
		
		if draw_layer:
			# Вычисляем позицию для центрирования
			var canvas_size := AppState.canvas_size
			var img_size := image.get_size()
			var offset := Vector2i(
				(canvas_size.x - img_size.x) >> 1,
				(canvas_size.y - img_size.y) >> 1
			)
			
			# Копируем изображение в центр слоя
			for y in range(img_size.y):
				for x in range(img_size.x):
					var target_pos := Vector2i(x + offset.x, y + offset.y)
					# Проверяем границы
					if target_pos.x >= 0 and target_pos.y >= 0 and target_pos.x < canvas_size.x and target_pos.y < canvas_size.y:
						draw_layer.image.set_pixelv(target_pos, image.get_pixelv(Vector2i(x, y)))
			
			draw_layer.update_image()
	else:
		# Пустой канвас - изменяем размер под изображение
		resize_canvas(image.get_size())
		var layer_id: int = layer_service.create_layer(layer_name)
		set_draw_layer_image(layer_id, image)

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

## Получение всех изображений слоёв (для сохранения)
func get_all_layer_images() -> Dictionary:
	var result: Dictionary = {}
	for layer_id: int in draw_layers.keys():
		var draw_layer: DrawLayer = draw_layers[layer_id]
		if draw_layer and draw_layer.image:
			result[layer_id] = draw_layer.image.get_data()
	return result

## Установка изображений слоёв (для загрузки)
func set_all_layer_images(images: Dictionary) -> void:
	for layer_id: int in images.keys():
		var draw_layer: DrawLayer = draw_layers.get(layer_id)
		if draw_layer and draw_layer.image:
			var img_data: PackedByteArray = images[layer_id]
			var size: Vector2i = draw_layer.image.get_size()
			draw_layer.image.set_data(size.x, size.y, false, Image.FORMAT_RGBA8, img_data)
			draw_layer.update_image()

# === ОБРАБОТЧИКИ СОБЫТИЙ ===

func _on_canvas_resized(new_size: Vector2i) -> void:
	for layer_id: int in draw_layers.keys():
		update_draw_layer(layer_id, new_size)

func _on_layer_created(layer_data: Dictionary) -> void:
	# Создаём DrawLayer для нового слоя (если ещё не существует)
	var layer_id = layer_data.get("id", -1)
	if layer_id != -1 and not draw_layers.has(layer_id):
		create_draw_layer(layer_id, AppState.canvas_size)

func _on_layer_clear_requested(layer_id: int) -> void:
	var draw_layer: DrawLayer = draw_layers.get(layer_id)
	if draw_layer:
		draw_layer.clear_image()
		EventBus.layer_cleared.emit(layer_id)

func _on_layer_deleted(layer_id: int) -> void:
	# Удаляем DrawLayer
	delete_draw_layer(layer_id)
