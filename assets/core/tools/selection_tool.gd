class_name SelectionTool extends BaseTool

## Инструмент выделения - выделяет прямоугольные области и перемещает их содержимое
## 
## Состояния:
## - IDLE: нет выделения
## - SELECTING: процесс выделения (drag)
## - SELECTED: область выделена, можно перемещать
## - MOVING: перемещение выделенной области

enum State {
	IDLE,
	SELECTING, 
	SELECTED,
	MOVING
}

var current_state: State = State.IDLE
var selection_start: Vector2i
var selection_end: Vector2i
var selection_rect: Rect2i
var selected_pixels: Dictionary = {}  # Vector2i -> Color (относительные координаты)
var move_offset: Vector2i
var original_position: Vector2i  # Исходная позиция выделения

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	match current_state:
		State.IDLE:
			_start_selection(position)
		State.SELECTED:
			if _is_inside_selection(position):
				_start_moving(position, layer)
			else:
				_clear_selection()
				_start_selection(position)

func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	match current_state:
		State.SELECTING:
			_update_selection(position)
		State.MOVING:
			_update_moving(position, layer)

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	match current_state:
		State.SELECTING:
			_finish_selection(layer)
		State.MOVING:
			_finish_moving(layer)

func on_hover(position: Vector2i) -> void:
	preview_position = position

func on_mouse_exit(layer: DrawLayer) -> void:
	match current_state:
		State.SELECTING:
			_finish_selection(layer)
		State.MOVING:
			_finish_moving(layer)

func should_draw_preview() -> bool:
	return false  # Selection рисует свой gizmo в canvas_renderer

## Начинаем выделение
func _start_selection(position: Vector2i) -> void:
	current_state = State.SELECTING
	selection_start = position
	selection_end = position
	_update_selection_rect()
	
	# Скрываем курсор во время выделения
	if Services.cursor:
		Services.cursor.hide_cursor()

## Обновляем область выделения
func _update_selection(position: Vector2i) -> void:
	selection_end = position
	_update_selection_rect()

## Завершаем выделение и сохраняем пиксели
func _finish_selection(layer: DrawLayer) -> void:
	if selection_rect.size.x < 1 or selection_rect.size.y < 1:
		# Слишком маленькое выделение - отменяем
		current_state = State.IDLE
		if Services.cursor:
			Services.cursor.show_cursor()
		return
	
	# Сохраняем выделенные пиксели с ОТНОСИТЕЛЬНЫМИ координатами
	selected_pixels.clear()
	for x in range(selection_rect.size.x):
		for y in range(selection_rect.size.y):
			var absolute_pos = selection_rect.position + Vector2i(x, y)
			var relative_pos = Vector2i(x, y)
			selected_pixels[relative_pos] = layer.get_pixel(absolute_pos)
	
	current_state = State.SELECTED
	# Показываем курсор после выделения
	if Services.cursor:
		Services.cursor.show_cursor()

## Начинаем перемещение
func _start_moving(position: Vector2i, layer: DrawLayer) -> void:
	current_state = State.MOVING
	move_offset = position - selection_rect.position
	original_position = selection_rect.position
	
	# Очищаем только непрозрачные пиксели выделения
	# Прозрачные пиксели не трогаем - под ними могут быть другие пиксели
	_clear_area_selective(layer, original_position)
	layer.update_image()

## Обновляем перемещение
func _update_moving(position: Vector2i, layer: DrawLayer) -> void:
	var new_pos = position - move_offset
	
	# Обновляем только позицию выделения
	# НЕ модифицируем слой - пиксели будут отрисованы через overlay
	selection_rect.position = new_pos

