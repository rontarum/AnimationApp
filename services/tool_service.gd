## ToolService - Управление инструментами
##
## Отвечает за выбор инструментов, их состояние и действия.
## Слушает события из EventBus и обновляет AppState.

class_name ToolService
extends Node

func _ready() -> void:
	Services.register("tool", self)
	
	# Подписка на события
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.tool_action_started.connect(_on_tool_action_started)
	EventBus.tool_action_updated.connect(_on_tool_action_updated)
	EventBus.tool_action_finished.connect(_on_tool_action_finished)

## Выбор инструмента
func select_tool(tool_type: int) -> void:
	AppState.current_tool = tool_type

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

func _on_tool_selected(tool_type: int) -> void:
	print("[ToolService] Tool selected: ", Util.ToolType.keys()[tool_type])

func _on_tool_action_started(position: Vector2) -> void:
	pass  # Логика обработки начала действия

func _on_tool_action_updated(position: Vector2) -> void:
	pass  # Логика обработки обновления действия

func _on_tool_action_finished(position: Vector2) -> void:
	pass  # Логика обработки завершения действия
