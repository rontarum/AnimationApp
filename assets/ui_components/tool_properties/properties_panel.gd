class_name PropertiesPanel extends Panel

## Панель настроек инструментов
## Отвечает ТОЛЬКО за загрузку/выгрузку UI настроек при смене инструмента
## Логика синхронизации - в конкретных UI компонентах (BrushProperties, FillProperties)

@onready var properties_panel_margin: MarginContainer = $PropertiesPanelMargin

# Маппинг инструментов к их UI сценам
var tool_ui_scenes: Dictionary = {
	ToolType.Type.BRUSH: preload("res://assets/ui_components/tool_properties/brush_properties.tscn"),
	ToolType.Type.FILL: preload("res://assets/ui_components/tool_properties/fill_properties.tscn"),
	ToolType.Type.MESH: preload("uid://dxjdp4scr0pec")
}

var current_properties_ui: ToolProperties = null

func _ready() -> void:
	EventBus.tool_selected.connect(_on_tool_selected)
	
	# Загружаем UI для текущего инструмента
	_load_tool_ui(AppState.current_tool)

func _on_tool_selected(tool_type: ToolType.Type) -> void:
	_load_tool_ui(tool_type)

func _load_tool_ui(tool_type: ToolType.Type) -> void:
	# Удаляем предыдущий UI
	if current_properties_ui:
		current_properties_ui.queue_free()
		current_properties_ui = null
	
	# Загружаем новый UI если есть
	if tool_ui_scenes.has(tool_type):
		var scene = tool_ui_scenes[tool_type]
		current_properties_ui = scene.instantiate()
		properties_panel_margin.add_child(current_properties_ui)
