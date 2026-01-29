## ToolService - Управление инструментами
##
## Отвечает за выбор инструментов, их состояние и действия.
## Слушает события из EventBus и обновляет AppState.
## Управляет instances инструментов (BaseTool).

class_name ToolService
extends Node

var active_tool: BaseTool = null
var tool_instances: Dictionary = {}  # ToolType.Type -> BaseTool
var tool_properties: Dictionary = {}  # ToolType.Type -> Dictionary

func _ready() -> void:
	Services.register("tool", self)
	
	# Создаем instances инструментов
	tool_instances[ToolType.Type.BRUSH] = BrushTool.new()
	tool_instances[ToolType.Type.ERASER] = EraserTool.new()
	tool_instances[ToolType.Type.FILL] = FillTool.new()
	
	# Инициализируем properties для каждого инструмента
	tool_properties[ToolType.Type.BRUSH] = {"size": 1, "shape": 0}  # 0=square, 1=circle
	tool_properties[ToolType.Type.ERASER] = {"size": 1}
	tool_properties[ToolType.Type.FILL] = {"contiguous": true}
	
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

## Получить property активного инструмента
func get_tool_property(property: String):
	var tool_type = AppState.current_tool
	if tool_properties.has(tool_type) and tool_properties[tool_type].has(property):
		return tool_properties[tool_type][property]
	return null

## Установить property активного инструмента
func set_tool_property(property: String, value) -> void:
	var tool_type = AppState.current_tool
	if tool_properties.has(tool_type):
		tool_properties[tool_type][property] = value
		EventBus.tool_property_changed.emit(tool_type, property, value)

## Изменить размер кисти/ластика
func resize_tool(delta: float) -> void:
	var current_size = get_tool_property("size")
	if current_size != null:
		var new_size = clamp(current_size + delta, 1, 10)
		set_tool_property("size", new_size)

func reset_tool_size() -> void:
	set_tool_property("size", 1)

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
