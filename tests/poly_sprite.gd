class_name PolySprite extends Sprite2D

@export var debug: bool = false
@export var vertex_size: float = 0.12
@export var vertex_color: Color = Color.PALE_TURQUOISE
var mouse_pixel_pos: Vector2
var first_vertex: Vector2
var last_vertex: Vector2
var active_vertex: Vector2

var size: Vector2

var surface: Array = []
var generated_mesh: ArrayMesh = ArrayMesh.new()

var vertex: PackedVector2Array = []
var uv: PackedVector2Array = []
var index: PackedInt32Array = []

func _init() -> void:
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertex
	surface[Mesh.ARRAY_TEX_UV] = uv
	surface[Mesh.ARRAY_INDEX] = index
	
	size = texture.get_size()

func _draw() -> void:
	if not debug:
		return
	
	draw_circle(mouse_pixel_pos, vertex_size, vertex_color, false)
	
	if _in_bounds():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.69, 0.93, 0.93, 0.36), false, -1.0)
	
	if vertex.is_empty():
		return
	
	for i: int in vertex.size():
		draw_circle(vertex[i], vertex_size, vertex_color, true)
		if vertex.size() > i + 1:
			draw_line(vertex[i], vertex[i + 1], vertex_color)
		else:
			draw_line(vertex[i], mouse_pixel_pos, vertex_color)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pixel_pos = round(get_global_mouse_position())
		queue_redraw()
	
	if event.is_action_pressed("action"):
		if vertex.has(mouse_pixel_pos):
			return
		vertex.append(mouse_pixel_pos)
		
		if not first_vertex:
			first_vertex = mouse_pixel_pos
			last_vertex = mouse_pixel_pos
			active_vertex = mouse_pixel_pos
		else:
			last_vertex = active_vertex
			active_vertex = mouse_pixel_pos
		print(vertex)
		queue_redraw()
	
	if event.is_action_pressed("cancel"):
		if vertex.has(mouse_pixel_pos):
			vertex.erase(mouse_pixel_pos)
			queue_redraw()

func _in_bounds() -> bool:
	if mouse_pixel_pos.x < 0.0 or mouse_pixel_pos.x > size.x or \
	mouse_pixel_pos.y < 0.0 or mouse_pixel_pos.y > size.y:
		return false
	return true
