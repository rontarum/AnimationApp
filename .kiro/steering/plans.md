### Планы новой архитектуры, разработанные несколькими разработчиками.

## План 1: .Веб-паттерны.

Прежде чем перейти к структуре, зафиксируем принципы:
Проблема сейчасРешениеСинглтоны вездеDependency Injection + Event BusЛогика размазанаЧёткое разделение на слоиТрудно добавить инструментStrategy/Command паттерныГлобальное состояниеЦентрализованный State ManagerПрямые связи компонентовКоммуникация через сигналы

Архитектура слоёв
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION                           │
│  (UI панели, кнопки, визуальные компоненты)                │
│  Только отображение + отправка событий пользователя        │
└─────────────────────────────────────────────────────────────┘
                              ↕ сигналы
┌─────────────────────────────────────────────────────────────┐
│                      APPLICATION                            │
│  (Координаторы, обработчики команд)                        │
│  Оркестрация, но не бизнес-логика                          │
└─────────────────────────────────────────────────────────────┘
                              ↕ вызовы
┌─────────────────────────────────────────────────────────────┐
│                        DOMAIN                               │
│  (Инструменты, операции над холстом, слои)                 │
│  Чистая логика, не знает про UI                            │
└─────────────────────────────────────────────────────────────┘
                              ↕ вызовы
┌─────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE                          │
│  (Event Bus, State Store, сериализация)                    │
│  Технические сервисы                                       │
└─────────────────────────────────────────────────────────────┘


Структура папок
res://
├── autoload/                    # Только истинно глобальные сервисы
│   ├── event_bus.gd            # Шина событий
│   ├── app_state.gd            # Централизованное состояние
│   └── service_locator.gd      # Регистрация сервисов
│
├── core/                        # Domain слой - чистая логика
│   ├── canvas/
│   │   ├── canvas_data.gd      # Resource: данные холста
│   │   ├── canvas_operations.gd # Операции над пикселями
│   │   └── canvas_renderer.gd  # Рендеринг холста
│   │
│   ├── layers/
│   │   ├── layer_data.gd       # Resource: данные слоя
│   │   ├── layer_stack.gd      # Управление стеком слоёв
│   │   └── layer_operations.gd # Операции над слоями
│   │
│   ├── tools/
│   │   ├── tool_base.gd        # Базовый класс инструмента
│   │   ├── brush_tool.gd
│   │   ├── eraser_tool.gd
│   │   ├── fill_tool.gd
│   │   ├── selection_tool.gd
│   │   └── tool_registry.gd    # Реестр инструментов
│   │
│   ├── commands/
│   │   ├── command_base.gd     # Базовый класс команды
│   │   ├── draw_command.gd
│   │   ├── fill_command.gd
│   │   └── command_history.gd  # Undo/Redo
│   │
│   └── selection/
│       ├── selection_data.gd
│       └── selection_operations.gd
│
├── application/                 # Application слой - координация
│   ├── tool_controller.gd      # Управление инструментами
│   ├── canvas_controller.gd    # Координация холста
│   ├── layer_controller.gd     # Координация слоёв
│   └── input_handler.gd        # Обработка ввода
│
├── presentation/                # UI слой
│   ├── panels/
│   │   ├── tool_panel/
│   │   │   ├── tool_panel.tscn
│   │   │   ├── tool_panel.gd
│   │   │   └── tool_button.gd
│   │   ├── layers_panel/
│   │   ├── color_panel/
│   │   └── properties_panel/
│   │
│   ├── canvas/
│   │   ├── canvas_view.tscn
│   │   ├── canvas_view.gd
│   │   └── canvas_camera.gd
│   │
│   ├── cursor/
│   │   ├── cursor_manager.gd
│   │   └── cursor_renderer.gd
│   │
│   └── dialogs/
│
├── resources/                   # Определения ресурсов
│   ├── tool_definition.gd      # Resource: описание инструмента
│   └── project_data.gd         # Resource: данные проекта
│
└── scenes/
    └── app.tscn                # Главная сцена


Ключевые компоненты
1. Event Bus (Шина событий)
Заменяет прямые связи между компонентами. Единственный "легитимный" синглтон.
gdscriptDownloadCopy code# autoload/event_bus.gd
extends Node

