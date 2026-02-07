class_name LayersPanel extends Panel

static var instance: LayersPanel

# --- НАСТРОЙКИ ---
@export var LAYER_HEIGHT: float = 64.0 
@export var ANIM_SPEED: float = 36.9

# --- ССЫЛКИ ---
@onready var layer_scene := preload("uid://dphwe1t4okc3j")
@onready var layers_container: Control = $LayersPanelMargin/LayersContainer
@onready var new_layer_button: Button = $NewLayerButton
@onready var delete_layer_button: Button = $DeleteLayerButton
@onready var clear_layer_button: Button = $ClearLayerButton
@onready var all_visible_button: CheckBox = $LayerVisible

# --- СОСТОЯНИЕ ---
var active_layer: Layer = null
var dragged_layer: Layer = null
var drag_offset_y: float = 0.0

# Маппинг layer_id (int) -> Layer UI node
var layer_ui_map: Dictionary = {}

func _init() -> void:
	instance = self

func _ready() -> void:
	new_layer_button.pressed.connect(_on_new_layer_pressed)
	delete_layer_button.pressed.connect(_on_delete_layer_pressed)
	clear_layer_button.pressed.connect(_on_clear_layer_pressed)
	# Подписка на события слоев
	EventBus.layer_created.connect(_on_layer_created)
	EventBus.layer_deleted.connect(_on_layer_deleted)
	EventBus.layer_selected.connect(_on_layer_selected)
	EventBus.layer_reordered.connect(_on_layer_reordered)
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed_sync_all_button)
	

func _input(event: InputEvent) -> void:
	if dragged_layer and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_drag()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# 1. Обновляем размер контейнера для скролла
	var total_height = layers_container.get_child_count() * LAYER_HEIGHT
	layers_container.custom_minimum_size.y = total_height
	layers_container.size.y = max(layers_container.size.y, total_height)

	# 2. Логика перетаскивания
	if dragged_layer:
		var mouse_y = layers_container.get_local_mouse_position().y
		var target_y = mouse_y - drag_offset_y
		var max_y = (layers_container.get_child_count() - 1) * LAYER_HEIGHT
		dragged_layer.position.y = clamp(target_y, -LAYER_HEIGHT/2.0, max_y + LAYER_HEIGHT/2.0)
		_check_reorder()
	
	# 3. Плавная расстановка (Soft Layout)
	for i in layers_container.get_child_count():
		var child = layers_container.get_child(i)
		if child == dragged_layer:
			continue
		var target_pos_y = i * LAYER_HEIGHT
		child.position.y = lerp(child.position.y, target_pos_y, delta * ANIM_SPEED)
		child.position.x = lerp(child.position.x, 0.0, delta * ANIM_SPEED)

# --- ЛОГИКА ПЕРЕСТАНОВКИ ---

func _check_reorder() -> void:
	var current_idx = dragged_layer.get_index()
	var dragging_center = dragged_layer.position.y + (LAYER_HEIGHT / 2.0)
	
	# Проверка соседа сверху
	if current_idx > 0:
		var prev_child = layers_container.get_child(current_idx - 1)
		var prev_center = prev_child.position.y + (LAYER_HEIGHT / 2.0)
		if dragging_center < prev_center:
			var old_index = current_idx
			var new_index = current_idx - 1
			layers_container.move_child(dragged_layer, new_index)
			Services.layer.reorder_layer(old_index, new_index)
			_reorder_draw_layers(old_index, new_index)
			for c in layers_container.get_children():
				c.moved.emit()
			return 

	# Проверка соседа снизу
	if current_idx < layers_container.get_child_count() - 1:
		var next_child = layers_container.get_child(current_idx + 1)
		var next_center = next_child.position.y + (LAYER_HEIGHT / 2.0)
		if dragging_center > next_center:
			var old_index = current_idx
			var new_index = current_idx + 1
			layers_container.move_child(dragged_layer, new_index)
			Services.layer.reorder_layer(old_index, new_index)
			_reorder_draw_layers(old_index, new_index)
			for c in layers_container.get_children():
				c.moved.emit()
			return

func _reorder_draw_layers(from_index: int, to_index: int) -> void:
	var draw_canvas = Services.canvas.draw_canvas
	if not draw_canvas:
		return
	
	if from_index < draw_canvas.get_child_count() and to_index < draw_canvas.get_child_count():
		var draw_layer = draw_canvas.get_child(from_index)
		draw_canvas.move_child(draw_layer, to_index)

# --- ОБРАБОТКА СОБЫТИЙ ---

func _on_layer_created(layer_data: Dictionary) -> void:
	var layer_id = layer_data.get("id", -1)
	var layer_name = layer_data.get("name", "Unknown")
	
	if layer_id == -1:
		push_error("[LayersPanel] Invalid layer_id")
		return
	
	# Создаём UI слой
	var layer_ui = layer_scene.instantiate()
	_connect_layer_signals(layer_ui)
	
	layers_container.add_child(layer_ui, true)
	layer_ui.set_meta("layer_id", layer_id)  # ID в метаданных
	layer_ui.rename(layer_name)  # Имя только для UI
	
	# Инициализируем кнопку видимости
	var layer_service_data = Services.layer.get_layer(layer_id)
	if layer_service_data.has("visible"):
		layer_ui.layer_visible.set_pressed_no_signal(layer_service_data["visible"])
	
	# Регистрируем маппинг
	layer_ui_map[layer_id] = layer_ui
	
	# Визуально в конец
	layer_ui.position.y = layers_container.get_child_count() * LAYER_HEIGHT

