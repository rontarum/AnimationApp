class_name TreeService extends Node

var tree: Tree
var life_container: LifeContainer

func _ready() -> void:
	Services.register("tree", self)
	
	EventBus.tree_item_move_requested.connect(_on_tree_item_move_requested)
	EventBus.tree_item_delete_requested.connect(_on_tree_item_delete_requested)
	EventBus.tree_item_duplicate_requested.connect(_on_tree_item_duplicate_requested)

func set_references(p_tree: Tree, p_container: LifeContainer) -> void:
	tree = p_tree
	life_container = p_container


# Заполнить дерево из SpriteMesh нод
func populate_tree_from_meshes(root_node: Node2D) -> void:
	if not tree:
		return
	
	var root := tree.get_root()
	if not root:
		return
	
	# Полностью очищаем дерево и создаём новый root
	tree.clear()
	root = tree.create_item()
	root.set_text(0, "Root")
	tree.hide_root = true
	
	# Создаём TreeItem для каждого SpriteMesh
	for child in root_node.get_children():
		if child is SpriteMesh:
			_create_tree_item_recursive(child, root)

# Рекурсивное создание TreeItem для SpriteMesh и его детей
func _create_tree_item_recursive(mesh: SpriteMesh, parent_item: TreeItem) -> void:
	var item := create_tree_item_for_mesh(mesh, parent_item)
	
	# Обрабатываем детей
	for child in mesh.get_children():
		if child is SpriteMesh:
			_create_tree_item_recursive(child, item)


# Создать TreeItem для SpriteMesh
func create_tree_item_for_mesh(mesh: SpriteMesh, parent_item: TreeItem = null) -> TreeItem:
	if not tree:
		return null
	
	var item := tree.create_item(parent_item)
	item.set_metadata(0, mesh)
	item.set_text(0, mesh.name)
	
	# Устанавливаем иконку (используем ту же что в tree.gd)
	var leaf_icon = load("uid://c4xs0joffk1d7")
	if leaf_icon:
		item.set_icon(0, leaf_icon)
		item.set_icon_max_width(0, 24)
	
	return item


# Получить SpriteMesh из TreeItem
func get_mesh_from_item(item: TreeItem) -> SpriteMesh:
	if not item:
		return null
	return item.get_metadata(0) as SpriteMesh

# Найти TreeItem по SpriteMesh
func find_tree_item_by_mesh(mesh: SpriteMesh, search_root: TreeItem = null) -> TreeItem:
	if not tree:
		return null
	
	if not search_root:
		search_root = tree.get_root()
	
	if not search_root:
		return null
	
	# Проверяем текущий элемент
	if search_root.get_metadata(0) == mesh:
		return search_root
	
	# Рекурсивно проверяем детей
	for child in search_root.get_children():
		var result := find_tree_item_by_mesh(mesh, child)
		if result:
			return result
	
	return null


# Синхронизация перемещения TreeItem → SpriteMesh
func sync_tree_item_moved(source_item: TreeItem, target_item: TreeItem, section: int) -> void:
	var source_mesh := get_mesh_from_item(source_item)
	var target_mesh := get_mesh_from_item(target_item)
	
	if not source_mesh or not target_mesh or not life_container:
		return
	
	life_container.move_sprite_mesh(source_mesh, target_mesh, section)


# Синхронизация удаления TreeItem → SpriteMesh
func sync_tree_item_deleted(item: TreeItem) -> void:
	var mesh := get_mesh_from_item(item)
	
	if not mesh or not life_container:
		return
	
	life_container.delete_sprite_mesh(mesh)
	item.free()


# Синхронизация дублирования TreeItem → SpriteMesh
func sync_tree_item_duplicated(item: TreeItem) -> TreeItem:
	var mesh := get_mesh_from_item(item)
	
	if not mesh or not life_container:
		return null
	
	var duplicate_mesh := life_container.duplicate_sprite_mesh(mesh)
	if not duplicate_mesh:
		return null
	
	var parent_item := item.get_parent()
	var new_item := create_tree_item_for_mesh(duplicate_mesh, parent_item)
	
	if new_item and item.get_next():
		new_item.move_before(item.get_next())
	
	return new_item


# Обработчики событий
func _on_tree_item_move_requested(source: TreeItem, target: TreeItem, section: int) -> void:
	sync_tree_item_moved(source, target, section)

func _on_tree_item_delete_requested(item: TreeItem) -> void:
	sync_tree_item_deleted(item)

func _on_tree_item_duplicate_requested(item: TreeItem) -> void:
	sync_tree_item_duplicated(item)
