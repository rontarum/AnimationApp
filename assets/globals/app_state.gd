## AppState - Реактивное состояние приложения
##
## Централизованное хранилище состояния с автоматическим уведомлением через EventBus.
## Все изменения состояния проходят через сеттеры, которые эмитят соответствующие события.
##
## Пример использования:
##   AppState.current_tool = ToolType.Type.BRUSH  # Автоматически эмитит tool_selected
##   var tool = AppState.current_tool  # Чтение состояния

extends Node

# === GLOBAL ===
var current_tab: int = 0:
	set(val):
		if current_tab != val:
			ProjectManager.auto_save()  # Автосохранение при переключении вкладки
			current_tab = val
			EventBus.tab_changed.emit(current_tab)

# === TOOL STATE ===
var _current_tool: ToolType.Type = ToolType.Type.ARROW
var current_tool: ToolType.Type:
	get: return _current_tool
	set(value):
		if _current_tool != value:
			_current_tool = value
			EventBus.tool_selected.emit(value)

# === LAYER STATE ===
var _active_layer_id: int = -1
var active_layer_id: int:
	get: return _active_layer_id
	set(value):
		if _active_layer_id != value:
			_active_layer_id = value
			EventBus.layer_selected.emit(value)

var _layer_count: int = 0
var layer_count: int:
	get: return _layer_count
	set(value): _layer_count = value

# === COLOR STATE ===
var _primary_color: Color = Color.WHITE
var primary_color: Color:
	get: return _primary_color
	set(value):
		if _primary_color != value:
			_primary_color = value
			EventBus.primary_color_changed.emit(value)

var _secondary_color: Color = Color.BLACK
var secondary_color: Color:
	get: return _secondary_color
	set(value):
		if _secondary_color != value:
			_secondary_color = value
			EventBus.secondary_color_changed.emit(value)

# === CANVAS STATE ===
var _canvas_size: Vector2i = Vector2i(32, 32)
var canvas_size: Vector2i:
	get: return _canvas_size
	set(value):
		if _canvas_size != value:
			_canvas_size = value
			EventBus.canvas_resized.emit(value)

# === CAMERA STATE ===
var _camera_zoom: Vector2 = Vector2.ONE
var camera_zoom: Vector2:
	get: return _camera_zoom
	set(value):
		if _camera_zoom != value:
			_camera_zoom = value
			EventBus.camera_zoom_changed.emit(value)

var _camera_position: Vector2 = Vector2.ZERO
var camera_position: Vector2:
	get: return _camera_position
	set(value):
		if _camera_position != value:
			_camera_position = value
			EventBus.camera_position_changed.emit(value)

# === UI STATE ===
var _focused_element: Node = null
var focused_element: Node:
	get: return _focused_element
	set(value):
		if _focused_element != value:
			_focused_element = value
			EventBus.ui_element_focused.emit(value)

# === FLAGS ===
var is_drawing: bool = false
var is_dragging_camera: bool = false
var is_color_picking: bool = false

func _ready() -> void:
	# Инициализация начальных значений
	_primary_color = Color.WHITE
	_secondary_color = Color.BLACK

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		ProjectManager.auto_save()
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			EventBus.app_closing.emit()
			get_tree().quit()
