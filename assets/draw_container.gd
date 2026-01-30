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

static var instance: DrawContainer

var mouse_pos: Vector2
var active_layer: DrawLayer  # DrawLayer extends TextureRect
var is_hold: bool = false
var use_color: Color

# Selection данные (для будущего SelectionTool)
var selection_rect: Rect2
var selection_start: Vector2
var selection_start_draw: Vector2
var selection_end_draw: Vector2

func _init() -> void:
	instance = self

func _ready() -> void:
	size = AppState.canvas_size
	
	# Подписка на события слоев через EventBus
	EventBus.layer_selected.connect(_on_layer_selected)
	EventBus.canvas_resized.connect(_on_canvas_resized)

func _process(_delta: float) -> void:
	mouse_pos = get_local_mouse_position()

func _clear() -> void:
	for c in draw_canvas.get_children():
		if c is TextureRect: continue
		c.queue_free()

func _gui_input(event: InputEvent) -> void:
	if not _in_canvas():
		return
	
	var active_tool: BaseTool = Services.tool.get_active_tool()
	if not active_tool:
		return
	
	var pixel_pos = Vector2i(floor(mouse_pos))
	
	
	# Press
	if event.is_action_pressed("action"):
		if not active_layer:
			return
		is_hold = true
		use_color = AppState.primary_color
		active_tool.on_press(pixel_pos, active_layer, use_color)
	
	if event.is_action_pressed("cancel"):
		if not active_layer:
			return
		is_hold = true
		use_color = AppState.secondary_color
		active_tool.on_press(pixel_pos, active_layer, use_color)
	
	# Release
	if event.is_action_released("action") or event.is_action_released("cancel"):
		is_hold = false
		if active_layer:
			active_tool.on_release(pixel_pos, active_layer, use_color)
	
	# Drag
	if is_hold and event is InputEventMouseMotion:
		if active_layer:
			active_tool.on_drag(pixel_pos, active_layer, use_color)
		
	
	if event.is_action_pressed("add") and not Input.is_key_pressed(KEY_CTRL):
		active_tool.on_resize(pixel_pos, 1)
	if event.is_action_pressed("sub") and not Input.is_key_pressed(KEY_CTRL):
		active_tool.on_resize(pixel_pos, -1)
	
	# Обработка deselect для SelectionTool
	if event.is_action_pressed("deselect") and active_tool is SelectionTool:
		active_tool.deselect()
		Services.cursor.clear_override()
	
	# Hover (для preview)
	if event is InputEventMouseMotion:
		active_tool.on_hover(pixel_pos)
		
		# Смена курсора для SelectionTool
		if active_tool is SelectionTool:
			var selection_tool = active_tool as SelectionTool
			if selection_tool.get_current_state() == SelectionTool.State.SELECTED:
				if selection_tool._is_inside_selection(pixel_pos):
					# Курсор DRAG при наведении на выделенную область
					Services.cursor.set_override(ToolType.Type.DRAG)
				else:
					# Обычный курсор вне выделения
					Services.cursor.clear_override()
	
	if event.is_action_pressed("undo"):
		Services.canvas.resize_canvas(Vector2i(128, 128))

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
		print("[DrawContainer] No active layer (empty state)")
		return
	
	# Находим соответствующий draw layer по ID
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if draw_layer:
		active_layer = draw_layer
		print("[DrawContainer] Selected layer: ID=", layer_id)
	else:
		print("[DrawContainer] Draw layer not found: ID=", layer_id)

func _on_mouse_entered() -> void:
	match AppState.current_tool:
		ToolType.Type.BRUSH, ToolType.Type.ERASER, ToolType.Type.FILL:
			if Services.cursor:
				Services.cursor.hide_cursor()
		_:
			if Services.cursor:
				Services.cursor.show_cursor()

func _on_mouse_exited() -> void:
	# Уведомляем активный инструмент о выходе мыши
	var active_tool = Services.tool.get_active_tool()
	if active_tool and active_layer:
		active_tool.on_mouse_exit(active_layer)
	
	if Services.cursor:
		Services.cursor.show_cursor()
	
	is_hold = false
