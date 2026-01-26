extends TextureRect

func _init() -> void:
	expand_mode = TextureRect.EXPAND_FIT_WIDTH
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _draw() -> void:
	draw_rect(get_rect(), Color("444b737f"), false)
