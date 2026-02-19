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
	EventBus.layer_all_visibility_requested.connect(_on_layer_all_visibility_requested)

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

func get_layer_name(layer_id: int) -> String:
	return layers[layer_id]["name"]

## Получение активного слоя
func get_active_layer() -> Dictionary:
	return get_layer(AppState.active_layer_id)

## Получение всех слоёв (для сохранения)
func get_all_layers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for layer_id: int in layers.keys():
		result.append(layers[layer_id].duplicate())
	return result

## Очистка всех слоёв (для нового проекта - без undo/redo)
func clear_layers() -> void:
	layers.clear()
	_next_layer_id = 0
	_freed_ids.clear()
	AppState.layer_count = 0
	AppState.active_layer_id = -1
	EventBus.canvas_cleared.emit()

## Полная очистка слоёв для нового проекта (без undo/redo)
func hard_clear_layers() -> void:
	# Очищаем без создания undo/redo действий
	layers.clear()
	_next_layer_id = 0
	_freed_ids.clear()
	AppState.layer_count = 0
	AppState.active_layer_id = -1
	EventBus.canvas_cleared.emit()

## Восстановление слоёв из сохранённых данных
func restore_layers(layers_data: Array[Dictionary]) -> void:
	clear_layers()
	for layer_data: Dictionary in layers_data:
		var layer_id: int = layer_data.get("id", 0)
		var layer_name: String = layer_data.get("name", "Layer")
		var visible: bool = layer_data.get("visible", true)
		
		layers[layer_id] = {
			"id": layer_id,
			"name": layer_name,
			"visible": visible
		}
		
		# Обновляем счётчик ID
		if layer_id >= _next_layer_id:
			_next_layer_id = layer_id + 1
	
	AppState.layer_count = layers.size()

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
	# UI запросил создание - выполняем через сервис с undo/redo
	create_layer_with_undo(layer_name)

## Создание слоя с поддержкой undo/redo
func create_layer_with_undo(layer_name: String) -> void:
	var layer_id: int
	if _freed_ids.size() > 0:
		layer_id = _freed_ids[0]  # Peek, не pop
	else:
		layer_id = _next_layer_id
	
	History.undo_redo.create_action("Create Layer")
	History.undo_redo.add_do_method(Callable(self, "_do_create_layer").bind(layer_name, layer_id))
	History.undo_redo.add_undo_method(Callable(self, "_undo_create_layer").bind(layer_id))
	History.undo_redo.commit_action()

func _do_create_layer(layer_name: String, layer_id: int) -> void:
	# Переиспользуем освободившийся ID или создаём новый
	if _freed_ids.has(layer_id):
		_freed_ids.erase(layer_id)
	else:
		_next_layer_id = layer_id + 1
	
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
	
	select_layer(layer_id)

func _undo_create_layer(layer_id: int) -> void:
	if not layers.has(layer_id):
		return
	
	var was_active = (AppState.active_layer_id == layer_id)
	
	layers.erase(layer_id)
	_freed_ids.append(layer_id)
	_freed_ids.sort()
	
	AppState.layer_count = layers.size()
	EventBus.layer_deleted.emit(layer_id)
	
	if was_active and layers.size() == 0:
		AppState.active_layer_id = -1

func _on_layer_delete_requested(layer_id: int) -> void:
	# UI запросил удаление - выполняем через сервис с undo/redo
	delete_layer_with_undo(layer_id)

## Удаление слоя с поддержкой undo/redo
func delete_layer_with_undo(layer_id: int) -> void:
	if not layers.has(layer_id):
		push_error("[LayerService] Layer not found: " + str(layer_id))
		return
	
	var layer_data = layers[layer_id].duplicate()
	var was_active = (AppState.active_layer_id == layer_id)
	
	# Сохраняем изображение слоя
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	var image_data: PackedByteArray = PackedByteArray()
	if draw_layer and draw_layer.image:
		image_data = draw_layer.image.get_data()
	
	History.undo_redo.create_action("Delete Layer")
	History.undo_redo.add_do_method(Callable(self, "_do_delete_layer").bind(layer_id))
	History.undo_redo.add_undo_method(Callable(self, "_undo_delete_layer").bind(layer_id, layer_data, was_active, image_data))
	History.undo_redo.commit_action()

