class_name BrushCommand
extends PixelCommand

## Команда для операций кисти
## Рисует пиксели указанным цветом

var brush_color: Color
var positions: Array[Vector2i] = []
var _already_executed: bool = false  # Флаг для отличия первого выполнения от redo

func _init(target_layer_id: int, color: Color, brush_positions: Array[Vector2i] = []) -> void:
	super._init(target_layer_id)
	brush_color = color
	positions = brush_positions.duplicate()
	description = "Brush: " + str(positions.size()) + " pixels"
	
	# Сразу подготавливаем изменения пикселей
	_prepare_pixel_changes()

## Подготовить изменения пикселей
func _prepare_pixel_changes() -> void:
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if not draw_layer:
		return
	
	# Сохраняем старые цвета и подготавливаем блендинг
	for pos in positions:
		var old_color = draw_layer.get_pixel(pos)
		var blended_color = _blend_colors(old_color, brush_color)
		add_pixel_change(pos, old_color, blended_color)

## Добавить позицию для рисования (вызывается ДО изменения пикселя)
func add_position_before_draw(pos: Vector2i) -> void:
	if pos in positions:
		return  # Не добавляем дубликаты
	
	positions.append(pos)
	
	# Получаем старый цвет ДО изменения и вычисляем блендинг
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if draw_layer:
		var old_color = draw_layer.get_pixel(pos)
		var blended_color = _blend_colors(old_color, brush_color)
		add_pixel_change(pos, old_color, blended_color)
	
	# Обновляем описание
	description = "Brush: " + str(positions.size()) + " pixels"

## Добавить позицию для рисования (старый метод, оставляем для совместимости)
func add_position(pos: Vector2i) -> void:
	add_position_before_draw(pos)

## Блендинг цветов (как в BrushTool)
func _blend_colors(source: Color, color: Color) -> Color:
	var blended: Color = source * (1.0 - color.a) + color * color.a
	blended.a = source.a + color.a
	return blended

## Переопределяем execute() - для redo нужно применить новые цвета
func execute() -> void:
	print("[BrushCommand] Execute called for: ", description, " Already executed: ", _already_executed)
	
	# При первом выполнении пиксели уже нарисованы в BrushTool
	if not _already_executed:
		_already_executed = true
		return
	
	# При redo применяем новые цвета
	_apply_changes("new")

## Переопределяем undo() - восстанавливаем старые цвета
func undo() -> void:
	print("[BrushCommand] Undo called for: ", description)
	_apply_changes("old")