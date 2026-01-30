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

func _init(_size: Vector2i, _layer_id: int, _image: Image = null) -> void:
	layer_id = _layer_id
	
	if _image:
		image = _image
	else:
		image = Image.create_empty(_size.x, _size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)  # Прозрачный по умолчанию
	
	tex = ImageTexture.create_from_image(image)
	texture = tex

func _ready() -> void:
	# Подписка на события через EventBus
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed)

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

func update_image() -> void:
	tex.update(image)

func resize_layer(new_size: Vector2i) -> void:
	var temp: Image = Image.create_empty(new_size.x, new_size.y, false, Image.FORMAT_RGBA8)
	temp.fill(Color.TRANSPARENT)
	temp.blend_rect(image, image.get_used_rect(), Vector2i.ZERO)
	image.copy_from(temp)
	tex = ImageTexture.create_from_image(image)
	texture = tex

func get_image_size() -> Vector2i:
	return image.get_size()

func _on_layer_visibility_changed(id: int, is_visible: bool) -> void:
	if id == layer_id:
		visible = is_visible
