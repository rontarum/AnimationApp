class_name EraseCommand
extends PixelCommand

## Команда для операций ластика
## Стирает пиксели (делает их прозрачными)

var positions: Array[Vector2i] = []

func _init(target_layer_id: int, erase_positions: Array[Vector2i] = []) -> void:
	super._init(target_layer_id)
	positions = erase_positions.duplicate()
	description = "Erase: " + str(positions.size()) + " pixels"
	
	# Сразу подготавливаем изменения пикселей
	_prepare_pixel_changes()

## Подготовить изменения пикселей
func _prepare_pixel_changes() -> void:
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if not draw_layer:
		return
	
	# Сохраняем старые цвета и подготавливаем прозрачные
	for pos in positions:
		var old_color = draw_layer.get_pixel(pos)
		add_pixel_change(pos, old_color, Color.TRANSPARENT)

## Добавить позицию для стирания
func add_position(pos: Vector2i) -> void:
	if pos in positions:
		return  # Не добавляем дубликаты
	
	positions.append(pos)
	
	# Получаем старый цвет и добавляем изменение
	var layer_data = Services.layer.get_layer_data(layer_id)
	if layer_data:
		var draw_layer = layer_data.get("draw_layer")
		if draw_layer:
			var old_color = draw_layer.get_pixel(pos.x, pos.y)
			add_pixel_change(pos, old_color, Color.TRANSPARENT)
	
	# Обновляем описание
	description = "Erase: " + str(positions.size()) + " pixels"