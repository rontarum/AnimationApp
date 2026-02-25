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
	
	# Эмитим событие готовности приложения
	EventBus.app_ready.emit()
