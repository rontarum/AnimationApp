extends Node

## ProjectManager — управление сохранением и загрузкой проектов
##
## Координатор для операций save/load. Работает с CanvasService, LayerService.
## Поддерживает автосохранение при переключении вкладок и по таймеру.

# Сигналы
signal project_saved(path: String)
signal project_loaded(path: String)
signal project_closed
signal auto_save_triggered
signal auto_save_completed
signal auto_save_failed(error: String)

# Состояние
var current_project_path: String = ""
var _auto_save_timer: Timer = null
var _save_in_progress: bool = false

# Настройки автосохранения
const AUTO_SAVE_INTERVAL: float = 60.0  # секунды


func _ready() -> void:
	_setup_auto_save_timer()


# === PUBLIC API ===

## Сохранить проект в указанный файл
func save_project(path: String) -> bool:
	if _save_in_progress:
		push_warning("[ProjectManager] Save already in progress")
		return false
	
	_save_in_progress = true
	
	var success: bool = false
	var error_msg: String = ""
	
	# Сбор данных
	var project_data := _collect_project_data()
	
	# Сохранение
	var err = ResourceSaver.save(project_data, path)
	if err == OK:
		current_project_path = path
		success = true
		project_saved.emit(path)
		print("[ProjectManager] Project saved: ", path)
	else:
		error_msg = "Failed to save: error " + str(err)
		push_error("[ProjectManager] " + error_msg)
		auto_save_failed.emit(error_msg)
	
	_save_in_progress = false
	return success


## Загрузить проект из файла
func load_project(path: String) -> bool:
	if _save_in_progress:
		push_warning("[ProjectManager] Save in progress, cannot load")
		return false
	
	var err = ResourceLoader.load(path)
	if err == null or not (err is ProjectData):
		push_error("[ProjectManager] Failed to load project: ", path)
		return false
	
	var project_data: ProjectData = err as ProjectData
	
	# Восстановление данных
	_restore_project_data(project_data)
	
	current_project_path = path
	project_loaded.emit(path)
	print("[ProjectManager] Project loaded: ", path)
	return true


## Создать новый проект
func new_project(size: Vector2i) -> void:
	# Очистка (без undo/redo для нового проекта)
	Services.canvas.clear_canvas()
	Services.layer.hard_clear_layers()
	
	# Установка размера холста
	AppState.canvas_size = size
	
	# Сброс пути
	current_project_path = ""
	
	project_closed.emit()
	print("[ProjectManager] New project created: ", size)


## Выполнить автосохранение
func auto_save() -> bool:
	if current_project_path == "":
		return false  # Некуда сохранять
	
	auto_save_triggered.emit()
	var success = save_project(current_project_path)
	if success:
		auto_save_completed.emit()
	return success


## Проверить наличие несохранённых изменений
func has_unsaved_changes() -> bool:
	return current_project_path != ""


# === INTERNAL ===

func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(_auto_save_timer)


func _on_auto_save_timer_timeout() -> void:
	if current_project_path != "":
		auto_save()


func _collect_project_data() -> ProjectData:
	var data := ProjectData.new()
	
	data.name = ProjectData.get_project_name_from_path(current_project_path) if current_project_path else "New Project"
	data.canvas_size = AppState.canvas_size
	data.current_tab = AppState.current_tab
	
	# Сбор слоёв
	var layer_service := Services.layer
	var canvas_service := Services.canvas
	
	var layers_data: Array[DrawLayerData] = []
	var all_layers: Array[Dictionary] = layer_service.get_all_layers()
	var all_images: Dictionary = canvas_service.get_all_layer_images()
	
	for layer_dict: Dictionary in all_layers:
		var layer_id: int = layer_dict.get("id", 0)
		var img_data: PackedByteArray = all_images.get(layer_id, PackedByteArray())
		layers_data.append(DrawLayerData.from_dict(layer_dict, img_data))
	
	data.layers = layers_data
	return data


func _restore_project_data(data: ProjectData) -> void:
	# Очистка текущего состояния
	Services.canvas.clear_canvas()
	Services.layer.clear_layers()
	
	# Восстановление размера холста
	AppState.canvas_size = data.canvas_size
	
	# Восстановление слоёв
	var layer_service := Services.layer
	var canvas_service := Services.canvas
	
	for layer_data: DrawLayerData in data.layers:
		var layer_dict: Dictionary = layer_data.to_dict()
		var layer_id: int = layer_data.layer_id
		
		# Создаём слой в LayerService (напрямую, без create_layer чтобы избежать дублей)
		layer_service.layers[layer_id] = layer_dict.duplicate()
		
		# Обновляем счётчик ID
		if layer_id >= layer_service._next_layer_id:
			layer_service._next_layer_id = layer_id + 1
		
		# Создаём DrawLayer в CanvasService напрямую
		var draw_layer = DrawLayer.new(data.canvas_size, layer_id)
		canvas_service.draw_canvas.add_child(draw_layer)
		draw_layer.name = "DrawLayer" + str(layer_id)
		canvas_service.draw_layers[layer_id] = draw_layer
		
		# Восстанавливаем изображение
		if layer_data.image_data.size() > 0:
			draw_layer.image.set_data(data.canvas_size.x, data.canvas_size.y, false, Image.FORMAT_RGBA8, layer_data.image_data)
			draw_layer.tex.update(draw_layer.image)
		
		# Восстанавливаем видимость DrawLayer
		draw_layer.visible = layer_data.visible
		
		# Эмитим событие создания слоя для UI (без создания DrawLayer в CanvasService)
		EventBus.layer_created.emit({
			"id": layer_id,
			"name": layer_data.name
		})
		
		# Эмитим событие обновления изображения для UI превью (ПОСЛЕ создания UI слоя)
		if layer_data.image_data.size() > 0:
			EventBus.layer_image_updated.emit(layer_id, draw_layer.image)
	
	# Обновляем состояние
	AppState.layer_count = layer_service.layers.size()
	
	# Восстановление вкладки
	AppState.current_tab = data.current_tab
