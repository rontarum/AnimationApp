class_name ColorService extends Node
## Сервис управления цветами
## Централизованно управляет primary/secondary цветами и их синхронизацией

func _ready() -> void:
	# Регистрация в Services
	Services.register("color", self)

	# Подписка на события изменения цветов
	EventBus.primary_color_changed.connect(_on_primary_color_changed)
	EventBus.secondary_color_changed.connect(_on_secondary_color_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("swap_colors"):
		swap_colors()

func _on_primary_color_changed(new_color: Color) -> void:
	pass
	# Здесь можно добавить дополнительную логику обработки изменения primary цвета

func _on_secondary_color_changed(new_color: Color) -> void:
	pass
	# Здесь можно добавить дополнительную логику обработки изменения secondary цвета

## Получить текущий primary цвет
func get_primary_color() -> Color:
	return AppState.primary_color

## Получить текущий secondary цвет
func get_secondary_color() -> Color:
	return AppState.secondary_color

## Установить primary цвет
func set_primary_color(color: Color) -> void:
	AppState.primary_color = color

## Установить secondary цвет
func set_secondary_color(color: Color) -> void:
	AppState.secondary_color = color

## Поменять местами primary и secondary цвета
func swap_colors() -> void:
	var temp = AppState.primary_color
	AppState.primary_color = AppState.secondary_color
	AppState.secondary_color = temp

## Сбросить цвета к значениям по умолчанию
func reset_colors() -> void:
	AppState.primary_color = Color.BLACK
	AppState.secondary_color = Color.WHITE