func _on_layer_deleted(layer_id: int) -> void:
	var layer_ui = layer_ui_map.get(layer_id)
	if not layer_ui:
		return
	
	var was_active = (active_layer == layer_ui)
	var deleted_index = layer_ui.get_index()
	
	# Удаляем UI
	layer_ui_map.erase(layer_id)
	
	if active_layer == layer_ui:
		active_layer = null
	
	# Выбираем следующий слой ДО удаления ноды
	if was_active and layers_container.get_child_count() > 1:
		# Выбираем слой на том же индексе или предыдущий
		var next_index = deleted_index
		if next_index >= layers_container.get_child_count() - 1:
			next_index = layers_container.get_child_count() - 2
		
		var next_layer_ui = layers_container.get_child(next_index)
		if next_layer_ui == layer_ui:
			# Если это тот же слой, берём следующий
			next_index = deleted_index + 1
			if next_index >= layers_container.get_child_count():
				next_index = deleted_index - 1
			next_layer_ui = layers_container.get_child(next_index)
		
		var next_layer_id = next_layer_ui.get_meta("layer_id", -1)
		if next_layer_id != -1:
			EventBus.layer_selected.emit(next_layer_id)
	
	# Теперь удаляем ноду
	layer_ui.queue_free()

func _on_layer_selected(layer_id: int) -> void:
	# Обработка пустого состояния (нет слоёв)
	if layer_id == -1:
		if active_layer and is_instance_valid(active_layer):
			active_layer.set_active(false)
		active_layer = null
		return
	
	var layer_ui = layer_ui_map.get(layer_id)
	if layer_ui:
		_set_active_layer(layer_ui)
	else:
		pass

func _on_layer_reordered(from_index: int, to_index: int) -> void:
	pass




# --- ОБРАБОТКА СИГНАЛОВ ОТ LAYER UI ---

func _connect_layer_signals(layer: Layer) -> void:
	if not layer.clicked.is_connected(_on_layer_clicked):
		layer.clicked.connect(_on_layer_clicked)
	if not layer.drag_started.is_connected(_on_layer_drag_started):
		layer.drag_started.connect(_on_layer_drag_started)
	if not layer.drag_ended.is_connected(_on_layer_drag_ended):
		layer.drag_ended.connect(_on_layer_drag_ended)

func _on_layer_clicked(layer: Layer) -> void:
	# Правильная архитектура: UI эмитит событие
	var layer_id = layer.get_meta("layer_id", -1)
	if layer_id != -1:
		EventBus.layer_selected.emit(layer_id)

func _on_layer_drag_started(layer: Layer, _mouse_pos: Vector2) -> void:
	if Services.cursor:
		Services.cursor.hide_cursor()
	dragged_layer = layer
	drag_offset_y = layers_container.get_local_mouse_position().y - layer.position.y
	dragged_layer.z_index = 10
	
	# Правильная архитектура: UI эмитит событие
	var layer_id = layer.get_meta("layer_id", -1)
	if layer_id != -1:
		EventBus.layer_selected.emit(layer_id)

func _on_layer_drag_ended(_layer: Layer) -> void:
	_finish_drag()

func _finish_drag() -> void:
	if Services.cursor:
		Services.cursor.show_cursor()
	if not dragged_layer: return
	dragged_layer.z_index = 0
	dragged_layer = null

# --- УПРАВЛЕНИЕ СЛОЯМИ (КНОПКИ) ---

func _on_new_layer_pressed() -> void:
	var layer_name = "Layer" + str(layers_container.get_child_count() + 1)
	# Правильная архитектура: UI эмитит событие
	EventBus.layer_create_requested.emit(layer_name)

func _on_delete_layer_pressed() -> void:
	if not active_layer or not is_instance_valid(active_layer):
		return
	
	var layer_id = active_layer.get_meta("layer_id", -1)
	if layer_id == -1:
		return
	
	# Правильная архитектура: UI эмитит событие
	EventBus.layer_delete_requested.emit(layer_id)

func _on_clear_layer_pressed() -> void:
	if not active_layer or not is_instance_valid(active_layer):
		return
	
	var layer_id = active_layer.get_meta("layer_id", -1)
	if layer_id == -1:
		return
	
	EventBus.layer_clear_requested.emit(layer_id)

func _set_active_layer(layer: Layer) -> void:
	if active_layer == layer: return
	
	if active_layer and is_instance_valid(active_layer):
		active_layer.set_active(false)
	
	active_layer = layer
	if active_layer:
		active_layer.set_active(true)


func _on_all_visible_toggled(toggled_on: bool) -> void:
	EventBus.layer_all_visibility_requested.emit(toggled_on)

func _on_layer_visibility_changed_sync_all_button(_layer_id: int, _visible: bool) -> void:
	# Синхронизируем состояние общей кнопки видимости
	# Проверяем, все ли слои видимы
	var all_visible = true
	for layer_id in layer_ui_map.keys():
		var layer_data = Services.layer.get_layer(layer_id)
		if not layer_data.get("visible", true):
			all_visible = false
			break
	
	all_visible_button.set_pressed_no_signal(all_visible)
