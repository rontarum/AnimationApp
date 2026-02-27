class_name LifeContainer extends SubViewportContainer

@onready var life_canvas: SubViewport = $LifeCanvas
@onready var life_camera: CanvasCamera = %LifeCamera

var root_item: Node2D = Node2D.new()
var active_item: SpriteMesh

var mouse_pos: Vector2

func _ready() -> void:
	size = AppState.canvas_size * 2.0
	life_camera.set_canvas_size(size)
	
	root_item.name = "RootItem"
	#root_item.position = size * 0.5
	root_item.position = size * 0.5 - AppState.canvas_size * 0.5
	life_canvas.add_child(root_item, true)
	
	EventBus.canvas_resized.connect(_on_canvas_resized)
	EventBus.tab_changed.connect(_on_tab_changed)
	EventBus.item_selected.connect(_on_item_selected)
	visibility_changed.connect(func(): life_camera.enabled = visible)
	
	# Регистрируем себя в TreeService
	Services.tree.life_container = self

func _on_tab_changed(tab: int) -> void:
	if tab == 1:
		_items_from_layers()

func _items_from_layers() -> void:
	var layers: Dictionary = Services.canvas.get_all_layers()
	if layers.is_empty():
		return
	
	# Очищаем существующие SpriteMesh немедленно
	for child in root_item.get_children():
		child.free()  # Немедленное удаление вместо queue_free
	
	# Создаём SpriteMesh для каждого слоя
	for layer: DrawLayer in layers.values():
		var image := layer.get_image()
		var rect := image.get_used_rect()
		if rect.has_area():
			var trimmed := Image.create(rect.size.x, rect.size.y, false, image.get_format())
			trimmed.blit_rect(image, rect, Vector2.ZERO)
			image = trimmed
			
		var item := SpriteMesh.new()
		item.name = layer.get_layer_name()
		item.texture = ImageTexture.create_from_image(image)
		var rect_center := (Vector2(rect.position) * 0.5)
		item.position = rect_center
		root_item.add_child(item)
	
	# Инициализируем дерево
	Services.tree.populate_tree_from_meshes(root_item)

func _on_canvas_resized(new_size: Vector2i) -> void:
	size = new_size * 2.0

func _gui_input(event: InputEvent) -> void:
	var active_tool = Services.tool.get_active_life_tool()
	if not active_tool or not active_item:
		return
	
	active_tool.handle_input(event, active_item)

func _on_item_selected(item_id: int) -> void:
	if item_id < 0 or item_id >= root_item.get_child_count():
		active_item = null
		return
	
	var item = root_item.get_child(item_id)
	if item is SpriteMesh:
		active_item = item
	else:
		active_item = null


# Перемещение SpriteMesh (только порядок, без вложенности)
func move_sprite_mesh(mesh: SpriteMesh, target_mesh: SpriteMesh, section: int) -> void:
	if not mesh or not target_mesh:
		return
	
	var parent := target_mesh.get_parent()
	if not parent:
		return
	
	# Перемещаем только в том же родителе (меняем порядок)
	if mesh.get_parent() != parent:
		mesh.reparent(parent)
	
	match section:
		-1:  # Над target
			parent.move_child(mesh, target_mesh.get_index())
		1:  # Под target
			parent.move_child(mesh, target_mesh.get_index() + 1)
		0:  # На target - игнорируем, не делаем вложенность
			parent.move_child(mesh, target_mesh.get_index())


# Удаление SpriteMesh
func delete_sprite_mesh(mesh: SpriteMesh) -> void:
	if mesh:
		mesh.free()  # Немедленное удаление


# Дублирование SpriteMesh
func duplicate_sprite_mesh(mesh: SpriteMesh) -> SpriteMesh:
	if not mesh:
		return null
	
	var dup := mesh.duplicate() as SpriteMesh
	var parent := mesh.get_parent()
	if parent:
		parent.add_child(dup)
		parent.move_child(dup, mesh.get_index() + 1)
	
	return dup