# ===== Инструменты =====
signal tool_selected(tool_id: StringName)
signal tool_settings_changed(tool_id: StringName, settings: Dictionary)

# ===== Холст =====
signal canvas_created(size: Vector2i)
signal canvas_modified(region: Rect2i)
signal stroke_started(position: Vector2i)
signal stroke_updated(position: Vector2i)
signal stroke_ended()

# ===== Слои =====
signal layer_added(layer_id: int)
signal layer_removed(layer_id: int)
signal layer_selected(layer_id: int)
signal layer_visibility_changed(layer_id: int, visible: bool)
signal layer_order_changed(old_index: int, new_index: int)

# ===== Выделение =====
signal selection_started(position: Vector2i)
signal selection_updated(rect: Rect2i)
signal selection_completed(rect: Rect2i)
signal selection_cleared()

# ===== Цвет =====
signal primary_color_changed(color: Color)
signal secondary_color_changed(color: Color)

# ===== История =====
signal command_executed(command_name: String)
signal undo_requested()
signal redo_requested()

# ===== Курсор =====
signal cursor_position_changed(canvas_pos: Vector2i, screen_pos: Vector2)
signal cursor_icon_requested(icon_name: StringName)
2. App State (Централизованное состояние)
Вместо распределённого состояния по синглтонам:
gdscriptDownloadCopy code# autoload/app_state.gd
extends Node

# Реактивные свойства с сигналами при изменении
var _current_tool: StringName = &"brush":
	set(value):
		if _current_tool != value:
			_current_tool = value
			current_tool_changed.emit(value)

var _active_layer_id: int = -1:
	set(value):
		if _active_layer_id != value:
			_active_layer_id = value
			active_layer_changed.emit(value)

var _primary_color: Color = Color.BLACK:
	set(value):
		if _primary_color != value:
			_primary_color = value
			primary_color_changed.emit(value)

var _secondary_color: Color = Color.WHITE:
	set(value):
		if _secondary_color != value:
			_secondary_color = value
			secondary_color_changed.emit(value)

var _canvas_size: Vector2i = Vector2i(64, 64)
var _zoom_level: float = 1.0

# Сигналы изменения состояния
signal current_tool_changed(tool_id: StringName)
signal active_layer_changed(layer_id: int)
signal primary_color_changed(color: Color)
signal secondary_color_changed(color: Color)

# Геттеры (без сеттеров извне — только через методы)
var current_tool: StringName:
	get: return _current_tool

var active_layer_id: int:
	get: return _active_layer_id

var primary_color: Color:
	get: return _primary_color

var secondary_color: Color:
	get: return _secondary_color

var canvas_size: Vector2i:
	get: return _canvas_size

# Методы изменения состояния (можно добавить валидацию)
func select_tool(tool_id: StringName) -> void:
	_current_tool = tool_id

func select_layer(layer_id: int) -> void:
	_active_layer_id = layer_id

func set_primary_color(color: Color) -> void:
	_primary_color = color

func set_secondary_color(color: Color) -> void:
	_secondary_color = color
3. Система инструментов (Strategy + Registry)
Базовый класс инструмента:
gdscriptDownloadCopy code# core/tools/tool_base.gd
class_name ToolBase
extends RefCounted

# Метаданные инструмента
var tool_id: StringName
var display_name: String
var icon: Texture2D
var cursor_icon: StringName

# Настройки (переопределяются в наследниках)
var settings: Dictionary = {}

# Зависимости инжектируются при создании
var _canvas_operations: CanvasOperations
var _command_history: CommandHistory

func _init(canvas_ops: CanvasOperations, history: CommandHistory) -> void:
	_canvas_operations = canvas_ops
	_command_history = history

# Жизненный цикл инструмента
func activate() -> void:
	pass

func deactivate() -> void:
	pass

# Обработка ввода (переопределяется в наследниках)
func on_stroke_start(pos: Vector2i, button: MouseButton) -> void:
	pass

func on_stroke_move(pos: Vector2i) -> void:
	pass

func on_stroke_end(pos: Vector2i) -> void:
	pass

# Для preview (необязательно)
func get_preview(pos: Vector2i) -> Image:
	return null

# Настройки
func get_settings_schema() -> Array[Dictionary]:
	# Возвращает описание настроек для UI
	return []

