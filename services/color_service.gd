class_name ColorService extends Node
## Сервис управления цветами
## Централизованно управляет primary/secondary цветами и их синхронизацией

func _ready() -> void:
	print("[ColorService] Initialized")
	
	# Регистрация в Services
	Services.register("color", self)
	
	# Подписка на события изменения цветов
	EventBus.primary_color_changed.connect(_on_primary_color_changed)
	EventBus.secondary_color_changed.connect(_on_secondary_color_changed)
	EventBus.color_picked.connect(_on_color_picked)

func _on_primary_color_changed(new_color: Color) -> void:
	print("[ColorService] Primary color changed to: ", new_color)
	# Здесь можно добавить дополнительную логику обработки изменения primary цвета

func _on_secondary_color_changed(new_color: Color) -> void:
	print("[ColorService] Secondary color changed to: ", new_color)
	# Здесь можно добавить дополнительную логику обработки изменения secondary цвета

func _on_color_picked(color: Color, source: Node) -> void:
	print("[ColorService] Color picked: ", color, " from: ", source.name if source else "unknown")
	# Здесь можно добавить логику обработки выбора цвета

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
