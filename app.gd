class_name App
extends Node2D

# Preload классов
const CanvasRendererScene = preload("res://assets/canvas_renderer.gd")

# Сервисы инициализируются как дочерние ноды
@onready var tool_service: ToolService = $Services/ToolService
@onready var layer_service: LayerService = $Services/LayerService
@onready var canvas_service: CanvasService = $Services/CanvasService
@onready var color_service = $Services/ColorService
@onready var cursor_service = $Services/CursorService

func _ready() -> void:
	# Инициализация canvas_service с DrawCanvas
	var draw_canvas = $DrawContainer/DrawCanvas
	Services.canvas.initialize(draw_canvas)
	
	# Добавляем CanvasRenderer как child DrawContainer
	var draw_container = $DrawContainer
	var canvas_renderer = CanvasRendererScene.new()
	canvas_renderer.name = "CanvasRenderer"
	draw_container.add_child(canvas_renderer)
	print("[App] CanvasRenderer added to DrawContainer")
	
	# Эмитим событие готовности приложения
	EventBus.app_ready.emit()
	
	print("[App] Application ready")
	print("[App] Services initialized: ", Services.are_all_ready())

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			EventBus.app_closing.emit()
			get_tree().quit()