func apply_settings(new_settings: Dictionary) -> void:
	settings.merge(new_settings, true)
Конкретный инструмент — кисть:
gdscriptDownloadCopy code# core/tools/brush_tool.gd
class_name BrushTool
extends ToolBase

var _current_stroke: Array[Vector2i] = []
var _stroke_color: Color

func _init(canvas_ops: CanvasOperations, history: CommandHistory) -> void:
	super(canvas_ops, history)
	tool_id = &"brush"
	display_name = "Кисть"
	cursor_icon = &"crosshair"
	settings = {
		"size": 1,
		"opacity": 1.0,
		"interpolate": true
	}

func on_stroke_start(pos: Vector2i, button: MouseButton) -> void:
	_current_stroke.clear()
	_stroke_color = AppState.primary_color if button == MOUSE_BUTTON_LEFT else AppState.secondary_color
	_add_point(pos)

func on_stroke_move(pos: Vector2i) -> void:
	if _current_stroke.is_empty():
		return
	
	if settings.interpolate:
		var last_pos := _current_stroke[-1]
		for point in _interpolate_line(last_pos, pos):
			_add_point(point)
	else:
		_add_point(pos)

func on_stroke_end(pos: Vector2i) -> void:
	if _current_stroke.is_empty():
		return
	
	# Создаём команду для undo/redo
	var command := DrawCommand.new(
		AppState.active_layer_id,
		_current_stroke.duplicate(),
		_stroke_color,
		settings.size
	)
	_command_history.execute(command)
	_current_stroke.clear()

func _add_point(pos: Vector2i) -> void:
	_current_stroke.append(pos)
	# Немедленная отрисовка для отзывчивости
	_canvas_operations.draw_pixel(
		AppState.active_layer_id, 
		pos, 
		_stroke_color, 
		settings.size
	)

func _interpolate_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# Алгоритм Брезенхэма
	var points: Array[Vector2i] = []
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var sx := 1 if from.x < to.x else -1
	var sy := 1 if from.y < to.y else -1
	var err := dx - dy
	var x := from.x
	var y := from.y
	
	while true:
		points.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	
	return points

func get_settings_schema() -> Array[Dictionary]:
	return [
		{
			"key": "size",
			"type": "int",
			"label": "Размер",
			"min": 1,
			"max": 64,
			"default": 1
		},
		{
			"key": "opacity",
			"type": "float",
			"label": "Непрозрачность",
			"min": 0.0,
			"max": 1.0,
			"default": 1.0
		}
	]
Реестр инструментов:
gdscriptDownloadCopy code# core/tools/tool_registry.gd
class_name ToolRegistry
extends RefCounted

var _tools: Dictionary = {}  # StringName -> ToolBase
var _canvas_operations: CanvasOperations
var _command_history: CommandHistory

func _init(canvas_ops: CanvasOperations, history: CommandHistory) -> void:
	_canvas_operations = canvas_ops
	_command_history = history

func register_tool(tool_class: GDScript) -> void:
	var tool: ToolBase = tool_class.new(_canvas_operations, _command_history)
	_tools[tool.tool_id] = tool

func get_tool(tool_id: StringName) -> ToolBase:
	return _tools.get(tool_id)

func get_all_tools() -> Array[ToolBase]:
	var result: Array[ToolBase] = []
	for tool in _tools.values():
		result.append(tool)
	return result

func has_tool(tool_id: StringName) -> bool:
	return _tools.has(tool_id)
4. Система команд (для Undo/Redo)
gdscriptDownloadCopy code# core/commands/command_base.gd
class_name CommandBase
extends RefCounted

var description: String = ""

func execute() -> void:
	push_error("CommandBase.execute() must be overridden")

func undo() -> void:
	push_error("CommandBase.undo() must be overridden")

# Для объединения мелких команд (например, много точек в одном штрихе)
func can_merge_with(other: CommandBase) -> bool:
	return false

func merge_with(other: CommandBase) -> void:
	pass
gdscriptDownloadCopy code# core/commands/draw_command.gd
class_name DrawCommand
extends CommandBase

var layer_id: int
var points: Array[Vector2i]
var color: Color
var size: int
var _previous_pixels: Dictionary = {}  # Vector2i -> Color