func _do_delete_layer(layer_id: int) -> void:
	if not layers.has(layer_id):
		return
	
	var was_active = (AppState.active_layer_id == layer_id)
	
	layers.erase(layer_id)
	_freed_ids.append(layer_id)
	_freed_ids.sort()
	
	AppState.layer_count = layers.size()
	EventBus.layer_deleted.emit(layer_id)
	
	if was_active and layers.size() == 0:
		AppState.active_layer_id = -1

func _undo_delete_layer(layer_id: int, layer_data: Dictionary, was_active: bool, image_data: PackedByteArray) -> void:
	# Восстанавливаем слой
	if _freed_ids.has(layer_id):
		_freed_ids.erase(layer_id)
	
	layers[layer_id] = layer_data
	
	AppState.layer_count = layers.size()
	EventBus.layer_created.emit({
		"id": layer_id,
		"name": layer_data["name"]
	})
	
	# Восстанавливаем изображение слоя
	if image_data.size() > 0:
		await get_tree().process_frame  # Ждём создания DrawLayer
		var draw_layer = Services.canvas.get_draw_layer(layer_id)
		if draw_layer and draw_layer.image:
			var img_size = draw_layer.image.get_size()
			draw_layer.image.set_data(img_size.x, img_size.y, false, Image.FORMAT_RGBA8, image_data)
			draw_layer.update_image()
	
	# Восстанавливаем видимость
	if not layer_data.get("visible", true):
		EventBus.layer_visibility_changed.emit(layer_id, false)
	
	if was_active:
		select_layer(layer_id)

func _on_layer_visibility_requested(layer_id: int, visible: bool) -> void:
	set_layer_visibility_with_undo(layer_id, visible)

## Изменение видимости всех слоёв с поддержкой undo/redo
func set_all_layers_visibility_with_undo(visible: bool) -> void:
	if layers.size() == 0:
		return
	
	# Собираем старые состояния
	var old_states: Dictionary = {}
	for layer_id in layers.keys():
		old_states[layer_id] = layers[layer_id]["visible"]
	
	History.undo_redo.create_action("Toggle All Layers Visibility")
	History.undo_redo.add_do_method(Callable(self, "_do_set_all_layers_visibility").bind(visible))
	History.undo_redo.add_undo_method(Callable(self, "_do_restore_all_layers_visibility").bind(old_states))
	History.undo_redo.commit_action()

func _do_set_all_layers_visibility(visible: bool) -> void:
	for layer_id in layers.keys():
		layers[layer_id]["visible"] = visible
		EventBus.layer_visibility_changed.emit(layer_id, visible)
	EventBus.layer_all_visibility_changed.emit(visible)

func _do_restore_all_layers_visibility(old_states: Dictionary) -> void:
	for layer_id in old_states.keys():
		if layers.has(layer_id):
			var visible = old_states[layer_id]
			layers[layer_id]["visible"] = visible
			EventBus.layer_visibility_changed.emit(layer_id, visible)
	
	# Определяем общее состояние для UI кнопки
	var all_visible = true
	for layer_id in layers.keys():
		if not layers[layer_id]["visible"]:
			all_visible = false
			break
	EventBus.layer_all_visibility_changed.emit(all_visible)

## Изменение видимости слоя с поддержкой undo/redo
func set_layer_visibility_with_undo(layer_id: int, visible: bool) -> void:
	if not layers.has(layer_id):
		push_error("[LayerService] Layer not found: " + str(layer_id))
		return
	
	var old_visible = layers[layer_id]["visible"]
	if old_visible == visible:
		return  # Нет изменений
	
	History.undo_redo.create_action("Toggle Layer Visibility")
	History.undo_redo.add_do_method(Callable(self, "_do_set_layer_visibility").bind(layer_id, visible))
	History.undo_redo.add_undo_method(Callable(self, "_do_set_layer_visibility").bind(layer_id, old_visible))
	History.undo_redo.commit_action()

func _do_set_layer_visibility(layer_id: int, visible: bool) -> void:
	if not layers.has(layer_id):
		return
	
	layers[layer_id]["visible"] = visible
	EventBus.layer_visibility_changed.emit(layer_id, visible)

func _on_layer_all_visibility_requested(visible: bool) -> void:
	set_all_layers_visibility_with_undo(visible)
