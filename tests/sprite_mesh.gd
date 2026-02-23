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
	
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertex
	surface[Mesh.ARRAY_TEX_UV] = uv
	surface[Mesh.ARRAY_INDEX] = index
	
	generated_mesh = ArrayMesh.new()
	#generated_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	#mesh = generated_mesh
	
	vertex = create_polygon()
	index = Geometry2D.triangulate_delaunay(vertex)
	
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
		draw_texture(texture, position)
		
	#if vertex:
		#var polygon := vertex
		#polygon.push_back(vertex[0])
		#draw_polyline(polygon, Color.AQUA)
		#for v in vertex:
			#draw_circle(v, 0.04, Color.AQUA)
	if index:
		draw_triangulation(vertex, index)

func draw_triangulation(poly: PackedVector2Array, indices: PackedInt32Array):
	for i in range(0, indices.size(), 3):
		var a := poly[indices[i]]
		var b := poly[indices[i+1]]
		var c := poly[indices[i+2]]
		
		draw_line(a, b, Color.CORAL, 0.048)
		draw_line(b, c, Color.CORAL, 0.048)
		draw_line(c, a, Color.CORAL, 0.048)

func create_polygon() -> PackedVector2Array:
	var image := texture.get_image()
	
	var points: Array[Vector2] = []
	var w := image.get_width()
	var h := image.get_height()
	
	for y in range(h):
		for x in range(w):
			if image.get_pixel(x, y).a > 0.1:
				points.append(Vector2(x, y))
				points.append(Vector2(x + 1, y))
				points.append(Vector2(x + 1, y + 1))
				points.append(Vector2(x, y + 1))
	if points.size() < 3:
		return PackedVector2Array(points)
	
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	hull.append(floor(image.get_size() * 0.5))
	return hull

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
