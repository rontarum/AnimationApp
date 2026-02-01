class_name BrushTool extends BaseTool

## Инструмент кисти - рисует пиксели выбранным цветом
## 
## Зона ответственности:
## - Установка пикселя в указанной позиции
## - Обновление preview данных для отрисовки

var _temp_position: Vector2i

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.start_changes()
		_draw_brush(position, layer, color)
		_temp_position = position

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		var diff: float = abs(_temp_position.length() - position.length())
		if diff < 0.04:
			return
		_draw_brush(position, layer, color)
		_temp_position = position

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.finish_changes()

func _draw_brush(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	var brush_size: int = int(Services.tool.get_tool_property("size"))
	var brush_shape: int = int(Services.tool.get_tool_property("shape"))  # 0=square, 1=circle
	var half_size: int = int(floor(brush_size / 2.0))
	
	# Рисуем кисть в зависимости от формы
	if brush_shape == 0:  # Square
		_draw_square_brush(position, layer, color, brush_size, half_size)
	else:  # Circle
		_draw_circle_brush(position, layer, color, brush_size, half_size)
	
	preview_position = position
	preview_color = color

func _draw_square_brush(position: Vector2i, layer: DrawLayer, color: Color, brush_size: int, half_size: int) -> void:
	for x in range(-half_size, brush_size - half_size):
		for y in range(-half_size, brush_size - half_size):
			var pixel_pos = position + Vector2i(x, y)
			if limits_check(pixel_pos):
				continue
			
			var source: Color = layer.get_pixel(pixel_pos)
			var blended: Color = _blend_colors(source, color)
			
			layer.set_pixel(pixel_pos, blended)

func _draw_circle_brush(position: Vector2i, layer: DrawLayer, color: Color, brush_size: int, half_size: int) -> void:
	for x in range(-half_size, half_size + 1):
		var dx := Vector2i(x, 0)
		var dist_x := x*x
		var yy := int(sqrt(half_size * half_size - dist_x))
		
		for y in range(-yy, yy + 1):
			var pixel_pos = position + dx + Vector2i(0, y)
			if limits_check(pixel_pos):
				continue
				
			var source: Color = layer.get_pixel(pixel_pos)
			var blended: Color = _blend_colors(source, color)
			layer.set_pixel(pixel_pos, blended)

func on_hover(position: Vector2i) -> void:
	preview_position = position
	# preview_color будет установлен при press/drag

func should_draw_preview() -> bool:
	return true

func _blend_colors(source: Color, color: Color) -> Color:
	var blended: Color = source * (1.0 - color.a) + color * color.a
	blended.a = source.a + color.a
	return blended
