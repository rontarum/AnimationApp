class_name DrawLayer extends TextureRect

## DrawLayer - слой рисования на canvas
## 
## Зона ответственности:
## - Хранение и управление Image данными
## - Методы set_pixel/get_pixel для рисования
## - Работает через layer_id (int), не зависит от UI Layer

var image: Image
var tex: ImageTexture
var layer_id: int = -1
var undo_redo: UndoRedo
var image_data_before: PackedByteArray
var image_data_after: PackedByteArray

func _init(_size: Vector2i, _layer_id: int, _image: Image = null) -> void:
	layer_id = _layer_id
	
	if _image:
		image = _image
	else:
		image = Image.create_empty(_size.x, _size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)  # Прозрачный по умолчанию
	
	tex = ImageTexture.create_from_image(image)
	texture = tex
	EventBus.layer_image_updated.emit(layer_id, image)

func _ready() -> void:
	# Подписка на события через EventBus
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed)
	undo_redo = History.undo_redo

func get_image() -> Image:
	return image

func get_pixel(point: Vector2i) -> Color:
	var img_size = image.get_size()
	if point.x < 0 or point.y < 0 or point.x >= img_size.x or point.y >= img_size.y:
		return Color.TRANSPARENT
	return image.get_pixelv(point)

func set_pixel(point: Vector2i, color: Color) -> void:
	var img_size = image.get_size()
	if point.x < 0 or point.y < 0 or point.x >= img_size.x or point.y >= img_size.y:
		return
	
	image.set_pixelv(point, color)
	update_image()

func update_image() -> void:
	tex.update(image)
	EventBus.layer_image_updated.emit(layer_id, image)

# Вызываем это ПЕРЕД началом изменений (Input.is_action_just_pressed)
func start_changes() -> void:
	image_data_before = image.get_data()

# Вызываем это ПОСЛЕ завершения изменений (Input.is_action_just_released)
func finish_changes() -> void:
	image_data_after = image.get_data()
	
	undo_redo.create_action("Image changes")
	undo_redo.add_do_method(_apply_image_data.bind(image_data_after))
	undo_redo.add_undo_method(_apply_image_data.bind(image_data_before))
	undo_redo.commit_action(false)

func set_image(new_image: Image) -> void:
	image.copy_from(new_image)
	update_image()
	

func clear_image() -> void:
	start_changes()
	image.fill(Color.TRANSPARENT)
	update_image()
	finish_changes()

func resize_layer(new_size: Vector2i) -> void:
	var temp: Image = Image.create_empty(new_size.x, new_size.y, false, Image.FORMAT_RGBA8)
	temp.fill(Color.TRANSPARENT)
	temp.blend_rect(image, image.get_used_rect(), Vector2i.ZERO)
	image.copy_from(temp)
	tex = ImageTexture.create_from_image(image)
	texture = tex

func get_image_size() -> Vector2i:
	return image.get_size()

func _apply_image_data(image_data: PackedByteArray) -> void:
	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, image_data)
	update_image()

func _on_layer_visibility_changed(id: int, is_visible: bool) -> void:
	if id == layer_id:
		visible = is_visible
