class_name PixelCommand
extends BaseCommand

## Базовая команда для операций с пикселями
## Хранит изменения пикселей в формате: Vector2i -> {old: Color, new: Color}

var layer_id: int
var pixel_changes: Dictionary = {}  # Vector2i -> {old: Color, new: Color}

func _init(target_layer_id: int) -> void:
	super._init()
	layer_id = target_layer_id

## Добавить изменение пикселя
func add_pixel_change(pos: Vector2i, old_color: Color, new_color: Color) -> void:
	pixel_changes[pos] = {
		"old": old_color,
		"new": new_color
	}

## Выполнить команду - применить новые цвета
func execute() -> void:
	_apply_changes("new")

## Отменить команду - восстановить старые цвета
func undo() -> void:
	_apply_changes("old")

## Применить изменения к слою
func _apply_changes(color_key: String) -> void:
	# Получаем DrawLayer через CanvasService
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if not draw_layer:
		print("PixelCommand: DrawLayer not found for layer: ", layer_id)
		return
	
	# Применяем изменения к слою
	for pos in pixel_changes:
		var change = pixel_changes[pos]
		var color = change[color_key]
		draw_layer.set_pixel(pos, color)
	
	# Обновляем текстуру после изменений
	draw_layer.update_image()

## Подсчёт использования памяти
func get_memory_usage() -> int:
	var base_size = super.get_memory_usage()
	# Каждое изменение: Vector2i (8 bytes) + 2 Colors (32 bytes) = 40 bytes
	var changes_size = pixel_changes.size() * 40
	return base_size + changes_size + 8  # +8 для layer_id

## Проверка возможности выполнения
func can_execute() -> bool:
	return Services.canvas.get_draw_layer(layer_id) != null

func can_undo() -> bool:
	return Services.canvas.get_draw_layer(layer_id) != null