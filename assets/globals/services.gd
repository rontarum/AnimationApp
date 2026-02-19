## Services - Service Locator
##
## Централизованный доступ к сервисам приложения.
## Сервисы регистрируются при инициализации и доступны глобально.
##
## Пример использования:
##   Services.tool.select_tool(ToolType.Type.BRUSH)
##   Services.layer.create_layer("New Layer")

extends Node

# === SERVICE REFERENCES ===
var tool: ToolService = null
var layer: LayerService = null
var canvas: CanvasService = null
var color: ColorService = null
var cursor: CursorService = null
var tree: TreeService = null

## Регистрация сервиса
func register(service_name: String, service: Node) -> void:
	match service_name:
		"tool": tool = service
		"layer": layer = service
		"canvas": canvas = service
		"color": color = service
		"cursor": cursor = service
		"tree": tree = service
		_:
			push_error("Unknown service: " + service_name)

## Проверка готовности всех сервисов
func are_all_ready() -> bool:
	return tool != null and layer != null and canvas != null \
	and color != null and cursor != null and tree != null
