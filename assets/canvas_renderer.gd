class_name CanvasRenderer extends Node2D

## Отрисовка overlay поверх canvas (pixel preview, selection rect, etc.)
## 
## Зона ответственности:
## - Pixel preview для brush/eraser
## - Selection rectangle для selection tool
## - Canvas border
## 
## НЕ содержит логику инструментов - только визуализация

@onready var draw_container: DrawContainer = get_parent()
@onready var draw_canvas: SubViewport = draw_container.draw_canvas

var mouse_pos: Vector2 = Vector2.ZERO
var slide_pos: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if not draw_container:
		return
	
	mouse_pos = draw_container.get_local_mouse_position()
	slide_pos = lerp(slide_pos, floor(mouse_pos), 36.9 * delta)
	queue_redraw()

func _draw() -> void:
	_draw_pixel_preview()
	_draw_canvas_border()

## Рисует pixel preview для активного инструмента
func _draw_pixel_preview() -> void:
	var active_tool = Services.tool.get_active_tool()
	if not active_tool or not active_tool.should_draw_preview():
		return
	
	# Проверка границ canvas
	if mouse_pos.x < 0.0 or mouse_pos.y < 0.0:
		return
	if mouse_pos.x >= draw_container.size.x or mouse_pos.y >= draw_container.size.y:
		return
	
	# Rect для preview пикселя
	var rect: Rect2 = Rect2()
	rect.position = slide_pos
	rect.end = slide_pos + Vector2(1, 1)
	
	# Получаем цвет текущего пикселя для контрастного stroke
	var pixel: Color = draw_canvas.get_texture().get_image().get_pixelv(floor(mouse_pos))
	var color: Color = AppState.primary_color
	var stroke: Color = Color(Color.WHITE - pixel, 1.0) if pixel.a > 0.0 else Color.BLACK
	
	if color.a > 0:
		stroke = Color(Color.WHITE - color, 1.0) if color.a > 0.0 else Color.BLACK
	
	# Рисуем preview (только для Brush, Eraser не показывает fill)
	if AppState.current_tool == ToolType.Type.BRUSH:
		draw_rect(rect, color, true)
	
	# Рисуем stroke (контур)
	draw_rect(rect, stroke, false)
	
	# Дополнительный маркер при большом зуме
	if CanvasCamera.instance and CanvasCamera.instance.zoom_value.x >= 8.0:
		draw_rect(Rect2(mouse_pos - Vector2(0.04, 0.04), Vector2(0.08, 0.08)), stroke, false, -1.0)

## Рисует border вокруг canvas
func _draw_canvas_border() -> void:
	if not draw_container:
		return
	draw_rect(Rect2(draw_container.get_rect()), Color("454b7386"), false)
