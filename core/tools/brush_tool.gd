class_name BrushTool extends BaseTool

## Инструмент кисти - рисует пиксели выбранным цветом
## 
## Зона ответственности:
## - Установка пикселя в указанной позиции
## - Обновление preview данных для отрисовки

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.set_pixel(position, color)
		preview_position = position
		preview_color = color

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.set_pixel(position, color)
		preview_position = position
		preview_color = color

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	# Brush не требует действий при release
	pass

func on_hover(position: Vector2i) -> void:
	preview_position = position
	# preview_color будет установлен при press/drag

func should_draw_preview() -> bool:
	return true
