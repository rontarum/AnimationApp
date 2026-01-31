class_name AllLayersVisibilityCommand
extends LayerCommand

## Команда для изменения видимости всех слоёв одновременно

var new_visibility: bool
var previous_states: Dictionary = {}  # layer_id -> previous_visibility

func _init(visible: bool) -> void:
	super._init(-1)  # Не привязана к конкретному слою
	new_visibility = visible
	
	# Сохраняем текущие состояния всех слоёв
	for layer_id in layer_service.layers.keys():
		var layer_data = layer_service.get_layer_data(layer_id)
		previous_states[layer_id] = layer_data.get("visible", true)
	
	var action = "Show" if visible else "Hide"
	description = action + " all layers (" + str(previous_states.size()) + " layers)"

func execute() -> void:
	# Изменяем видимость всех слоёв
	for layer_id in previous_states.keys():
		if _layer_exists(layer_id):
			layer_service.set_layer_visibility(layer_id, new_visibility)
	
	# Обновляем UI кнопку
	_update_all_visible_button()

func undo() -> void:
	# Восстанавливаем предыдущие состояния
	for layer_id in previous_states.keys():
		if _layer_exists(layer_id):
			var previous_visibility = previous_states[layer_id]
			layer_service.set_layer_visibility(layer_id, previous_visibility)
	
	# Обновляем UI кнопку
	_update_all_visible_button()

func _update_all_visible_button() -> void:
	# Определяем состояние кнопки на основе ВСЕХ текущих слоёв
	var all_visible = true
	for layer_id in layer_service.layers.keys():
		if _layer_exists(layer_id):
			var layer_data = layer_service.get_layer_data(layer_id)
			if not layer_data.get("visible", true):
				all_visible = false
				break
	
	# Обновляем кнопку через LayersPanel
	if LayersPanel.instance and LayersPanel.instance.all_visible_button:
		LayersPanel.instance.all_visible_button.set_pressed_no_signal(all_visible)