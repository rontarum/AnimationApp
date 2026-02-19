class_name DrawLayerData
extends Resource

## DrawLayerData — данные слоя для сохранения/загрузки проекта
##
## Хранит метаданные слоя и его изображение в сериализованном виде

@export var layer_id: int = 0
@export var name: String = "Layer"
@export var visible: bool = true
@export var image_data: PackedByteArray = PackedByteArray()


## Создать из Dictionary (данные из LayerService)
static func from_dict(data: Dictionary, img_data: PackedByteArray) -> DrawLayerData:
	var res = DrawLayerData.new()
	res.layer_id = data.get("id", 0)
	res.name = data.get("name", "Layer")
	res.visible = data.get("visible", true)
	res.image_data = img_data
	return res


## Конвертировать в Dictionary (для LayerService)
func to_dict() -> Dictionary:
	return {
		"id": layer_id,
		"name": name,
		"visible": visible
	}