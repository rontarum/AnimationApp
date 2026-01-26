class_name LayersPanel extends Panel

signal active_layer_changed(layer: Layer) 

static var instance: LayersPanel

# --- НАСТРОЙКИ ---
# Высота слоя. Должна совпадать с реальной высотой сцены Layer в пикселях.
# Если между слоями нужен отступ, добавь его сюда (например, высота 60 + отступ 4 = 64)
@export var LAYER_HEIGHT: float = 64.0 
@export var ANIM_SPEED: float = 36.9   # Скорость сглаживания движения

# --- ССЫЛКИ ---
@onready var layer_scene := preload("uid://dphwe1t4okc3j")
# Ссылка на контейнер, который теперь должен быть CONTROL (не VBoxContainer!)
@onready var layers_container: Control = $MarginContainer/LayersContainer
@onready var new_layer_button: Button = $NewLayerButton
@onready var delete_layer_button: Button = $DeleteLayerButton

# --- СОСТОЯНИЕ ---
var active_layer: Layer = null
var dragged_layer: Layer = null
var drag_offset_y: float = 0.0

func _init() -> void:
	instance = self

func _ready() -> void:
	new_layer_button.pressed.connect(_on_new_layer_pressed)
	delete_layer_button.pressed.connect(_on_delete_layer_pressed)
	
	# Если слои уже есть в сцене при запуске
	for child in layers_container.get_children():
		if child is Layer:
			_connect_layer_signals(child)

func _input(event: InputEvent) -> void:
	# Глобальная страховка: если отпустили мышь где угодно, завершаем перетаскивание.
	# Класс Layer обрабатывает отпускание внутри себя, но если мышь ушла за пределы слоя,
	# Layer это пропустит. Панель подстрахует.
	if dragged_layer and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_drag()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# 1. Обновляем размер контейнера для скролла
	# Так как это не VBox, ScrollContainer не знает размер контента. Сообщаем ему вручную.
	var total_height = layers_container.get_child_count() * LAYER_HEIGHT
	layers_container.custom_minimum_size.y = total_height
	layers_container.size.y = max(layers_container.size.y, total_height)

	# 2. Логика перетаскивания
	if dragged_layer:
		var mouse_y = layers_container.get_local_mouse_position().y
		
		# Двигаем слой за мышкой (с ограничением, чтобы не улетел в бесконечность)
		var target_y = mouse_y - drag_offset_y
		var max_y = (layers_container.get_child_count() - 1) * LAYER_HEIGHT
		dragged_layer.position.y = clamp(target_y, -LAYER_HEIGHT/2.0, max_y + LAYER_HEIGHT/2.0)
		
		# Проверяем перестановку (меняем индексы)
		_check_reorder()
	
	# 3. Основная магия: Плавная расстановка (Soft Layout)
	for i in layers_container.get_child_count():
		var child = layers_container.get_child(i)
		
		# Если слой перетаскивается прямо сейчас — не трогаем его позицию (ей управляет мышь выше)
		if child == dragged_layer:
			continue
			
		# Где слой ДОЛЖЕН быть по математике
		var target_pos_y = i * LAYER_HEIGHT
		
		# Плавно тянем слой к его законному месту (lerp)
		# position.x фиксируем в 0, position.y интерполируем
		child.position.y = lerp(child.position.y, target_pos_y, delta * ANIM_SPEED)
		child.position.x = lerp(child.position.x, 0.0, delta * ANIM_SPEED)

# --- ЛОГИКА ПЕРЕСТАНОВКИ ---

