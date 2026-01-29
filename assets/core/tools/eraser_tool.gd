class_name EraserTool extends BaseTool

## Инструмент ластика - стирает пиксели (делает прозрачными)
## 
## Зона ответственности:
## - Установка прозрачного пикселя в указанной позиции
## - Обновление preview данных для отрисовки

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		_draw_eraser(position, layer)

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		_draw_eraser(position, layer)

func _draw_eraser(position: Vector2i, layer: DrawLayer) -> void:
	var brush_size: int = int(Services.tool.get_tool_property("size"))
	var half_size: int = int(floor(brush_size / 2.0))
	
	# Стираем квадратную область
	for x in range(-half_size, brush_size - half_size):
		for y in range(-half_size, brush_size - half_size):
			var pixel_pos = position + Vector2i(x, y)
			layer.set_pixel(pixel_pos, Color.TRANSPARENT)
	layer.update_image()

	
	preview_position = position
	preview_color = Color.TRANSPARENT

func on_hover(position: Vector2i) -> void:
	preview_position = position
	# preview_color всегда TRANSPARENT для eraser

func should_draw_preview() -> bool:
	return true