## Завершаем перемещение
func _finish_moving(layer: DrawLayer) -> void:
	# Рисуем пиксели в финальной позиции
	_draw_selection(layer, selection_rect.position)
	layer.update_image()
	
	# Пересохраняем пиксели из новой позиции для следующего перемещения
	var canvas_size = layer.get_image_size()
	var new_pixels: Dictionary = {}
	
	for x in range(selection_rect.size.x):
		for y in range(selection_rect.size.y):
			var absolute_pos = selection_rect.position + Vector2i(x, y)
			var relative_pos = Vector2i(x, y)
			
			# Проверяем границы холста
			if absolute_pos.x >= 0 and absolute_pos.y >= 0 and absolute_pos.x < canvas_size.x and absolute_pos.y < canvas_size.y:
				new_pixels[relative_pos] = layer.get_pixel(absolute_pos)
			else:
				# За границами холста - прозрачный пиксель
				new_pixels[relative_pos] = Color.TRANSPARENT
	
	selected_pixels = new_pixels
	current_state = State.SELECTED

## Очищаем выделение
func _clear_selection() -> void:
	current_state = State.IDLE
	selected_pixels.clear()
	selection_rect = Rect2i()

## Проверяем, находится ли точка внутри выделения
func _is_inside_selection(position: Vector2i) -> bool:
	return selection_rect.has_point(position)

## Обновляем прямоугольник выделения
func _update_selection_rect() -> void:
	var min_x = min(selection_start.x, selection_end.x)
	var min_y = min(selection_start.y, selection_end.y)
	var max_x = max(selection_start.x, selection_end.x)
	var max_y = max(selection_start.y, selection_end.y)
	
	selection_rect = Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

## Очищаем область выделения на слое
func _clear_selected_area(layer: DrawLayer) -> void:
	for x in range(selection_rect.position.x, selection_rect.position.x + selection_rect.size.x):
		for y in range(selection_rect.position.y, selection_rect.position.y + selection_rect.size.y):
			var pos = Vector2i(x, y)
			layer.set_pixel(pos, Color.TRANSPARENT)

## Очищаем область по заданной позиции
func _clear_area(layer: DrawLayer, offset: Vector2i) -> void:
	var canvas_size = layer.get_image_size()
	
	for relative_pos in selected_pixels:
		var pos = offset + relative_pos
		
		# Проверяем границы холста
		if pos.x >= 0 and pos.y >= 0 and pos.x < canvas_size.x and pos.y < canvas_size.y:
			layer.set_pixel(pos, Color.TRANSPARENT)

## Очищаем только непрозрачные пиксели выделения
func _clear_area_selective(layer: DrawLayer, offset: Vector2i) -> void:
	var canvas_size = layer.get_image_size()
	
	for relative_pos in selected_pixels:
		var color = selected_pixels[relative_pos]
		
		# Очищаем только непрозрачные пиксели
		if color.a == 0.0:
			continue
		
		var pos = offset + relative_pos
		
		# Проверяем границы холста
		if pos.x >= 0 and pos.y >= 0 and pos.x < canvas_size.x and pos.y < canvas_size.y:
			layer.set_pixel(pos, Color.TRANSPARENT)

## Рисуем выделение по заданной позиции
func _draw_selection(layer: DrawLayer, offset: Vector2i) -> void:
	var canvas_size = layer.get_image_size()
	
	for relative_pos in selected_pixels:
		var color = selected_pixels[relative_pos]
		
		# Пропускаем прозрачные пиксели - не перезаписываем то, что под ними
		if color.a == 0.0:
			continue
		
		var pos = offset + relative_pos
		
		# Проверяем границы холста
		if pos.x >= 0 and pos.y >= 0 and pos.x < canvas_size.x and pos.y < canvas_size.y:
			layer.set_pixel(pos, color)

## Получить текущее состояние для отрисовки gizmo
func get_selection_rect() -> Rect2i:
	return selection_rect

func get_current_state() -> State:
	return current_state

## Получить пиксели выделения для отрисовки overlay
func get_selected_pixels() -> Dictionary:
	return selected_pixels

## Обработка экшена deselect
func deselect() -> void:
	_clear_selection()
	if Services.cursor:
		Services.cursor.show_cursor()