func _init(p_layer_id: int, p_points: Array[Vector2i], p_color: Color, p_size: int) -> void:
	layer_id = p_layer_id
	points = p_points
	color = p_color
	size = p_size
	description = "Рисование кистью"

func execute() -> void:
	# Сохраняем предыдущие пиксели для undo
	var layer := ServiceLocator.get_layer_stack().get_layer(layer_id)
	if not layer:
		return
	
	for point in points:
		for dx in range(-size/2, size/2 + 1):
			for dy in range(-size/2, size/2 + 1):
				var px := point + Vector2i(dx, dy)
				if not _previous_pixels.has(px):
					_previous_pixels[px] = layer.get_pixel(px)
				layer.set_pixel(px, color)
	
	EventBus.canvas_modified.emit(_calculate_bounds())

func undo() -> void:
	var layer := ServiceLocator.get_layer_stack().get_layer(layer_id)
	if not layer:
		return
	
	for px in _previous_pixels:
		layer.set_pixel(px, _previous_pixels[px])
	
	EventBus.canvas_modified.emit(_calculate_bounds())

func _calculate_bounds() -> Rect2i:
	if points.is_empty():
		return Rect2i()
	var min_p := points[0]
	var max_p := points[0]
	for p in points:
		min_p = Vector2i(mini(min_p.x, p.x), mini(min_p.y, p.y))
		max_p = Vector2i(maxi(max_p.x, p.x), maxi(max_p.y, p.y))
	return Rect2i(min_p - Vector2i(size, size), max_p - min_p + Vector2i(size * 2, size * 2))
gdscriptDownloadCopy code# core/commands/command_history.gd
class_name CommandHistory
extends RefCounted

signal history_changed()

var _undo_stack: Array[CommandBase] = []
var _redo_stack: Array[CommandBase] = []
var _max_history: int = 100

func execute(command: CommandBase) -> void:
	command.execute()
	
	# Пробуем объединить с предыдущей командой
	if not _undo_stack.is_empty() and _undo_stack[-1].can_merge_with(command):
		_undo_stack[-1].merge_with(command)
	else:
		_undo_stack.append(command)
		if _undo_stack.size() > _max_history:
			_undo_stack.pop_front()
	
	_redo_stack.clear()
	history_changed.emit()

func undo() -> void:
	if _undo_stack.is_empty():
		return
	var command := _undo_stack.pop_back()
	command.undo()
	_redo_stack.append(command)
	history_changed.emit()

func redo() -> void:
	if _redo_stack.is_empty():
		return
	var command := _redo_stack.pop_back()
	command.execute()
	_undo_stack.append(command)
	history_changed.emit()

func can_undo() -> bool:
	return not _undo_stack.is_empty()

func can_redo() -> bool:
	return not _redo_stack.is_empty()

func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	history_changed.emit()
5. Service Locator (контролируемый доступ к сервисам)
gdscriptDownloadCopy code# autoload/service_locator.gd
extends Node

var _services: Dictionary = {}

func register(service_name: StringName, service: Object) -> void:
	if _services.has(service_name):
		push_warning("Service '%s' is being overwritten" % service_name)
	_services[service_name] = service

func get_service(service_name: StringName) -> Object:
	if not _services.has(service_name):
		push_error("Service '%s' not found" % service_name)
		return null
	return _services[service_name]

func has_service(service_name: StringName) -> bool:
	return _services.has(service_name)

# Типизированные хелперы для частых сервисов
func get_tool_registry() -> ToolRegistry:
	return get_service(&"tool_registry") as ToolRegistry

func get_layer_stack() -> LayerStack:
	return get_service(&"layer_stack") as LayerStack

func get_command_history() -> CommandHistory:
	return get_service(&"command_history") as CommandHistory

func get_canvas_operations() -> CanvasOperations:
	return get_service(&"canvas_operations") as CanvasOperations
6. Контроллер инструментов (Application layer)
gdscriptDownloadCopy code# application/tool_controller.gd
class_name ToolController
extends Node

var _tool_registry: ToolRegistry
var _current_tool: ToolBase

