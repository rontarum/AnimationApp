class_name Tool extends TextureRect

@export var type: Util.ToolType

var is_hovered: bool = false

var is_toggled: bool = false

@onready var center: Vector2 = size / 2.0

func _init() -> void:
	expand_mode = TextureRect.EXPAND_KEEP_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	pivot_offset = center
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	Cursor.focus_changed.connect(func(node): if node != self: modulate = Color("ffffffff"))


func _on_mouse_entered() -> void:
	is_hovered = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.07)
	CursorSprite.instance.change_shape(Util.ToolType.POINTER)


func _on_mouse_exited() -> void:
	is_hovered = false
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	CursorSprite.instance.change_shape(Util.ToolType.ARROW)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and is_hovered:
		Cursor.set_focus(self)
		Cursor.focus.modulate = Color(3.299, 1.669, 1.527)
		Cursor.set_mode(type)
