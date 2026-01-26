class_name CursorSprite extends Sprite2D

static var instance: CursorSprite

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	instance = self
	scale = Vector2(0.5, 0.5)
	offset = Vector2(16.0, 24.0)

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()

func change_shape(type: Util.ToolType) -> void:
	texture = Cursor.get_icon(type)
