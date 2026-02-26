class_name FillProperties extends ToolProperties

## UI настроек заливки
## Отвечает за синхронизацию своих параметров с FillProps Resource

var is_contiguous: bool = true
var fill_props: FillProps

func _ready() -> void:
	# Получаем FillProps Resource из ToolService
	fill_props = Services.tool.get_draw_property(ToolType.Type.FILL) as FillProps
	
	if fill_props:
		# Загружаем текущие значения
		is_contiguous = fill_props.contiguous
		
		# Подписываемся на изменения через Resource signals
		fill_props.contiguous_changed.connect(_on_contiguous_changed_from_resource)

func _on_contiguous_property_toggled(toggled_on: bool) -> void:
	if is_contiguous != toggled_on and fill_props:
		is_contiguous = toggled_on
		fill_props.contiguous = is_contiguous

func _on_contiguous_changed_from_resource(new_contiguous: bool) -> void:
	# Обновляем UI если изменился параметр извне
	if is_contiguous != new_contiguous:
		is_contiguous = new_contiguous
