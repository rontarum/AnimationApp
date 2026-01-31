class_name SelectLayerCommand
extends LayerCommand

## Команда выбора активного слоя

var previous_layer_id: int
var new_layer_id: int
var _executed: bool = false

func _init(target_layer_id: int) -> void:
	super._init(target_layer_id)
	new_layer_id = target_layer_id
	# НЕ сохраняем previous_layer_id здесь - сохраним при выполнении
	
	var layer_name = "Unknown"
	if target_layer_id != -1:
		var layer_data = _get_layer_data(target_layer_id)
		layer_name = layer_data.get("name", "Unknown")
	
	description = "Select layer: " + layer_name

func execute() -> void:
	# Сохраняем предыдущий слой только при первом выполнении
	if not _executed:
		previous_layer_id = AppState.active_layer_id
		_executed = true
	
	# Выбираем новый слой (всегда выполняем, даже если тот же)
	layer_service.select_layer(new_layer_id)

func undo() -> void:
	# Возвращаем предыдущий активный слой (всегда выполняем)
	layer_service.select_layer(previous_layer_id)