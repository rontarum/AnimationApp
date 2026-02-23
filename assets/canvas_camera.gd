class_name CanvasCamera
extends Camera2D

static var instance: CanvasCamera

@export var min_zoom: float = 1.0
@export var max_zoom: float = 64.0

@export var zoom_step: float = 2.0
var zoom_value: Vector2

var drag_mouse: Vector2
var drag_camera: Vector2
var is_dragging: bool = false

var mouse_pos: Vector2
var new_mouse_pos: Vector2
var diff: Vector2

func _init() -> void:
	instance = self

func _ready() -> void:
	zoom = Vector2.ONE
	position = AppState.canvas_size * 0.5
	zoom_value = zoom
	EventBus.canvas_resized.connect(func(size): center_view(size); zoom_to(Vector2.ONE))

func _process(delta: float) -> void:
	_zoom(delta)

func center_view(size: Vector2i) -> void:
	if size:
		position = size * 0.5
	else:
		position = AppState.canvas_size * 0.5

func zoom_to(to: Vector2) -> void:
	zoom = to
	position = AppState.canvas_size * 0.5
	zoom_value = to

func _zoom(delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	new_mouse_pos = mouse_pos

	if Input.is_action_just_pressed("zoom_in"):
		zoom_value *= zoom_step
	if Input.is_action_just_pressed("zoom_out"):
		zoom_value /= zoom_step

	zoom_value = _clamp_zoom(zoom_value)

	zoom = lerp(zoom, zoom_value, 36.9 * delta)
	new_mouse_pos = get_global_mouse_position()
	if (zoom - zoom_value).length() > 0.001:
		diff = mouse_pos - new_mouse_pos
	else:
		diff = Vector2(0.0, 0.0)

	position = _clamp_position(_drag() + diff)

func _drag() -> Vector2:
	var mouse_vp := get_viewport().get_mouse_position()
	if !is_dragging and Input.is_action_just_pressed("drag"):
		drag_mouse = mouse_vp
		drag_camera = position
		is_dragging = true
		# Меняем курсор на GRAB при начале перетаскивания
		if Services.cursor:
			Services.cursor.set_override(ToolType.Type.GRAB)

	if is_dragging and Input.is_action_just_released("drag"):
		is_dragging = false
		# Возвращаем курсор текущего инструмента
		if Services.cursor:
			Services.cursor.clear_override()

	if is_dragging:
		var move_vector: Vector2 = mouse_vp - drag_mouse
		var new_position = drag_camera - move_vector * 1.0 / zoom.x
		return new_position
	return position

func _clamp_zoom(zoom_vector: Vector2) -> Vector2:
	var clamped_value = clamp(zoom_vector.x, min_zoom, max_zoom)
	return Vector2(clamped_value, clamped_value)

func _clamp_position(pos: Vector2) -> Vector2:
	var canvas_size = AppState.canvas_size
	var viewport_size = get_viewport().get_visible_rect().size
	var current_zoom = zoom.x

	# Рассчитываем видимую область в пикселях холста
	var visible_area = viewport_size / current_zoom
	var half_visible = visible_area / 16

	# Определяем границы позиции камеры
	var min_x = half_visible.x
	var max_x = canvas_size.x - half_visible.x
	var min_y = half_visible.y
	var max_y = canvas_size.y - half_visible.y

	# Если холст меньше видимой области, центрируем камеру
	if max_x < min_x:
		var center_x = canvas_size.x * 0.5
		min_x = center_x
		max_x = center_x
	if max_y < min_y:
		var center_y = canvas_size.y * 0.5
		min_y = center_y
		max_y = center_y

	return Vector2(
		clamp(pos.x, min_x, max_x),
		clamp(pos.y, min_y, max_y)
	)
