class_name Swatch extends ColorRect

@export var order: int = 0
var is_hovered: bool = false
var is_toggled: bool = false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	Cursor.focus_changed.connect(func(node):
		if is_toggled and node != self:
			_toggle()
			SwatchPicker.instance.visible = false
		)
	SwatchPicker.instance.color_picked.connect(
		func(col, from):
			if from == self:
				color = col
				Cursor.primary_swatch = color
			)
	Cursor.primary_swatch = color

func _on_mouse_entered() -> void:
	is_hovered = true
	CursorSprite.instance.change_shape(Util.ToolType.POINTER)

func _on_mouse_exited() -> void:
	is_hovered = false
	CursorSprite.instance.change_shape(Util.ToolType.ARROW)

func _toggle() -> void:
	var tween = get_tree().create_tween()
	if not is_toggled:
		tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		is_toggled = true
	else:
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		is_toggled = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and is_hovered:
		Cursor.set_focus(self)
		SwatchPicker.instance.toggle(color, self)
		_toggle()
