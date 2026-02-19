class_name ProjectData
extends Resource

## ProjectData — данные проекта для сохранения/загрузки
##
## Корневой ресурс, содержащий все данные проекта

@export var name: String = "New Project"
@export var canvas_size: Vector2i = Vector2i(32, 32)
@export var current_tab: int = 0
@export var layers: Array[DrawLayerData] = []


## Создать пустой проект
static func create_empty() -> ProjectData:
	return ProjectData.new()


## Получить имя проекта из пути
static func get_project_name_from_path(path: String) -> String:
	return path.get_file().get_basename()