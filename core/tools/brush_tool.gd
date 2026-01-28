class_name BrushTool extends BaseTool

## Инструмент кисти - рисует пиксели выбранным цветом
## 
## Зона ответственности:
## - Установка пикселя в указанной позиции
## - Обновление preview данных для отрисовки

var _temp_position: Vector2i

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		var source: Color = layer.get_pixel(position)
		var blended: Color = _blend_colors(source, color)
		layer.set_pixel(position, blended)
		preview_position = position
		preview_color = color
		
		_temp_position = position

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		var diff: float = abs(_temp_position.length() - position.length())
		if diff < 0.04:
			return
		var source: Color = layer.get_pixel(position)
		var blended: Color = _blend_colors(source, color)
		layer.set_pixel(position, blended)
		preview_position = position
		preview_color = color
		
		_temp_position = position

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	# Brush не требует действий при release
	pass

func on_hover(position: Vector2i) -> void:
	preview_position = position
	# preview_color будет установлен при press/drag

func should_draw_preview() -> bool:
	return true

func _blend_colors(source: Color, color: Color) -> Color:
	var blended: Color = source * (1.0 - color.a) + color * color.a
	blended.a = source.a + color.a
	return blended
