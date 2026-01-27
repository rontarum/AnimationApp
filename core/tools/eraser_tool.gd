class_name EraserTool extends BaseTool

## Инструмент ластика - стирает пиксели (делает прозрачными)
## 
## Зона ответственности:
## - Установка прозрачного пикселя в указанной позиции
## - Обновление preview данных для отрисовки

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.set_pixel(position, Color.TRANSPARENT)
		preview_position = position
		preview_color = Color.TRANSPARENT

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.set_pixel(position, Color.TRANSPARENT)
		preview_position = position
		preview_color = Color.TRANSPARENT

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	# Eraser не требует действий при release
	pass

func on_hover(position: Vector2i) -> void:
	preview_position = position
	# preview_color всегда TRANSPARENT для eraser

func should_draw_preview() -> bool:
	return true