func _ready() -> void:
	_tool_registry = ServiceLocator.get_tool_registry()
	
	# Подписываемся на события
	EventBus.tool_selected.connect(_on_tool_selected)
	AppState.current_tool_changed.connect(_on_current_tool_changed)
	
	# Регистрируем стандартные инструменты
	_tool_registry.register_tool(BrushTool)
	_tool_registry.register_tool(EraserTool)
	_tool_registry.register_tool(FillTool)
	_tool_registry.register_tool(SelectionTool)
	
	# Активируем инструмент по умолчанию
	_activate_tool(&"brush")

func _on_tool_selected(tool_id: StringName) -> void:
	AppState.select_tool(tool_id)

func _on_current_tool_changed(tool_id: StringName) -> void:
	_activate_tool(tool_id)

func _activate_tool(tool_id: StringName) -> void:
	if _current_tool:
		_current_tool.deactivate()
	
	_current_tool = _tool_registry.get_tool(tool_id)
	
	if _current_tool:
		_current_tool.activate()
		EventBus.cursor_icon_requested.emit(_current_tool.cursor_icon)

# Делегирование ввода текущему инструменту
func handle_stroke_start(pos: Vector2i, button: MouseButton) -> void:
	if _current_tool:
		_current_tool.on_stroke_start(pos, button)

func handle_stroke_move(pos: Vector2i) -> void:
	if _current_tool:
		_current_tool.on_stroke_move(pos)

func handle_stroke_end(pos: Vector2i) -> void:
	if _current_tool:
		_current_tool.on_stroke_end(pos)
7. UI компоненты (Presentation layer)
Панель инструментов:
gdscriptDownloadCopy code# presentation/panels/tool_panel/tool_panel.gd
extends Panel

@export var tool_button_scene: PackedScene

@onready var _button_container: VBoxContainer = $ToolBar

func _ready() -> void:
	# Ждём регистрации сервисов
	await get_tree().process_frame
	_build_tool_buttons()
	
	# Подписываемся на изменение текущего инструмента
	AppState.current_tool_changed.connect(_on_current_tool_changed)

func _build_tool_buttons() -> void:
	var registry := ServiceLocator.get_tool_registry()
	
	for tool in registry.get_all_tools():
		var button: ToolButton = tool_button_scene.instantiate()
		button.setup(tool.tool_id, tool.display_name, tool.icon)
		button.pressed.connect(_on_tool_button_pressed.bind(tool.tool_id))
		_button_container.add_child(button)

func _on_tool_button_pressed(tool_id: StringName) -> void:
	EventBus.tool_selected.emit(tool_id)

func _on_current_tool_changed(tool_id: StringName) -> void:
	# Обновляем визуальное состояние кнопок
	for button in _button_container.get_children():
		if button is ToolButton:
			button.set_selected(button.tool_id == tool_id)
Кнопка инструмента:
gdscriptDownloadCopy code# presentation/panels/tool_panel/tool_button.gd
class_name ToolButton
extends TextureRect

signal pressed()

var tool_id: StringName

var _is_selected: bool = false
var _is_hovered: bool = false

func setup(p_tool_id: StringName, p_name: String, p_icon: Texture2D) -> void:
	tool_id = p_tool_id
	texture = p_icon
	tooltip_text = p_name

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_visual()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit()

func _mouse_enter() -> void:
	_is_hovered = true
	_update_visual()

func _mouse_exit() -> void:
	_is_hovered = false
	_update_visual()

func _update_visual() -> void:
	if _is_selected:
		modulate = Color(1.2, 1.2, 1.2)
		scale = Vector2(1.1, 1.1)
	elif _is_hovered:
		modulate = Color(1.1, 1.1, 1.1)
		scale = Vector2(1.05, 1.05)
	else:
		modulate = Color.WHITE
		scale = Vector2.ONE
8. Инициализация приложения
gdscriptDownloadCopy code# app.gd
extends Node2D

func _ready() -> void:
	_initialize_services()
	_setup_input_handling()

func _initialize_services() -> void:
	# Создаём core сервисы
	var canvas_ops := CanvasOperations.new()
	var layer_stack := LayerStack.new()
	var command_history := CommandHistory.new()
	var tool_registry := ToolRegistry.new(canvas_ops, command_history)
	
	# Регистрируем в Service Locator
	ServiceLocator.register(&"canvas_operations", canvas_ops)
	ServiceLocator.register(&"layer_stack", layer_stack)
	ServiceLocator.register(&"command_history", command_history)
	ServiceLocator.register(&"tool_registry", tool_registry)
	
	# Инициализируем слой по умолчанию
	layer_stack.add_layer()
	AppState.select_layer(layer_stack.get_layer_ids()[0])

