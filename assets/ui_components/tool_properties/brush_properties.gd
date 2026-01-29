class_name BrushProperties extends ToolProperties

## UI настроек кисти
## Отвечает за синхронизацию своих параметров с ToolService

var shape: int = 0  # 0=square, 1=circle

func _ready() -> void:
	# Подписываемся на изменения properties
	EventBus.tool_property_changed.connect(_on_tool_property_changed)
	
	# Загружаем текущие значения из ToolService
	var current_shape = Services.tool.get_tool_property("shape")
	if current_shape != null:
		shape = current_shape
		_update_ui()

func _update_ui() -> void:
	# Обновляем CheckButton (должен быть подключен в сцене)
	# Если есть CheckButton в сцене, обновляем его состояние
	pass

func _on_check_button_toggled(toggled_on: bool) -> void:
	var new_shape = 1 if toggled_on else 0
	if shape != new_shape:
		shape = new_shape
		Services.tool.set_tool_property("shape", shape)

func _on_tool_property_changed(tool_type: ToolType.Type, property: String, value) -> void:
	# Обновляем UI если изменился наш параметр
	if tool_type == ToolType.Type.BRUSH and property == "shape":
		shape = value
		_update_ui()
