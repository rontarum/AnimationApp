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
var tool: ToolService = null  # ToolService
var layer: LayerService = null  # LayerService
var canvas: CanvasService = null  # CanvasService
var color: ColorService = null  # ColorService
var cursor: CursorService = null  # CursorService
var undo_redo: Node = null  # UndoRedoService
var history: Node = null  # HistoryService
var clipboard: Node = null  # ClipboardService

func _ready() -> void:
	# Сервисы будут зарегистрированы при их создании
	pass

## Регистрация сервиса
func register(service_name: String, service: Node) -> void:
	match service_name:
		"tool": tool = service
		"layer": layer = service
		"canvas": canvas = service
		"color": color = service
		"cursor": cursor = service
		"undo_redo": undo_redo = service
		"history": history = service
		"clipboard": clipboard = service
		_:
			push_error("Unknown service: " + service_name)

## Проверка готовности всех сервисов
func are_all_ready() -> bool:
	return tool != null and layer != null and canvas != null and color != null and cursor != null