func _setup_input_handling() -> void:
	# Глобальные хоткеи
	EventBus.undo_requested.connect(func(): ServiceLocator.get_command_history().undo())
	EventBus.redo_requested.connect(func(): ServiceLocator.get_command_history().redo())

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo"):  # Ctrl+Z
		EventBus.undo_requested.emit()
	elif event.is_action_pressed("ui_redo"):  # Ctrl+Y / Ctrl+Shift+Z
		EventBus.redo_requested.emit()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		get_tree().quit()

Диаграмма взаимодействия
┌─────────────┐     нажатие      ┌─────────────┐
│ ToolButton  │ ───────────────> │  EventBus   │
└─────────────┘                  └──────┬──────┘
                                        │ tool_selected
                                        ▼
┌─────────────┐  current_tool   ┌─────────────┐
│  AppState   │ <────────────── │ ToolController│
└──────┬──────┘   changed       └──────┬──────┘
       │                               │
       │ current_tool_changed          │ _activate_tool()
       ▼                               ▼
┌─────────────┐                 ┌─────────────┐
│ ToolPanel   │                 │  BrushTool  │
│ (обновляет  │                 │ (активирует)│
│  кнопки)    │                 └─────────────┘
└─────────────┘


Добавление нового инструмента
Теперь добавить новый инструмент — это создать один файл:
gdscriptDownloadCopy code# core/tools/line_tool.gd
class_name LineTool
extends ToolBase

var _start_pos: Vector2i
var _preview_end: Vector2i

func _init(canvas_ops: CanvasOperations, history: CommandHistory) -> void:
	super(canvas_ops, history)
	tool_id = &"line"
	display_name = "Линия"
	cursor_icon = &"crosshair"

func on_stroke_start(pos: Vector2i, button: MouseButton) -> void:
	_start_pos = pos

func on_stroke_move(pos: Vector2i) -> void:
	_preview_end = pos
	# Можно эмитить сигнал для отрисовки preview

func on_stroke_end(pos: Vector2i) -> void:
	var command := LineCommand.new(
		AppState.active_layer_id,
		_start_pos,
		pos,
		AppState.primary_color
	)
	_command_history.execute(command)
И зарегистрировать:
gdscriptDownloadCopy code# В tool_controller.gd
_tool_registry.register_tool(LineTool)
Всё. UI подхватит автоматически, undo/redo работает, никакие другие файлы менять не нужно.

Итого: что даёт новая архитектура
АспектБылоСталоСвязанностьВысокая (все знают про всех)Низкая (через EventBus и интерфейсы)Добавление инструментаМенять 5+ файловСоздать 1 файл + регистрацияUndo/RedoНетВстроено в архитектуруТестируемостьСложноЛегко (DI, изолированная логика)Понимание кода"Где что лежит?"Чёткие слои и ответственностиРасширение под анимациюСтрашноДобавляем новые контроллеры и сервисы

### План 2: .Godot-Managers.

План архитектуры проекта

Краткий список недочетов старой архитектуры

В ходе анализа текущей архитектуры проекта были выявлены следующие ключевые проблемы, которые приводят к ощущению "несвязности", "немодульности" и трудностям в разработке и расширении:

1.  **Чрезмерное использование синглтонов (`static var instance`):** Большинство ключевых компонентов (DrawContainer, CanvasCamera, LayersPanel, SwatchPicker, CursorDrawer, CursorSprite, а также неявный Globals) реализованы как синглтоны. Это приводит к:
    *   **Жёстким связям (Tight Coupling):** Компоненты напрямую обращаются друг к другу через `ClassName.instance`, что делает их сильно зависимыми.
    *   **Трудностям в тестировании:** Изолированное тестирование компонентов становится крайне сложным.
    *   **Трудностям в расширении:** Добавление новой функциональности часто требует изменения нескольких тесно связанных компонентов.

2.  **Глобальные зависимости (`Globals`):** Использование глобального `Globals.gd` как "мусорной свалки" для общих данных и сигналов усиливает проблему жёстких связей и затрудняет отслеживание потока данных.

