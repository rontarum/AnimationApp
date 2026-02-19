@tool
class_name SpriteMesh extends MeshInstance2D

enum VertexState {PASSIVE, HOVERED, ACTIVE}
enum EdgeState {BOUND, PASSIVE, ACTIVE, POLYGON}

@export var vertex_icons: Array[Texture2D]

var surface: Array = []
var generated_mesh: ArrayMesh

var vertex: PackedVector2Array = []
var uv: PackedVector2Array = []
var index: PackedInt32Array = []

var draw_canvas: RID
var mouse_pixel_pos: Vector2
var first_vertex: Vector2
var last_vertex: Vector2
var active_vertex: Vector2

func _ready() -> void:
	var size := texture.get_size()
	
	vertex = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	copy_uv()
	index = PackedInt32Array([0, 1, 2, 0, 2, 3])
	
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertex
	surface[Mesh.ARRAY_TEX_UV] = uv
	surface[Mesh.ARRAY_INDEX] = index
	
	generated_mesh = ArrayMesh.new()
	generated_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	#mesh = generated_mesh
	queue_redraw()

func add_point(point: Vector2) -> void:
	if vertex.has(point):
		return
	vertex.append(point)

func remove_point(point: Vector2) -> void:
	vertex.erase(point)

func copy_uv() -> void:
	if not uv.is_empty():
		uv = []
	uv = _uvs_from_vertices(vertex)

func draw_vertex(canvas_item: RID, state: VertexState, pos: Vector2) -> void:
	var rs := RenderingServer
	var icon: Texture2D
	icon = vertex_icons[state]
	var offset := Vector2(0.25, 0.25)
	var rect := Rect2(pos - offset, Vector2(0.5, 0.5))
	rs.canvas_item_clear(canvas_item)
	rs.canvas_item_add_texture_rect(canvas_item, rect, icon )

func _draw() -> void:
	# Отрисовка текстуры для удобства редактирования точек
	if not mesh:
		draw_texture(texture, position, Color.AQUA)
	
	

func draw_on_canvas(canvas_item: RID) -> void:
	var rs := RenderingServer
	rs.canvas_item_clear(canvas_item)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pixel_pos = round(get_global_mouse_position())
		var rs := RenderingServer
		if not draw_canvas:
			draw_canvas = rs.canvas_item_create()
			rs.canvas_item_set_parent(draw_canvas, get_canvas_item())
			rs.canvas_item_set_transform(draw_canvas, transform)
		draw_vertex(draw_canvas, VertexState.PASSIVE, mouse_pixel_pos)

func _uvs_from_vertices(vertices: PackedVector2Array) -> PackedVector2Array:
	if vertices.is_empty():
		return PackedVector2Array()
	
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	
	for v in vertices:
		min_x = min(min_x, v.x)
		min_y = min(min_y, v.y)
		max_x = max(max_x, v.x)
		max_y = max(max_y, v.y)
	
	var w = max_x - min_x
	var h = max_y - min_y
	
	var uvs := PackedVector2Array()
	uvs.resize(vertices.size())
	
	if w <= 0 or h <= 0:
		for i in vertices.size():
			uvs[i] = Vector2(0.5, 0.5)  # fallback
	else:
		for i in vertices.size():
			var v = vertices[i]
			uvs[i] = Vector2(
				(v.x - min_x) / w,
				(v.y - min_y) / h
			)
	
	return uvs
