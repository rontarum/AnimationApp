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

@export var canvas_size: Vector2i = Vector2i(32, 32)
@onready var draw_canvas: SubViewport = $DrawCanvas

static var instance: DrawContainer

var mouse_pos: Vector2
var active_layer: DrawLayer  # DrawLayer extends TextureRect
var is_hold: bool = false

# Selection данные (для будущего SelectionTool)
var selection_rect: Rect2
var selection_start: Vector2
var selection_start_draw: Vector2
var selection_end_draw: Vector2

func _init() -> void:
	instance = self

func _ready() -> void:
	size = canvas_size
	
	# Подписка на события слоев через EventBus
	EventBus.layer_selected.connect(_on_layer_selected)

func _process(_delta: float) -> void:
	mouse_pos = get_local_mouse_position()

func _clear() -> void:
	for c in draw_canvas.get_children():
		if c is TextureRect: continue
		c.queue_free()

func _gui_input(event: InputEvent) -> void:
	var active_tool = Services.tool.get_active_tool()
	if not active_tool:
		return
	
	# Проверка границ canvas
	if mouse_pos.x < 0.0 or mouse_pos.y < 0.0:
		return
	if mouse_pos.x >= size.x or mouse_pos.y >= size.y:
		return
	
	var pixel_pos = Vector2i(floor(mouse_pos))
	
	# Press
	if event.is_action_pressed("action"):
		if not active_layer:
			return
		is_hold = true
		active_tool.on_press(pixel_pos, active_layer, AppState.primary_color)
		selection_start = event.position
	
	# Release
	if event.is_action_released("action"):
		is_hold = false
		if active_layer:
			active_tool.on_release(pixel_pos, active_layer, AppState.primary_color)
	
	# Drag
	if is_hold and event is InputEventMouseMotion:
		if active_layer:
			active_tool.on_drag(pixel_pos, active_layer, AppState.primary_color)
		
		# Selection rect (для будущего SelectionTool)
		var selection_end: Vector2 = event.position
		var diff := selection_end - selection_start
		selection_start_draw = selection_start_draw.lerp(selection_start.snapped(Vector2.ONE), 0.1)
		selection_end_draw = selection_end_draw.lerp(diff.snapped(Vector2.ONE), 0.1)
		selection_rect = Rect2(selection_start_draw, selection_end_draw).abs()
	
	# Hover (для preview)
	if event is InputEventMouseMotion:
		active_tool.on_hover(pixel_pos)

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
		ToolType.Type.BRUSH, ToolType.Type.ERASER:
			if Services.cursor:
				Services.cursor.hide_cursor()
		_:
			if Services.cursor:
				Services.cursor.show_cursor()

func _on_mouse_exited() -> void:
	if Services.cursor:
		Services.cursor.show_cursor()
