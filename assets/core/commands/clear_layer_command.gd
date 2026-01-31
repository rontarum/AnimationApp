class_name ClearLayerCommand
extends LayerCommand

## Команда очистки слоя

var cleared_pixels: Dictionary = {}  # Сохраняем все пиксели для восстановления

func _init(target_layer_id: int) -> void:
	super._init(target_layer_id)
	
	var layer_data = _get_layer_data(layer_id)
	var layer_name = layer_data.get("name", "Unknown")
	description = "Clear layer: " + layer_name
	
	# Сохраняем все пиксели слоя перед очисткой
	_save_layer_pixels()

func _save_layer_pixels() -> void:
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if not draw_layer:
		return
	
	# Сохраняем все непрозрачные пиксели
	var image = draw_layer.texture.get_image()
	if not image:
		return
	
	for x in image.get_width():
		for y in image.get_height():
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.0:  # Только непрозрачные пиксели
				cleared_pixels[Vector2i(x, y)] = pixel

func execute() -> void:
	if not _layer_exists(layer_id):
		push_error("[ClearLayerCommand] Layer not found: " + str(layer_id))
		return
	
	# Очищаем слой
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if draw_layer:
		# Очищаем все пиксели
		for pos in cleared_pixels.keys():
			draw_layer.set_pixel(pos, Color.TRANSPARENT)
		# Принудительно обновляем текстуру
		draw_layer.update_image()

func undo() -> void:
	if not _layer_exists(layer_id):
		push_error("[ClearLayerCommand] Layer not found: " + str(layer_id))
		return
	
	# Восстанавливаем сохранённые пиксели
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if draw_layer:
		for pos in cleared_pixels.keys():
			var color = cleared_pixels[pos]
			draw_layer.set_pixel(pos, color)
		# Принудительно обновляем текстуру
		draw_layer.update_image()