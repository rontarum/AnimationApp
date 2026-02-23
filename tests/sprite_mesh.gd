class_name SpriteMesh extends MeshInstance2D

enum VertexState {PASSIVE, HOVERED, ACTIVE}
enum EdgeState {BOUND, PASSIVE, ACTIVE, POLYGON}

@export var vertex_icons: Array[Texture2D]

var vertex: PackedVector2Array = []
var uv: PackedVector2Array = []
var index: PackedInt32Array = []

var draw_canvas: RID
var mouse_pixel_pos: Vector2
var first_vertex: Vector2
var last_vertex: Vector2
var active_vertex: Vector2

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
