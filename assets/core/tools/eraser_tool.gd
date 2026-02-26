class_name EraserTool extends DrawTool

## Инструмент ластика - стирает пиксели (делает прозрачными)
## 
## Зона ответственности:
## - Установка прозрачного пикселя в указанной позиции
## - Обновление preview данных для отрисовки

var _eraser_size: int = 1

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.start_changes()
		_draw_eraser(position, layer)

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		_draw_eraser(position, layer)

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.finish_changes()

func _draw_eraser(position: Vector2i, layer: DrawLayer) -> void:
	var half_size: int = int(floor(_eraser_size / 2.0))
	
	# Стираем квадратную область
	for x in range(-half_size, _eraser_size - half_size):
		for y in range(-half_size, _eraser_size - half_size):
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

func _on_size_changed(new_size: int) -> void:
	_eraser_size = new_size

func connect_to_properties(properties: Resource) -> void:
	if properties.has_signal("size_changed"):
		properties.size_changed.connect(_on_size_changed)
		# Initialize current value
		_eraser_size = properties.get("size")

