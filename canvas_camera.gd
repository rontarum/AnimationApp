class_name CanvasCamera
extends Camera2D

static var instance: CanvasCamera

@export var zoom_step: float = 2.0
var zoom_value: Vector2

var drag_mouse: Vector2
var drag_camera: Vector2
var is_dragging: bool = false

var mouse_pos: Vector2
var new_mouse_pos: Vector2
var diff: Vector2

var anchor: Vector2

func _init() -> void:
	instance = self

func _ready() -> void:
	zoom = Vector2.ONE
	position = DrawViewport.canvas_size * 0.5
	zoom_value = zoom

func _process(delta: float) -> void:
	_zoom(delta)

func _zoom(delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	new_mouse_pos = mouse_pos
	
	if Input.is_action_just_pressed("zoom_in"):
		zoom_value *= zoom_step
	if Input.is_action_just_pressed("zoom_out"):
		zoom_value /= zoom_step
	
	zoom = lerp(zoom, zoom_value, 36.9 * delta)
	new_mouse_pos = get_global_mouse_position()
	if (zoom - zoom_value).length() > 0.001:
		diff = mouse_pos - new_mouse_pos
	else:
		diff = Vector2(0.0, 0.0)
	
	position = _drag() + diff

func _drag() -> Vector2:
	var mouse_vp := get_viewport().get_mouse_position()
	if !is_dragging and Input.is_action_just_pressed("drag"):
		drag_mouse = mouse_vp
		drag_camera = position
		is_dragging = true
		CursorSprite.instance.change_shape(Util.ToolType.GRAB)
	
	if is_dragging and Input.is_action_just_released("drag"):
		is_dragging = false
		CursorSprite.instance.change_shape(Util.ToolType.ARROW)
	
	if is_dragging:
		var move_vector: Vector2 = mouse_vp - drag_mouse
		return drag_camera - move_vector * 1.0 / zoom.x
	return position
