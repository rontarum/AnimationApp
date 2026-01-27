# Финальное решение: Service Locator + Services

## Согласен с тобой

Ты прав — ServiceLocator действительно удобен и не создаёт overload. Более того, он решает проблему передачи зависимостей элегантнее, чем @export.

## Финальная архитектура

### Автозагрузки (3 штуки)
```
autoload/
├── event_bus.gd      # Шина событий
├── app_state.gd      # Реактивное состояние
└── services.gd       # Service Locator
```

### Структура
```
res://
├── autoload/
│   ├── event_bus.gd
│   ├── app_state.gd
│   └── services.gd
│
├── services/              # Сервисы (Node)
│   ├── canvas_service.gd
│   ├── layer_service.gd
│   ├── tool_service.gd
│   ├── history_service.gd
│   └── clipboard_service.gd
│
├── core/                  # Чистая логика (RefCounted)
│   ├── tools/
│   │   ├── tool_base.gd
│   │   ├── brush_tool.gd
│   │   └── eraser_tool.gd
│   │
│   └── commands/
│       ├── command_base.gd
│       └── draw_command.gd
│
└── ui/                    # UI компоненты
    ├── panels/
    └── components/
```

### Ключевые компоненты

**1. Services (autoload)**
```gdscript
# autoload/services.gd
extends Node

var _services: Dictionary = {}

func register(name: StringName, service: Node) -> void:
    _services[name] = service

func get_service(name: StringName) -> Node:
    return _services.get(name)

# Типизированные геттеры
func get_canvas() -> CanvasService:
    return get_service(&"canvas")

func get_layers() -> LayerService:
    return get_service(&"layers")

func get_tools() -> ToolService:
    return get_service(&"tools")

func get_history() -> HistoryService:
    return get_service(&"history")
```

**2. Canvas Service**
```gdscript
# services/canvas_service.gd
class_name CanvasService
extends Node

var _image: Image
var _size: Vector2i

func create(size: Vector2i) -> void:
    _size = size
    _image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    _image.fill(Color.TRANSPARENT)
    EventBus.canvas_created.emit(size)

func get_pixel(pos: Vector2i) -> Color:
    if _is_valid(pos):
        return _image.get_pixelv(pos)
    return Color.TRANSPARENT

func set_pixel(pos: Vector2i, color: Color) -> void:
    if _is_valid(pos):
        _image.set_pixelv(pos, color)

func get_image() -> Image:
    return _image

func _is_valid(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < _size.x and pos.y < _size.y
```

**3. Tool Service**
```gdscript
# services/tool_service.gd
class_name ToolService
extends Node

var _tools: Dictionary = {}
var _current_tool: ToolBase

func _ready() -> void:
    _register_tools()
    EventBus.tool_selected.connect(_on_tool_selected)

func _register_tools() -> void:
    register_tool(BrushTool.new())
    register_tool(EraserTool.new())
    register_tool(FillTool.new())

func register_tool(tool: ToolBase) -> void:
    _tools[tool.tool_id] = tool

func get_tool(tool_id: StringName) -> ToolBase:
    return _tools.get(tool_id)

func _on_tool_selected(tool_id: StringName) -> void:
    if _current_tool:
        _current_tool.deactivate()
    
    _current_tool = get_tool(tool_id)
    if _current_tool:
        _current_tool.activate()
```

**4. History Service (Undo/Redo)**
```gdscript
# services/history_service.gd
class_name HistoryService
extends Node

var _undo_stack: Array[CommandBase] = []
var _redo_stack: Array[CommandBase] = []

func _ready() -> void:
    EventBus.undo_requested.connect(undo)
    EventBus.redo_requested.connect(redo)

func execute(command: CommandBase) -> void:
    command.execute()
    _undo_stack.append(command)
    _redo_stack.clear()

func undo() -> void:
    if _undo_stack.is_empty():
        return
    var cmd = _undo_stack.pop_back()
    cmd.undo()
    _redo_stack.append(cmd)

func redo() -> void:
    if _redo_stack.is_empty():
        return
    var cmd = _redo_stack.pop_back()
    cmd.execute()
    _undo_stack.append(cmd)
```

**5. Инициализация в app.gd**
```gdscript
# app.gd
extends Node2D

func _ready() -> void:
    _register_services()

func _register_services() -> void:
    # Создаём сервисы
    var canvas = CanvasService.new()
    var layers = LayerService.new()
    var tools = ToolService.new()
    var history = HistoryService.new()
    
    # Добавляем в дерево
    add_child(canvas)
    add_child(layers)
    add_child(tools)
    add_child(history)
    
    # Регистрируем в Services
    Services.register(&"canvas", canvas)
    Services.register(&"layers", layers)
    Services.register(&"tools", tools)
    Services.register(&"history", history)
    
    # Инициализируем холст
    canvas.create(Vector2i(64, 64))
```

**6. Использование в инструментах**
```gdscript
# core/tools/brush_tool.gd
class_name BrushTool
extends ToolBase

var _stroke: Array[Vector2i] = []

func on_stroke_move(pos: Vector2i) -> void:
    _stroke.append(pos)
    Services.get_canvas().set_pixel(pos, AppState.primary_color)

func on_stroke_end(pos: Vector2i) -> void:
    var cmd = DrawCommand.new(_stroke.duplicate(), AppState.primary_color)
    Services.get_history().execute(cmd)
    _stroke.clear()
```

## Преимущества

✅ **Чистый доступ** — `Services.get_canvas()` вместо `CanvasService.instance`  
✅ **Типизация** — автодополнение работает  
✅ **Тестируемость** — можно подменить сервисы  
✅ **Централизация** — все сервисы в одном месте  
✅ **Гибкость** — легко добавлять новые сервисы  
✅ **Нет overload** — простая и понятная структура  

## Что получаем

- **3 автозагрузки:** EventBus, AppState, Services
- **Сервисы как Node:** живут в дереве сцены
- **Core как RefCounted:** чистая логика без зависимостей от движка
- **Command Pattern:** встроенный Undo/Redo
- **Чистая архитектура:** UI → Services → Core

## Вердикт

Добавляем ServiceLocator к гибридному плану. Это даёт лучшее из обоих миров:
- Удобство доступа к сервисам
- Чистая архитектура
- Простота понимания
- Легко расширять

**Готов к реализации.**
