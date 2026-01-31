class_name LayerCommand
extends BaseCommand

## Базовый класс для команд работы со слоями
## Содержит общую логику для операций со слоями

var layer_id: int
var layer_service: LayerService

func _init(target_layer_id: int = -1) -> void:
	layer_id = target_layer_id
	layer_service = Services.layer

## Проверка существования слоя
func _layer_exists(id: int) -> bool:
	return layer_service.layers.has(id)

## Получение данных слоя
func _get_layer_data(id: int) -> Dictionary:
	return layer_service.get_layer_data(id)