class_name DrawContainer
extends SubViewportContainer

## Viewport container для canvas рисования
## 
## Зона ответственности:
## - Viewport container для DrawCanvas
## - Input routing к активному инструменту
## - Mouse enter/exit для cursor visibility
## 
## НЕ содержит логику рисования или инструментов

@onready var draw_canvas: SubViewport = $DrawCanvas
@onready var draw_camera: CanvasCamera = %DrawCamera

var mouse_pos: Vector2
var active_layer: DrawLayer  # DrawLayer extends TextureRect
var is_hold: bool = false
var use_color: Color

# Selection данные (для будущего SelectionTool)
var selection_rect: Rect2
var selection_start: Vector2
var selection_start_draw: Vector2
var selection_end_draw: Vector2

func _ready() -> void:
	size = AppState.canvas_size
	
	# Подписка на события слоев через EventBus
	EventBus.layer_selected.connect(_on_layer_selected)
	EventBus.canvas_resized.connect(_on_canvas_resized)
	visibility_changed.connect(func(): draw_camera.enabled = visible)

func _process(_delta: float) -> void:
	mouse_pos = get_local_mouse_position()

func _input(event: InputEvent) -> void:
	# === ГЛОБАЛЬНАЯ ОБРАБОТКА (работает везде) ===
	
	var active_tool = Services.tool.get_active_tool()
	if not active_tool or not active_tool is BaseTool:
		return
	
	var pixel_pos = Vector2i(floor(mouse_pos))
	
	# 1. Release - обрабатываем глобально (можно отпустить вне canvas)
	if event.is_action_released("action") or event.is_action_released("cancel"):
		if is_hold:
			is_hold = false
			_resolve_cursor_sprite()
			if active_layer:
				active_tool.on_release(pixel_pos, active_layer, use_color)
	
	# 2. Drag - обрабатываем глобально (можно тянуть за пределы canvas)
	if is_hold and event is InputEventMouseMotion:
		_resolve_cursor_sprite()
		# Рисуем только если мышь в canvas
		if _in_canvas() and active_layer:
			active_tool.on_drag(pixel_pos, active_layer, use_color)
	
	# 3. Resize (add/sub) - глобальные горячие клавиши
	if event.is_action_pressed("add") and not Input.is_key_pressed(KEY_CTRL):
		active_tool.on_resize(pixel_pos, 1)
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("sub") and not Input.is_key_pressed(KEY_CTRL):
		active_tool.on_resize(pixel_pos, -1)
		get_viewport().set_input_as_handled()
	
	# 4. Deselect - глобальная горячая клавиша
	if event.is_action_pressed("deselect") and active_tool is SelectionTool:
		active_tool.deselect()
		Services.cursor.clear_override()
		get_viewport().set_input_as_handled()



func _clear() -> void:
	for c in draw_canvas.get_children():
		if c is TextureRect: continue
		c.queue_free()

func _gui_input(event: InputEvent) -> void:
	# === ЛОКАЛЬНАЯ ОБРАБОТКА (только внутри canvas) ===
	
	if not _in_canvas():
		return
	
	_resolve_cursor_sprite()
	
	var active_tool = Services.tool.get_active_tool()
	if not active_tool or not active_tool is BaseTool:
		return
	
	var pixel_pos = Vector2i(floor(mouse_pos))
	
	# 1. Press - начинаем действие только внутри canvas
	if event.is_action_pressed("action"):
		if not active_layer:
			return
		is_hold = true
		use_color = AppState.primary_color
		active_tool.on_press(pixel_pos, active_layer, use_color)
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("cancel"):
		if not active_layer:
			return
		is_hold = true
		use_color = AppState.secondary_color
		active_tool.on_press(pixel_pos, active_layer, use_color)
		get_viewport().set_input_as_handled()
	
	# 2. Hover - только внутри canvas (для preview)
	if event is InputEventMouseMotion:
		active_tool.on_hover(pixel_pos)
		
		# Смена курсора для SelectionTool
		if active_tool is SelectionTool:
			var selection_tool = active_tool as SelectionTool
			match selection_tool.get_current_state():
				SelectionTool.State.IDLE:
					Services.cursor.show_cursor()
				SelectionTool.State.SELECTING:
					Services.cursor.hide_cursor()
				SelectionTool.State.SELECTED:
					if selection_tool._is_inside_selection(pixel_pos):
						# Курсор DRAG при наведении на выделенную область
						Services.cursor.show_cursor()
						Services.cursor.set_override(ToolType.Type.DRAG)
					else:
						# Обычный курсор вне выделения
						Services.cursor.clear_override()

func _in_canvas() -> bool:
	if mouse_pos.x < 0.0 or \
	mouse_pos.y < 0.0 or \
	mouse_pos.x >= size.x or \
	mouse_pos.y >= size.y:
		return false
	return true

func _on_canvas_resized(new_size: Vector2i) -> void:
	size = new_size

func _on_layer_selected(layer_id: int) -> void:
	# Обработка пустого состояния (нет слоёв)
	if layer_id == -1:
		active_layer = null
		return
	
	# Находим соответствующий draw layer по ID
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if draw_layer:
		active_layer = draw_layer
	else:
		pass

func _on_mouse_entered() -> void:
	_resolve_cursor_sprite()

func _on_mouse_exited() -> void:
	if AppState.is_color_picking:
		return
	
	# Уведомляем активный инструмент о выходе мыши
	var active_tool = Services.tool.get_active_tool()
	if active_tool and active_layer:
		active_tool.on_mouse_exit(active_layer)
	
	# Сбрасываем override курсора (для SelectionTool и других)
	if Services.cursor:
		Services.cursor.clear_override()
		Services.cursor.show_cursor()
	
	# НЕ сбрасываем is_hold - drag может продолжаться вне canvas
	# is_hold сбросится при release в _input()

func _resolve_cursor_sprite() -> void:
	if not Services.cursor:
		return
	if AppState.is_color_picking:
		return
	
	# Если мышь вне области canvas, всегда показываем курсор и сбрасываем override
	if not _in_canvas():
		Services.cursor.clear_override()
		Services.cursor.show_cursor()
		return
		
	match AppState.current_tool:
		ToolType.Type.BRUSH, ToolType.Type.ERASER, ToolType.Type.FILL:
			Services.cursor.hide_cursor()
		_:
			Services.cursor.show_cursor()
