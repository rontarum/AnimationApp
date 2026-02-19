class_name Leaf extends Button

const LEAF = preload("uid://c4xs0joffk1d7")

func _init() -> void:
	icon = LEAF
	expand_icon = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(128.0, 32.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

#func _get_drag_data(at_position: Vector2) -> Variant:
	#var preview := duplicate()
	#preview.modulate = Color("efdfdf")
	#preview.modulate.a = 0.64
	#set_drag_preview(preview)
	#
	#return self

func get_preview(label: String) -> Leaf:
	text = label
	self_modulate = Color("efdfdf")
	self_modulate.a = 0.64
	return self
