extends Tree

const LEAF = preload("uid://c4xs0joffk1d7")

func _ready() -> void:
	drop_mode_flags = 0
	
	var root := create_item()
	root.set_text(0, "Root")
	hide_root = true
	
	_create_item("Leaf 1", root)
	var l := _create_item("Leaf 2", root)
	_create_item("Leaf 3", l)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
		NOTIFICATION_DRAG_END:
			drop_mode_flags = 0

func _create_item(label: String, parent: TreeItem = null) -> TreeItem:
	var leaf := create_item(parent)
	leaf.set_icon(0, LEAF)
	leaf.set_icon_max_width(0, 24)
	leaf.set_text(0, label)
	return leaf

func _get_drag_data(at_position: Vector2) -> Variant:
	var item := get_item_at_position(at_position)
	if item == null or item == get_root():
		return null
	
	var preview := Leaf.new().get_preview(item.get_text(0))
	set_drag_preview(preview)
	
	return item 

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is TreeItem):
		return false
	
	var target := get_item_at_position(at_position)
	if target == null or target == data:
		return false
	
	var check := target
	while check != null:
		if check == data:
			return false
		check = check.get_parent()
	
	return true
	

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var source: TreeItem = data
	var target := get_item_at_position(at_position)
	if target == null:
		return

	# section: -1 = выше, 0 = на элемент, 1 = ниже
	var section := get_drop_section_at_position(at_position)

	# Нельзя сделать sibling-ом root — превращаем в child root
	if (section == -1 or section == 1) and target.get_parent() == null:
		section = 0

	# Сохраняем всё поддерево source
	var saved := _save_subtree(source)
	# Удаляем оригинал
	source.free()

	match section:
		0:
			# НА элемент → source становится последним ребёнком target
			_restore_subtree(saved, target)
		-1:
			# ВЫШЕ target → вставляем как sibling перед ним
			var new_item := _restore_subtree(saved, target.get_parent())
			new_item.move_before(target)
		1:
			# НИЖЕ target → вставляем как sibling после него
			var new_item := _restore_subtree(saved, target.get_parent())
			new_item.move_after(target)

func _save_subtree(item: TreeItem) -> Dictionary:
	var data := {
		"text":      item.get_text(0),
		"icon":      item.get_icon(0),
		"metadata":  item.get_metadata(0) if item.get_metadata(0) != null else null,
		"collapsed": item.collapsed,
		"children":  [] as Array[Dictionary],
	}
	for child in item.get_children():
		data["children"].append(_save_subtree(child))
	return data

func _restore_subtree(data: Dictionary, parent: TreeItem) -> TreeItem:
	var item := create_item(parent)
	item.set_text(0, data["text"])
	if data["icon"] != null:
		item.set_icon(0, data["icon"])
	if data["metadata"] != null:
		item.set_metadata(0, data["metadata"])
	item.collapsed = data["collapsed"]
	for child_data: Dictionary in data["children"]:
		_restore_subtree(child_data, item)
	return item
	