func _check_reorder() -> void:
	var current_idx = dragged_layer.get_index()
	var dragging_center = dragged_layer.position.y + (LAYER_HEIGHT / 2.0)
	
	# Проверка соседа сверху
	if current_idx > 0:
		var prev_child = layers_container.get_child(current_idx - 1)
		# Сравниваем центры. Если центр перетаскиваемого выше центра предыдущего -> меняем
		var prev_center = prev_child.position.y + (LAYER_HEIGHT / 2.0)
		if dragging_center < prev_center:
			layers_container.move_child(dragged_layer, current_idx - 1)
			for c in layers_container.get_children():
				c.moved.emit()
			return 

	# Проверка соседа снизу
	if current_idx < layers_container.get_child_count() - 1:
		var next_child = layers_container.get_child(current_idx + 1)
		var next_center = next_child.position.y + (LAYER_HEIGHT / 2.0)
		if dragging_center > next_center:
			layers_container.move_child(dragged_layer, current_idx + 1)
			for c in layers_container.get_children():
				c.moved.emit()
			return

# --- ОБРАБОТКА СИГНАЛОВ ОТ LAYER ---

func _connect_layer_signals(layer: Layer) -> void:
	if not layer.clicked.is_connected(_on_layer_clicked):
		layer.clicked.connect(_on_layer_clicked)
	if not layer.drag_started.is_connected(_on_layer_drag_started):
		layer.drag_started.connect(_on_layer_drag_started)
	if not layer.drag_ended.is_connected(_on_layer_drag_ended) :
		layer.drag_ended.connect(_on_layer_drag_ended)

func _on_layer_clicked(layer: Layer) -> void:
	_set_active_layer(layer)

func _on_layer_drag_started(layer: Layer, _mouse_pos: Vector2) -> void:
	CursorSprite.instance.hide()
	# _mouse_pos приходит глобальный, переведем в локальный для удобства
	dragged_layer = layer
	drag_offset_y = layers_container.get_local_mouse_position().y - layer.position.y
	
	# Поднимаем визуально над всеми
	dragged_layer.z_index = 10 
	_set_active_layer(layer) # Перетаскивание также делает слой активным

# Вызывается сигналом от слоя ИЛИ глобальным отпусканием мыши
func _on_layer_drag_ended(_layer: Layer) -> void:
	_finish_drag()

func _finish_drag() -> void:
	CursorSprite.instance.show()
	if not dragged_layer: return
	
	# Возвращаем z-index
	dragged_layer.z_index = 0
	
	# Просто сбрасываем переменную.
	# В следующем кадре _process увидит, что dragged_layer == null,
	# и блок "3. Soft Layout" плавно притянет слой на его место в списке.
	dragged_layer = null

# --- УПРАВЛЕНИЕ СЛОЯМИ (КНОПКИ) ---

func _on_new_layer_pressed() -> void:
	var layer = layer_scene.instantiate()
	_connect_layer_signals(layer)
	
	layers_container.add_child(layer, true)
	
	# Назовем красиво
	var layer_name := "Layer" + str(layer.get_index())
	layer.rename(layer_name)
	
	
	# Ставим его визуально в конец сразу, чтобы он "выплыл" снизу, а не прилетел сверху
	layer.position.y = layers_container.get_child_count() * LAYER_HEIGHT
	
	DrawContainer.instance.create_draw_layer(layer)
	
	# Делаем активным
	_set_active_layer(layer)


func _on_delete_layer_pressed() -> void:
	if not active_layer or not is_instance_valid(active_layer):
		return
	
	var index = active_layer.get_index()
	active_layer.queue_free()
	active_layer = null
	
	# Ждем кадр, чтобы обновился список детей
	await get_tree().process_frame
	
	# Пытаемся выбрать соседний
	var count = layers_container.get_child_count()
	if count > 0:
		index = clamp(index - 1, 0, count - 1)
		_set_active_layer(layers_container.get_child(index))

func _set_active_layer(layer: Layer) -> void:
	if active_layer == layer: return
	
	# Снимаем активность со старого
	if active_layer and is_instance_valid(active_layer):
		active_layer.set_active(false)
	
	active_layer = layer
	if active_layer:
		active_layer.set_active(true)
	
	active_layer_changed.emit(active_layer)
