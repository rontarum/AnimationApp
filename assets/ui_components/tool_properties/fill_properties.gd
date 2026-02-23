class_name FillProperties extends ToolProperties

## UI настроек заливки
## Отвечает за синхронизацию своих параметров с ToolService

var is_contiguous: bool = true

func _ready() -> void:
	# Подписываемся на изменения properties
	EventBus.tool_property_changed.connect(_on_tool_property_changed)
	
	# Загружаем текущие значения из ToolService
	var current_contiguous = Services.tool.get_tool_property("contiguous")
	if current_contiguous != null:
		is_contiguous = current_contiguous

func _on_contiguous_property_toggled(toggled_on: bool) -> void:
	if is_contiguous != toggled_on:
		is_contiguous = toggled_on
		Services.tool.set_tool_property("contiguous", is_contiguous)

func _on_tool_property_changed(tool_type: ToolType.Type, property: String, value) -> void:
	# Обновляем UI если изменился наш параметр
	if tool_type == ToolType.Type.FILL and property == "contiguous":
		is_contiguous = value
