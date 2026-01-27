class_name App
extends Node2D

# Сервисы инициализируются как дочерние ноды
@onready var tool_service: ToolService = $Services/ToolService
@onready var layer_service: LayerService = $Services/LayerService
@onready var canvas_service: CanvasService = $Services/CanvasService

func _ready() -> void:
	# Инициализация canvas_service с DrawCanvas
	var draw_canvas = $DrawContainer/DrawCanvas
	canvas_service.initialize(draw_canvas)
	
	# Эмитим событие готовности приложения
	EventBus.app_ready.emit()
	
	print("[App] Application ready")
	print("[App] Services initialized: ", Services.are_all_ready())

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			EventBus.app_closing.emit()
			get_tree().quit()
