## LayerService - Управление слоями
##
## Отвечает за создание, удаление, переименование и переупорядочивание слоёв.
## Хранит данные о слоях и синхронизирует их с UI.
##
## ВАЖНО: Вся логика работает через уникальные int ID, имена - только UI labels

class_name LayerService
extends Node

# Данные слоёв (id: int -> LayerData: Dictionary)
var layers: Dictionary = {}

# Счётчик для генерации уникальных ID
var _next_layer_id: int = 0

# Пул освободившихся ID для переиспользования
var _freed_ids: Array[int] = []

func _ready() -> void:
	Services.register("layer", self)
	
	# Подписка на события
	EventBus.layer_created.connect(_on_layer_created)
	EventBus.layer_deleted.connect(_on_layer_deleted)
	EventBus.layer_selected.connect(_on_layer_selected)
	EventBus.layer_reordered.connect(_on_layer_reordered)
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed)
	EventBus.layer_renamed.connect(_on_layer_renamed)
	EventBus.layer_rename_requested.connect(_on_layer_rename_requested)
	EventBus.layer_create_requested.connect(_on_layer_create_requested)
	EventBus.layer_delete_requested.connect(_on_layer_delete_requested)
	EventBus.layer_visibility_requested.connect(_on_layer_visibility_requested)

## Создание нового слоя
func create_layer(layer_name: String) -> int:
	# Переиспользуем освободившийся ID или создаём новый
	var layer_id: int
	if _freed_ids.size() > 0:
		layer_id = _freed_ids.pop_front()
	else:
		layer_id = _next_layer_id
		_next_layer_id += 1
	
	# Храним только ID, имя и видимость - БЕЗ индексов
	layers[layer_id] = {
		"id": layer_id,
		"name": layer_name,
		"visible": true
	}
	
	AppState.layer_count = layers.size()
	EventBus.layer_created.emit({
		"id": layer_id,
		"name": layer_name
	})
	
	# Автоматически выбираем новый слой
	select_layer(layer_id)
	
	return layer_id

## Удаление слоя
func delete_layer(layer_id: int) -> void:
	if not layers.has(layer_id):
		push_error("[LayerService] Layer not found: " + str(layer_id))
		return
	
	var was_active = (AppState.active_layer_id == layer_id)
	
	layers.erase(layer_id)
	
	# Добавляем ID в пул для переиспользования
	_freed_ids.append(layer_id)
	_freed_ids.sort()
	
	AppState.layer_count = layers.size()
	EventBus.layer_deleted.emit(layer_id)
	
	# Если удалили активный слой - UI сам выберет следующий
	# Здесь только сбрасываем состояние если слоёв не осталось
	if was_active and layers.size() == 0:
		AppState.active_layer_id = -1

## Выбор активного слоя
func select_layer(layer_id: int) -> void:
	# Разрешаем -1 для сброса активного слоя (пустое состояние)
	if layer_id == -1:
		AppState.active_layer_id = -1
		return
	
	if not layers.has(layer_id):
		push_error("[LayerService] Layer not found: " + str(layer_id))
		return
	
	AppState.active_layer_id = layer_id

## Переименование слоя
func rename_layer(layer_id: int, new_name: String) -> void:
	if not layers.has(layer_id):
		push_error("[LayerService] Layer not found: " + str(layer_id))
		return
	
	var old_name = layers[layer_id]["name"]
	layers[layer_id]["name"] = new_name
	
	EventBus.layer_renamed.emit(layer_id, old_name, new_name)

## Изменение видимости слоя
func set_layer_visibility(layer_id: int, visible: bool) -> void:
	if not layers.has(layer_id):
		push_error("[LayerService] Layer not found: " + str(layer_id))
		return
	
	layers[layer_id]["visible"] = visible
	EventBus.layer_visibility_changed.emit(layer_id, visible)

## Изменение порядка слоёв
func reorder_layer(from_index: int, to_index: int) -> void:
	# LayerService не управляет порядком - это ответственность UI
	# Просто эмитим событие для логирования
	EventBus.layer_reordered.emit(from_index, to_index)

## Получение данных слоя по ID
func get_layer(layer_id: int) -> Dictionary:
	return layers.get(layer_id, {})

## Получение активного слоя
func get_active_layer() -> Dictionary:
	return get_layer(AppState.active_layer_id)

# === ОБРАБОТЧИКИ СОБЫТИЙ ===

func _on_layer_created(layer_data: Dictionary) -> void:
	var layer_id = layer_data.get("id", -1)
	var layer_name = layer_data.get("name", "Unknown")

func _on_layer_deleted(layer_id: int) -> void:
	pass

func _on_layer_selected(layer_id: int) -> void:
	if layer_id == -1:
		pass
	else:
		pass

func _on_layer_reordered(from_index: int, to_index: int) -> void:
	pass

func _on_layer_visibility_changed(layer_id: int, visible: bool) -> void:
	pass

func _on_layer_renamed(layer_id: int, old_name: String, new_name: String) -> void:
	pass

func _on_layer_rename_requested(layer_id: int, new_name: String) -> void:
	# UI запросил переименование - выполняем через сервис
	rename_layer(layer_id, new_name)

func _on_layer_create_requested(layer_name: String) -> void:
	# UI запросил создание - выполняем через сервис
	create_layer(layer_name)

func _on_layer_delete_requested(layer_id: int) -> void:
	# UI запросил удаление - выполняем через сервис
	delete_layer(layer_id)

func _on_layer_visibility_requested(layer_id: int, visible: bool) -> void:
	set_layer_visibility(layer_id, visible)