3.  **Смешение ответственности (Low Cohesion):** Некоторые классы выполняют слишком много задач. Например:
    *   `DrawContainer` управляет холстом, логикой рисования для кисти/ластика, логикой выделения и реагирует на изменения слоёв.
    *   `Tool` (скрипт) отвечает за визуальное представление кнопки, обработку ввода и установку глобального режима курсора.

4.  **Неявное управление состоянием:** Состояние активного инструмента, активного слоя, выбранного цвета и режима курсора управляется через множество глобальных синглтонов, что затрудняет отслеживание текущего состояния приложения и может приводить к ошибкам.

5.  **Трудности с расширением:** Добавление нового инструмента или функции требует изменения кода в нескольких местах, что делает процесс трудоёмким и подверженным ошибкам.

Полный план новой модульной архитектуры через менеджеры

Цель новой архитектуры — создать модульную, чистую, связную и расширяемую систему, основанную на принципах разделения ответственности (Separation of Concerns), слабой связанности (Loose Coupling) и высокой связности (High Cohesion).

Основные принципы:

1.  **Устранение синглтонов:** Замена прямых вызовов `ClassName.instance` на более гибкие механизмы:
    *   **Сигналы Godot:** Для асинхронного общения между несвязанными компонентами.
    *   **Инъекция зависимостей:** Передача необходимых ссылок через `@export` переменные или при создании экземпляров.
    *   **Группы Godot:** Для более гибкого поиска и взаимодействия с группами узлов.
2.  **Централизованное управление состоянием (но не глобальный синглтон):** Создание одного или нескольких "менеджеров" (например, `ToolManager`, `LayerManager`, `ColorManager`), которые будут отвечать за управление состоянием своих доменов. Эти менеджеры будут доступны через инъекцию зависимостей или как автозагружаемые синглтоны, но их API будет чётким и ограниченным, чтобы избежать "мусорной свалки".
3.  **Разделение UI и логики:** UI-элементы должны быть максимально "глупыми" и только отображать данные и отправлять события. Вся логика должна быть в отдельных скриптах или менеджерах.
4.  **Модульная система инструментов:** Каждый инструмент должен быть отдельным классом/сценой, инкапсулирующим свою логику и визуальное представление.

Предлагаемая структура модулей/менеджеров:

1.  **`App` (Root Node):**
    *   Основная сцена, которая собирает все остальные компоненты.
    *   Отвечает за инициализацию и связывание основных менеджеров.
    *   Может содержать ссылки на основные UI-панели.
    *   Минимальная логика, в основном координация.

2.  **`InputManager` (Автозагружаемый синглтон):**
    *   Отвечает за обработку всего пользовательского ввода (мышь, клавиатура).
    *   Преобразует низкоуровневые события ввода в высокоуровневые действия (например, "начать рисовать", "переместить камеру", "выбрать инструмент").
    *   Испускает сигналы, на которые подписываются другие менеджеры/компоненты.
    *   **Преимущества:** Централизованная обработка ввода, легко менять привязки клавиш, легко добавлять новые действия.

3.  **`ToolManager` (Автозагружаемый синглтон):**
    *   Управляет активным инструментом.
    *   Содержит список доступных инструментов.
    *   Испускает сигнал `tool_changed(new_tool_type)`, на который подписываются UI-элементы (для подсветки активного инструмента) и `DrawManager` (для изменения поведения рисования).
    *   Предоставляет API для выбора инструмента.
    *   **Преимущества:** Инкапсулирует логику выбора инструмента, легко добавлять новые инструменты.

4.  **`DrawManager` (Автозагружаемый синглтон):**
    *   Основной контроллер для логики рисования.
    *   Подписывается на сигналы от `InputManager` (например, "начать рисовать", "переместить курсор") и `ToolManager` (для определения текущего инструмента).
    *   Взаимодействует с `LayerManager` для получения активного слоя и применения изменений.
    *   Отвечает за отрисовку курсора рисования, выделения и т.д.
    *   **Преимущества:** Централизованная логика рисования, легко добавлять новые режимы рисования.

