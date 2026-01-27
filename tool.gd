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
	
	# Новая архитектура: подписка на EventBus
	EventBus.ui_element_focused.connect(_on_element_focused)
	
	# Обратная совместимость (пока)
	if Cursor.has_signal("focus_changed"):
		Cursor.focus_changed.connect(func(node): if node != self: modulate = Color("ffffffff"))

func _on_element_focused(element: Node) -> void:
	if element != self:
		modulate = Color("ffffffff")


func _on_mouse_entered() -> void:
	is_hovered = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.07)
	
	# Новая архитектура: эмитим событие наведения
	EventBus.ui_element_hovered.emit(self, true)
	
	# Обратная совместимость с курсором (пока)
	if CursorSprite.instance and CursorSprite.instance.has_method("change_shape"):
		CursorSprite.instance.change_shape(Util.ToolType.POINTER)

func _on_mouse_exited() -> void:
	is_hovered = false
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Новая архитектура: эмитим событие ухода
	EventBus.ui_element_hovered.emit(self, false)
	
	# Обратная совместимость с курсором (пока)
	if CursorSprite.instance and CursorSprite.instance.has_method("change_shape"):
		CursorSprite.instance.change_shape(Util.ToolType.ARROW)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and is_hovered:
		# Новая архитектура: используем EventBus и AppState
		AppState.focused_element = self
		modulate = Color(3.299, 1.669, 1.527)
		
		# Выбираем инструмент через ToolService
		Services.tool.select_tool(type)
		
		# Обратная совместимость с курсором (пока)
		if Cursor.has_method("set_mode"):
			Cursor.set_mode(type)
