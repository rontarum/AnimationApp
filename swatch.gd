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
	
	# Новая архитектура: подписка на EventBus
	EventBus.ui_element_focused.connect(_on_element_focused)
	EventBus.primary_color_changed.connect(_on_primary_color_changed)
	EventBus.secondary_color_changed.connect(_on_secondary_color_changed)
	
	# Инициализация цвета из AppState
	if order == 0:  # Primary swatch
		color = AppState.primary_color
	else:  # Secondary swatch
		color = AppState.secondary_color
	
	# Обратная совместимость (пока)
	if Cursor.has_signal("focus_changed"):
		Cursor.focus_changed.connect(func(node):
			if is_toggled and node != self:
				_toggle()
				if SwatchPicker.instance:
					SwatchPicker.instance.visible = false
		)
	
	if SwatchPicker.instance and SwatchPicker.instance.has_signal("color_picked"):
		SwatchPicker.instance.color_picked.connect(
			func(col, from):
				if from == self:
					_on_color_picked(col)
		)

func _on_element_focused(element: Node) -> void:
	if is_toggled and element != self:
		_toggle()
		if SwatchPicker.instance:
			SwatchPicker.instance.visible = false

func _on_primary_color_changed(new_color: Color) -> void:
	if order == 0:  # Primary swatch
		color = new_color

func _on_secondary_color_changed(new_color: Color) -> void:
	if order == 1:  # Secondary swatch
		color = new_color

func _on_color_picked(new_color: Color) -> void:
	# Новая архитектура: обновляем через AppState
	if order == 0:
		AppState.primary_color = new_color
	else:
		AppState.secondary_color = new_color

func _on_mouse_entered() -> void:
	is_hovered = true
	# Новая архитектура: эмитим событие наведения
	EventBus.ui_element_hovered.emit(self, true)
	
	# Обратная совместимость с курсором (пока)
	if CursorSprite.instance and CursorSprite.instance.has_method("change_shape"):
		CursorSprite.instance.change_shape(Util.ToolType.POINTER)

func _on_mouse_exited() -> void:
	is_hovered = false
	# Новая архитектура: эмитим событие ухода
	EventBus.ui_element_hovered.emit(self, false)
	
	# Обратная совместимость с курсором (пока)
	if CursorSprite.instance and CursorSprite.instance.has_method("change_shape"):
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
		# Новая архитектура: используем AppState для фокуса
		AppState.focused_element = self
		
		# Открываем SwatchPicker (обратная совместимость)
		if SwatchPicker.instance:
			SwatchPicker.instance.toggle(color, self)
		_toggle()
