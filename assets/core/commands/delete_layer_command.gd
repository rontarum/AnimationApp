class_name DeleteLayerCommand
extends LayerCommand

## Команда удаления слоя

var deleted_layer_data: Dictionary
var deleted_layer_pixels: Dictionary = {}  # Сохраняем пиксели слоя
var previous_active_layer_id: int = -1
var new_active_layer_id: int = -1

func _init(target_layer_id: int) -> void:
	super._init(target_layer_id)
	
	# Сохраняем данные слоя перед удалением
	deleted_layer_data = _get_layer_data(layer_id).duplicate(true)
	description = "Delete layer: " + deleted_layer_data.get("name", "Unknown")
	
	# Сохраняем пиксели слоя
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
				deleted_layer_pixels[Vector2i(x, y)] = pixel

func execute() -> void:
	print("[DeleteLayerCommand] Execute: ", description)
	
	if not _layer_exists(layer_id):
		push_error("[DeleteLayerCommand] Layer to delete not found: " + str(layer_id))
		return
	
	# Сохраняем состояние активного слоя
	previous_active_layer_id = AppState.active_layer_id
	
	# Удаляем слой через сервис
	layer_service.delete_layer(layer_id)
	
	# Запоминаем новый активный слой после удаления
	new_active_layer_id = AppState.active_layer_id

func undo() -> void:
	print("[DeleteLayerCommand] Undo: ", description)
	
	# Восстанавливаем слой
	var restored_id = layer_service.create_layer(deleted_layer_data.get("name", "Restored"))
	
	# Восстанавливаем видимость
	var was_visible = deleted_layer_data.get("visible", true)
	layer_service.set_layer_visibility(restored_id, was_visible)
	
	# Восстанавливаем пиксели
	_restore_layer_pixels(restored_id)
	
	# Восстанавливаем активный слой
	if previous_active_layer_id == layer_id:
		layer_service.select_layer(restored_id)
	else:
		layer_service.select_layer(previous_active_layer_id)
	
	# Обновляем ID для возможных повторных операций
	layer_id = restored_id

func _restore_layer_pixels(target_layer_id: int) -> void:
	var draw_layer = Services.canvas.get_draw_layer(target_layer_id)
	if not draw_layer:
		return
	
	# Восстанавливаем сохранённые пиксели
	for pos in deleted_layer_pixels:
		var color = deleted_layer_pixels[pos]
		draw_layer.set_pixel(pos, color)