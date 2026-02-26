class_name CanvasRenderer extends Node2D

## Отрисовка overlay поверх canvas (pixel preview, selection rect, etc.)
## 
## Зона ответственности:
## - Pixel preview для brush/eraser
## - Selection rectangle для selection tool
## - Canvas border
## 
## НЕ содержит логику инструментов - только визуализация

@export var draw_container: DrawContainer
@export var draw_canvas: SubViewport
@export var draw_camera: CanvasCamera

var mouse_pos: Vector2 = Vector2.ZERO
var slide_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("Draw", true)

func _process(delta: float) -> void:
	if not draw_container or not visible:
		return
	
	mouse_pos = draw_container.get_local_mouse_position()
	slide_pos = lerp(slide_pos, floor(mouse_pos), 63.9 * delta)
	queue_redraw()

func _draw() -> void:
	if not AppState.is_color_picking:
		_draw_pixel_preview()
		_draw_selection_pixels()
		_draw_selection_gizmo()
	_draw_canvas_border()

## Рисует pixel preview для активного инструмента
func _draw_pixel_preview() -> void:
	var active_tool = Services.tool.get_active_draw_tool()
	if not active_tool or not active_tool.should_draw_preview():
		return
	
	# Проверка границ canvas
	if mouse_pos.x < 0.0 or mouse_pos.y < 0.0:
		return
	if mouse_pos.x >= draw_container.size.x or mouse_pos.y >= draw_container.size.y:
		return
	
	# Получаем размер из typed properties
	var brush_size: int = 1
	var tool_type = AppState.current_tool
	var props = Services.tool.get_draw_property(tool_type)
	if props and "size" in props:
		brush_size = props.size
	
	var half_size: int = int(floor(brush_size / 2.0))
	
	# Rect для preview (всегда квадратный)
	var rect: Rect2 = Rect2()
	rect.position = slide_pos - Vector2(half_size, half_size)
	rect.size = Vector2(brush_size, brush_size)
	
	# Получаем цвет текущего пикселя для контрастного stroke
	var pixel: Color = draw_canvas.get_texture().get_image().get_pixelv(floor(mouse_pos))
	var color: Color = AppState.primary_color
	var stroke: Color = Color(Color.WHITE - pixel, 1.0) if pixel.a > 0.0 else Color.BLACK
	
	if color.a > 0:
		stroke = Color(Color.WHITE - color, 1.0) if color.a > 0.0 else Color.BLACK
	
	# Рисуем preview (для Brush и Fill показываем заливку)
	if AppState.current_tool == ToolType.Type.BRUSH or AppState.current_tool == ToolType.Type.FILL:
		draw_rect(rect, color, true)
	
	# Рисуем stroke (контур)
	draw_rect(rect, stroke, false)
	
	# Дополнительный маркер при большом зуме
	if draw_camera and draw_camera.zoom_value.x >= 8.0:
		draw_rect(Rect2(mouse_pos - Vector2(0.04, 0.04), Vector2(0.08, 0.08)), stroke, false, -1.0)

## Рисует border вокруг canvas
func _draw_canvas_border() -> void:
	if not draw_container:
		return
	draw_rect(Rect2(draw_container.get_rect()), Color("454b7386"), false)

## Рисует пиксели выделения во время движения
func _draw_selection_pixels() -> void:
	var active_tool = Services.tool.get_active_draw_tool()
	if not active_tool or not active_tool is SelectionTool:
		return
	
	var selection_tool = active_tool as SelectionTool
	var state = selection_tool.get_current_state()
	
	# Рисуем пиксели только во время движения
	if state != SelectionTool.State.MOVING:
		return
	
	var selection_rect = selection_tool.get_selection_rect()
	var selected_pixels = selection_tool.get_selected_pixels()
	
	# Рисуем каждый пиксель выделения
	for relative_pos in selected_pixels:
		var absolute_pos = selection_rect.position + relative_pos
		var color = selected_pixels[relative_pos]
		
		# Проверяем границы canvas
		if absolute_pos.x >= 0 and absolute_pos.y >= 0 and absolute_pos.x < draw_container.size.x and absolute_pos.y < draw_container.size.y:
			draw_rect(Rect2(absolute_pos, Vector2.ONE), color, true)

## Рисует gizmo выделения для SelectionTool
func _draw_selection_gizmo() -> void:
	var active_tool = Services.tool.get_active_draw_tool()
	if not active_tool or not active_tool is SelectionTool:
		return
	
	var selection_tool = active_tool as SelectionTool
	var state = selection_tool.get_current_state()
	var selection_rect = selection_tool.get_selection_rect()
	
	if state == SelectionTool.State.IDLE or selection_rect.size.x < 1 or selection_rect.size.y < 1:
		return
	
	# Клампим rect к границам canvas
	var canvas_rect = Rect2(Vector2.ZERO, draw_container.size)
	var clamped_rect = selection_rect.intersection(canvas_rect)
	
	# Если rect полностью вне canvas, не рисуем
	if clamped_rect.size.x < 1 or clamped_rect.size.y < 1:
		return
	
	# Рисуем пунктирную рамку (чередование чёрного и белого)
	_draw_dashed_rect(clamped_rect)

## Рисует пунктирную рамку (чёрно-белую)
func _draw_dashed_rect(rect: Rect2) -> void:
	var dash_length: float = 1.0
	var gap_length: float = 0.0
	var pattern_length: float = dash_length + gap_length
	
	# Верхняя линия
	_draw_dashed_line(rect.position, rect.position + Vector2(rect.size.x, 0), dash_length, gap_length)
	
	# Правая линия
	_draw_dashed_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, dash_length, gap_length)
	
	# Нижняя линия
	_draw_dashed_line(rect.position + rect.size, rect.position + Vector2(0, rect.size.y), dash_length, gap_length)
	
	# Левая линия
	_draw_dashed_line(rect.position + Vector2(0, rect.size.y), rect.position, dash_length, gap_length)

## Рисует пунктирную линию (чёрно-белую)
func _draw_dashed_line(from: Vector2, to: Vector2, dash_length: float, gap_length: float) -> void:
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var pattern_length = dash_length + gap_length
	var current_pos = 0.0
	var is_white = true
	
	while current_pos < length:
		var segment_length = min(dash_length, length - current_pos)
		var start = from + direction * current_pos
		var end = from + direction * (current_pos + segment_length)
		
		# Чередуем белый и чёрный
		var color = Color.WHITE if is_white else Color.BLACK
		draw_line(start, end, color, -1.0)
		
		current_pos += pattern_length
		is_white = !is_white
	
