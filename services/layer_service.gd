## LayerService - Управление слоями
##
## Отвечает за создание, удаление, переименование и переупорядочивание слоёв.
## Хранит данные о слоях и синхронизирует их с UI.

class_name LayerService
extends Node

# Данные слоёв (id -> LayerData)
var layers: Dictionary = {}
var next_layer_id: int = 0

func _ready() -> void:
	Services.register("layer", self)
	
	# Подписка на события
	EventBus.layer_created.connect(_on_layer_created)
	EventBus.layer_deleted.connect(_on_layer_deleted)
	EventBus.layer_selected.connect(_on_layer_selected)
	EventBus.layer_reordered.connect(_on_layer_reordered)
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed)
	EventBus.layer_renamed.connect(_on_layer_renamed)

## Создание нового слоя
func create_layer(layer_name: String = "") -> int:
	var layer_id = next_layer_id
	next_layer_id += 1
	
	var name = layer_name if layer_name != "" else "Layer " + str(layer_id)
	
	layers[layer_id] = {
		"id": layer_id,
		"name": name,
		"visible": true,
		"index": layers.size()
	}
	
	AppState.layer_count = layers.size()
	EventBus.layer_created.emit(layer_id)
	
	# Автоматически выбираем новый слой
	select_layer(layer_id)
	
	return layer_id

## Удаление слоя
func delete_layer(layer_id: int) -> void:
	if not layers.has(layer_id):
		push_error("Layer not found: " + str(layer_id))
		return
	
	layers.erase(layer_id)
	AppState.layer_count = layers.size()
	EventBus.layer_deleted.emit(layer_id)
	
	# Если удалили активный слой, выбираем другой
	if AppState.active_layer_id == layer_id:
		if layers.size() > 0:
			select_layer(layers.keys()[0])
		else:
			AppState.active_layer_id = -1

## Выбор активного слоя
func select_layer(layer_id: int) -> void:
	if not layers.has(layer_id):
		push_error("Layer not found: " + str(layer_id))
		return
	
	AppState.active_layer_id = layer_id

## Переименование слоя
func rename_layer(layer_id: int, new_name: String) -> void:
	if not layers.has(layer_id):
		push_error("Layer not found: " + str(layer_id))
		return
	
	layers[layer_id]["name"] = new_name
	EventBus.layer_renamed.emit(layer_id, new_name)

## Изменение видимости слоя
func set_layer_visibility(layer_id: int, visible: bool) -> void:
	if not layers.has(layer_id):
		push_error("Layer not found: " + str(layer_id))
		return
	
	layers[layer_id]["visible"] = visible
	EventBus.layer_visibility_changed.emit(layer_id, visible)

## Изменение порядка слоёв
func reorder_layer(from_index: int, to_index: int) -> void:
	EventBus.layer_reordered.emit(from_index, to_index)

## Получение данных слоя
func get_layer(layer_id: int) -> Dictionary:
	return layers.get(layer_id, {})

## Получение активного слоя
func get_active_layer() -> Dictionary:
	return get_layer(AppState.active_layer_id)

# === ОБРАБОТЧИКИ СОБЫТИЙ ===

func _on_layer_created(layer_id: int) -> void:
	print("[LayerService] Layer created: ", layer_id)

func _on_layer_deleted(layer_id: int) -> void:
	print("[LayerService] Layer deleted: ", layer_id)

func _on_layer_selected(layer_id: int) -> void:
	print("[LayerService] Layer selected: ", layer_id)

func _on_layer_reordered(from_index: int, to_index: int) -> void:
	print("[LayerService] Layer reordered: ", from_index, " -> ", to_index)

func _on_layer_visibility_changed(layer_id: int, visible: bool) -> void:
	print("[LayerService] Layer visibility changed: ", layer_id, " = ", visible)

func _on_layer_renamed(layer_id: int, new_name: String) -> void:
	print("[LayerService] Layer renamed: ", layer_id, " = ", new_name)
