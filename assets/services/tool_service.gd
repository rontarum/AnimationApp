## ToolService - Управление инструментами
##
## Отвечает за выбор инструментов, их состояние и действия.
## Слушает события из EventBus и обновляет AppState.
## Управляет instances инструментов (BaseTool).

class_name ToolService
extends Node

# Preload tool классов
const BrushToolClass = preload("res://core/tools/brush_tool.gd")
const EraserToolClass = preload("res://core/tools/eraser_tool.gd")

var active_tool: BaseTool = null
var tool_instances: Dictionary = {}  # ToolType.Type -> BaseTool

func _ready() -> void:
	Services.register("tool", self)
	
	# Создаем instances инструментов
	tool_instances[ToolType.Type.BRUSH] = BrushToolClass.new()
	tool_instances[ToolType.Type.ERASER] = EraserToolClass.new()
	
	# Подписка на события
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.tool_action_started.connect(_on_tool_action_started)
	EventBus.tool_action_updated.connect(_on_tool_action_updated)
	EventBus.tool_action_finished.connect(_on_tool_action_finished)
	
	# Устанавливаем начальный инструмент
	active_tool = tool_instances.get(AppState.current_tool)
	print("[ToolService] Initialized with ", tool_instances.size(), " tools")

## Выбор инструмента
func select_tool(tool_type: ToolType.Type) -> void:
	AppState.current_tool = tool_type

## Возвращает активный инструмент
func get_active_tool() -> BaseTool:
	return active_tool

## Начало действия инструмента
func start_action(position: Vector2) -> void:
	AppState.is_drawing = true
	EventBus.tool_action_started.emit(position)

## Обновление действия инструмента
func update_action(position: Vector2) -> void:
	if AppState.is_drawing:
		EventBus.tool_action_updated.emit(position)

## Завершение действия инструмента
func finish_action(position: Vector2) -> void:
	AppState.is_drawing = false
	EventBus.tool_action_finished.emit(position)

# === ОБРАБОТЧИКИ СОБЫТИЙ ===

func _on_tool_selected(tool_type: ToolType.Type) -> void:
	print("[ToolService] Tool selected: ", ToolType.Type.keys()[tool_type])
	
	# Переключаем активный инструмент
	active_tool = tool_instances.get(tool_type)
	if not active_tool:
		push_warning("[ToolService] No tool instance for: ", ToolType.Type.keys()[tool_type])

func _on_tool_action_started(position: Vector2) -> void:
	pass  # Логика обработки начала действия

func _on_tool_action_updated(position: Vector2) -> void:
	pass  # Логика обработки обновления действия

func _on_tool_action_finished(position: Vector2) -> void:
	pass  # Логика обработки завершения действия
