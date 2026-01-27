class_name CursorSprite extends Sprite2D

## Визуальный спрайт курсора, следующий за мышью
## Зона ответственности: только отображение, никакой логики

func _ready() -> void:
	# Скрываем системный курсор
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	scale = Vector2(0.5, 0.5)
	offset = Vector2(16.0, 24.0)

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()

## Устанавливает текстуру курсора
func set_cursor_texture(new_texture: Resource) -> void:
	texture = new_texture

## Показывает курсор
func show_cursor() -> void:
	show()

## Скрывает курсор
func hide_cursor() -> void:
	hide()