5.  **`LayerManager` (Автозагружаемый синглтон):**
    *   Управляет всеми слоями рисования.
    *   Содержит список слоёв, активный слой.
    *   Предоставляет API для создания, удаления, переупорядочивания слоёв, установки активного слоя.
    *   Испускает сигналы `layer_added(layer)`, `layer_removed(layer)`, `active_layer_changed(layer)`.
    *   **Преимущества:** Инкапсулирует логику управления слоями, UI-панель слоёв просто отображает данные из этого менеджера.

6.  **`ColorManager` (Автозагружаемый синглтон):**
    *   Управляет основным и второстепенным цветом.
    *   Предоставляет API для установки цветов.
    *   Испускает сигналы `primary_color_changed(color)`, `secondary_color_changed(color)`.
    *   **Преимущества:** Централизованное управление цветами, UI-элементы выбора цвета просто взаимодействуют с этим менеджером.

7.  **`CursorManager` (Автозагружаемый синглтон):**
    *   Управляет отображением курсора (текстура, видимость).
    *   Подписывается на сигналы от `ToolManager` (для изменения формы курсора в зависимости от инструмента) и `InputManager` (для скрытия/показа курсора при входе/выходе из области рисования).
    *   **Преимущества:** Инкапсулирует логику курсора.

Структура UI-компонентов:

*   **`ToolButton` (сцена/скрипт):**
    *   Представляет собой кнопку инструмента.
    *   Имеет `@export var tool_type: ToolManager.ToolType`.
    *   При нажатии вызывает `ToolManager.select_tool(tool_type)`.
    *   Подписывается на `ToolManager.tool_changed` для подсветки себя, если это активный инструмент.
    *   **Преимущества:** Каждый инструмент — это отдельный, самодостаточный UI-компонент.

*   **`SwatchButton` (сцена/скрипт):**
    *   Представляет собой образец цвета.
    *   Имеет `@export var color_type: ColorManager.ColorType` (например, `PRIMARY`, `SECONDARY`).
    *   При нажатии вызывает `ColorManager.open_color_picker(color_type)`.
    *   Подписывается на `ColorManager.primary_color_changed` / `secondary_color_changed` для обновления своего цвета.
    *   **Преимущества:** Инкапсулирует логику выбора цвета.

*   **`LayerItem` (сцена/скрипт):**
    *   Представляет собой один элемент слоя в `LayersPanel`.
    *   Отображает информацию о слое (имя, видимость).
    *   При нажатии вызывает `LayerManager.set_active_layer(layer_id)`.
    *   Подписывается на `LayerManager.active_layer_changed` для подсветки себя, если это активный слой.
    *   **Преимущества:** Каждый элемент слоя — это отдельный UI-компонент.

*   **`LayersPanel` (сцена/скрипт):**
    *   Отвечает за отображение списка `LayerItem`.
    *   Подписывается на `LayerManager.layer_added`, `LayerManager.layer_removed` для обновления списка.
    *   Кнопки "Добавить/Удалить" вызывают соответствующие методы `LayerManager`.
    *   **Преимущества:** Панель слоёв просто отображает данные, логика управления слоями находится в `LayerManager`.

Как это решает проблемы:

*   **Модульность:** Каждый менеджер и UI-компонент имеет чётко определённую ответственность.
*   **Слабая связанность:** Компоненты общаются через сигналы или через чётко определённые API менеджеров, а не через прямые ссылки на синглтоны.
*   **Расширяемость:** Добавление нового инструмента, типа слоя или функции рисования требует изменения только соответствующих менеджеров и создания новых UI-компонентов, а не переписывания всего приложения.
*   **Читаемость:** Поток данных и логики становится более предсказуемым и лёгким для отслеживания.
*   **Тестируемость:** Компоненты можно тестировать изолированно, подменяя зависимости.

Дальнейшие шаги:

1.  **Создание автозагружаемых синглтонов (менеджеров):** Начнём с создания пустых скриптов для `InputManager`, `ToolManager`, `DrawManager`, `LayerManager`, `ColorManager`, `CursorManager` и добавления их в автозагрузку Godot.
2.  **Определение API менеджеров:** Для каждого менеджера определим, какие сигналы он будет испускать и какие публичные методы предоставлять.
3.  **Рефакторинг существующих компонентов:** Постепенно перенесем логику из существующих скриптов в соответствующие менеджеры и изменим UI-компоненты для взаимодействия с менеджерами через их API и сигналы.
