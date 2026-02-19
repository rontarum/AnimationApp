# Project Save/Load — Дизайн

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                      ProjectManager                          │
│              (autoload, координатор save/load)               │
├─────────────────────────────────────────────────────────────┤
│  - current_project_path: String                              │
│  - is_dirty: bool                                            │
│  - auto_save_timer: Timer                                    │
│  - _save_in_progress: bool                                   │
├─────────────────────────────────────────────────────────────┤
│  + save_project(path: String)                                │
│  + load_project(path: String)                                │
│  + new_project(size: Vector2i)                               │
│  + auto_save()                                               │
│  + has_unsaved_changes() -> bool                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Services                              │
├───────────────────────┬───────────────────────┬─────────────┤
│    CanvasService      │    LayerService       │  AppState   │
├───────────────────────┼───────────────────────┼─────────────┤
│  - get_all_images()   │  - get_all_layers()   │  - canvas_size
│  - set_all_images()   │  - clear_layers()     │  - current_tab
│  - clear_canvas()     │  - create_layer()     │  - active_layer_id
└───────────────────────┴───────────────────────┴─────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DrawMenu (UI)                           │
├─────────────────────────────────────────────────────────────┤
│  - ProjectSaveDialog (FileDialog)                            │
│  - ProjectOpenDialog (FileDialog)                            │
│  - NewProjectDialog (кастомный)                              │
├─────────────────────────────────────────────────────────────┤
│  - NEW → NewProjectDialog → ProjectManager.new_project()     │
│  - OPEN → ProjectOpenDialog → ProjectManager.load_project()  │
│  - SAVE → ProjectManager.auto_save()                         │
│  - SAVE_AS → ProjectSaveDialog → save_project(path)          │
└─────────────────────────────────────────────────────────────┘
```

## Файлы

### Новые файлы

| Файл | Описание |
|------|----------|
| `assets/globals/project_manager.gd` | Autoload для управления проектом |
| `assets/data/draw_layer_data.gd` | Resource для данных слоя |
| `assets/data/project_data.gd` | Resource для данных проекта |

### Изменяемые файлы

| Файл | Изменения |
|------|-----------|
| `assets/ui_components/draw_menu.gd` | Добавить обработчики NEW/OPEN/SAVE/SAVE_AS |
| `assets/services/canvas_service.gd` | Добавить get_all_images(), set_all_images() |
| `assets/services/layer_service.gd` | Добавить get_all_layers(), clear_layers() |
| `app.tscn` | Добавить FileDialog для проектов |

## Data Classes

### DrawLayerData (Resource)
```gdscript
class_name DrawLayerData
extends Resource

@export var layer_id: int
@export var name: String
@export var visible: bool
@export var image_data: PackedByteArray
```

### ProjectData (Resource)
```gdscript
class_name ProjectData
extends Resource

@export var name: String
@export var canvas_size: Vector2i
@export var current_tab: int
@export var layers: Array[DrawLayerData]
```

## ProjectManager API

### Сигналы
```gdscript
signal project_saved(path: String)
signal project_loaded(path: String)
signal project_closed
signal auto_save_triggered
signal auto_save_completed
signal auto_save_failed(error: String)
```

### Методы

#### save_project(path: String) -> bool
```gdscript
## Сохраняет проект в указанный файл
## Args: path - полный путь к файлу .tres
## Returns: true если сохранение успешно
```

#### load_project(path: String) -> bool
```gdscript
## Загружает проект из файла
## Args: path - полный путь к файлу .tres
## Returns: true если загрузка успешна
```

#### new_project(size: Vector2i) -> void
```gdscript
## Создаёт новый проект
## Args: size - размер холста
## Очищает все слои и сбрасывает состояние
```

#### auto_save() -> bool
```gdscript
## Выполняет автосохранение
## Использует current_project_path
## Returns: true если сохранение выполнено
```

#### has_unsaved_changes() -> bool
```gdscript
## Проверяет наличие несохранённых изменений
## Returns: true если есть изменения
```

## EventBus события

| Событие | Параметры | Описание |
|---------|-----------|----------|
| `project_saved` | path: String | Проект сохранён |
| `project_loaded` | path: String | Проект загружен |
| `project_closed` | — | Проект закрыт (новый проект) |
| `auto_save_triggered` | — | Началось автосохранение |
| `auto_save_completed` | — | Автосохранение завершено |
| `auto_save_failed` | error: String | Ошибка автосохранения |

## Auto-save триггеры

### 1. Переключение вкладки
```gdscript
# В AppState при смене таба
func set current_tab(val):
    if current_tab != val:
        auto_save()  # Перед сменой
        current_tab = val
```

### 2. Таймер (каждую минуту)
```gdscript
# В ProjectManager._ready()
auto_save_timer = Timer.new()
auto_save_timer.wait_time = 60
auto_save_timer.timeout.connect(auto_save)
add_child(auto_save_timer)
auto_save_timer.start()
```

### 3. Action "save"
```gdscript
# В AppState._input()
if event.is_action_pressed("save"):
    auto_save()
```

## Алгоритм сохранения

```
1. Проверить is_dirty
2. Собрать данные слоёв из LayerService
3. Собрать изображения из CanvasService
4. Создать ProjectData
5. ResourceSaver.save(project_data, path)
6. Обновить current_project_path
7. Сбросить is_dirty = false
8. emit project_saved
```

## Алгоритм загрузки

```
1. Загрузить ResourceLoader.load(path)
2. Восстановить canvas_size в AppState
3. Очистить текущие слои
4. Создать слои из ProjectData.layers
5. Восстановить изображения через CanvasService
6. Восстановить current_tab
7. Обновить current_project_path
8. emit project_loaded
```

## UI Компоненты

### NewProjectDialog (кастомный)
```
┌─────────────────────────────┐
│     New Project             │
├─────────────────────────────┤
│  Width:  [ 32  ]            │
│  Height: [ 32  ]            │
│                             │
│  [ Cancel ]  [ Create ]     │
└─────────────────────────────┘
```

### FileDialog настройки

| Свойство | ProjectSaveDialog | ProjectOpenDialog |
|----------|-------------------|-------------------|
| mode | SAVE_FILE | OPEN_FILE |
| access | FILE_SYSTEM | FILE_SYSTEM |
| file_mode | | OPEN_FILE |
| filters | ["*.tres"] | ["*.tres"] |
| ok_label_text | "Save" | "Open" |

## Тестирование

### Unit тесты
- Сохранение пустого проекта
- Сохранение с одним слоем
- Сохранение с несколькими слоями
- Загрузка и восстановление данных
- Проверка image_data

### Property-based тесты
- Сохранение/загрузка с различными размерами холста
- Сохранение/загрузка с различным количеством слоёв
- Проверка целостности изображений после загрузки