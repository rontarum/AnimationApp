class_name BrushProperties extends ToolProperties

## UI настроек кисти
## Отвечает за синхронизацию своих параметров с BrushProps Resource

var shape: int = 0  # 0=square, 1=circle
var brush_props: BrushProps

func _ready() -> void:
	# Получаем BrushProps Resource из ToolService
	brush_props = Services.tool.get_draw_property(ToolType.Type.BRUSH) as BrushProps
	
	if brush_props:
		# Загружаем текущие значения
		shape = brush_props.shape
		_update_ui()
		
		# Подписываемся на изменения через Resource signals
		brush_props.shape_changed.connect(_on_shape_changed_from_resource)

func _update_ui() -> void:
	# Обновляем CheckButton (должен быть подключен в сцене)
	# Если есть CheckButton в сцене, обновляем его состояние
	pass

func _on_check_button_toggled(toggled_on: bool) -> void:
	var new_shape = 1 if toggled_on else 0
	if shape != new_shape and brush_props:
		shape = new_shape
		brush_props.shape = shape

func _on_shape_changed_from_resource(new_shape: int) -> void:
	# Обновляем UI если изменился параметр извне
	if shape != new_shape:
		shape = new_shape
		_update_ui()
