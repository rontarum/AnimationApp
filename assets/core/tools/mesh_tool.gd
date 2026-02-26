class_name MeshTool extends LifeTool

enum Mode {SELECT, ADD, REMOVE}

var mode: Mode = Mode.SELECT

var active_item: SpriteMesh

#func _init() -> void:
	#active_item = AppState.active_item_id
	#EventBus.item_selected

func handle_input(event: InputEvent, item: SpriteMesh) -> void:
	
	if not item:
		return
	if event.is_action_pressed("action"):
		add_point(item, round(event.position))
	if event.is_action_pressed("cancel"):
		remove_point(item, round(event.position))

func add_point(item: SpriteMesh, position: Vector2) -> void:
	var vertex := item.vertex
	if vertex.has(position):
		print(item.name, " already has point ", position)
		return
	vertex.append(position)
	_copy_uv(item)
	print(item.name, " + new point ", position)

func remove_point(item: SpriteMesh, position: Vector2) -> void:
	var vertex := item.vertex
	if vertex.has(position):
		vertex.erase(position)
		_copy_uv(item)
		print(item.name, " - removed point ", position)

func make_mesh(item: SpriteMesh) -> void:
	item.index = Geometry2D.triangulate_delaunay(item.vertex)
	
	var surface: Array = []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = item.vertex
	surface[Mesh.ARRAY_TEX_UV] = item.uv
	surface[Mesh.ARRAY_INDEX] = item.index
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	item.mesh = mesh
	print("Mesh for %s was successfully maded" % item.name)

func create_polygon(item: SpriteMesh) -> void:
	var image := item.texture.get_image()
	
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
	item.vertex = hull
	_copy_uv(item)
	print("Polygon %s for %s was successfully created" % [item.vertex, item.name])

func _copy_uv(item: SpriteMesh) -> void:
	if not item.uv.is_empty():
		item.uv = []
	item.uv = _uvs_from_vertices(item.vertex)

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

## Signal handlers for MeshProps
func _on_create_polygon_requested() -> void:
	if active_item:
		create_polygon(active_item)

func _on_make_mesh_requested() -> void:
	if active_item:
		make_mesh(active_item)

func _on_clear_vertices_requested() -> void:
	if active_item:
		active_item.vertex.clear()
		active_item.uv.clear()
		active_item.index.clear()
		print(active_item.name, " vertices cleared")

## Connect to MeshProps signals
func connect_to_properties(properties: Resource) -> void:
	if properties.has_signal("create_polygon_requested"):
		properties.create_polygon_requested.connect(_on_create_polygon_requested)
	if properties.has_signal("make_mesh_requested"):
		properties.make_mesh_requested.connect(_on_make_mesh_requested)
	if properties.has_signal("clear_vertices_requested"):
		properties.clear_vertices_requested.connect(_on_clear_vertices_requested)
