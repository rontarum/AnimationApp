class_name DrawLayer extends TextureRect

var image: Image
var tex: ImageTexture
var layer: Layer

var is_active: bool = false

func _init(_size: Vector2i, _layer: Layer, _image: Image = null) -> void:
	if _image:
		image = _image
		tex = ImageTexture.create_from_image(image)
		texture = tex
		return
	
	image = Image.create_empty(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	var random_color: Color = Color(randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0), 1.0)
	image.fill(random_color)
	tex = ImageTexture.create_from_image(image)
	texture = tex
	
	layer = _layer
	layer.visibility_changed.connect(_on_visibility_changed)
	layer.activity_changed.connect(_on_activity_changed)
	layer.moved.connect(_on_layer_moved)
	layer.tree_exiting.connect(func(): queue_free())

func _ready() -> void:
	queue_redraw()

func get_pixel(point: Vector2i) -> Color:
	return image.get_pixelv(point)

func set_pixel(point: Vector2i, color: Color) -> void:
	image.set_pixelv(point, color)
	tex.update(image)

func _on_visibility_changed() -> void:
	visible = layer.is_visible()

func _on_activity_changed(value: bool) -> void:
	is_active = value

func _on_layer_moved() -> void:
	get_parent().move_child(self, layer.get_index())
