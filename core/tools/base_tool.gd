class_name BaseTool extends RefCounted

## Базовый класс для всех инструментов рисования
## Определяет единый интерфейс для взаимодействия с canvas
## 
## Инструменты - это чистая логика (RefCounted), без зависимостей от Node.
## Они получают данные (position, layer, color) и выполняют действия.

# Данные для preview overlay
var preview_position: Vector2i = Vector2i(-1, -1)
var preview_color: Color = Color.TRANSPARENT

## Вызывается при нажатии кнопки мыши на canvas
func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	pass

## Вызывается при движении мыши с зажатой кнопкой
func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	pass

## Вызывается при отпускании кнопки мыши
func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	pass

## Вызывается при движении мыши над canvas (для preview)
func on_hover(position: Vector2i) -> void:
	preview_position = position

## Вызывается при изменении размера инструмента. Знак +-
func on_resize(position: Vector2i, sign: float = -1.0) -> void:
	pass

## Возвращает нужно ли рисовать preview для этого инструмента
func should_draw_preview() -> bool:
	return false
