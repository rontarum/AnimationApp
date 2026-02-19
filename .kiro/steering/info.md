# Документация проекта ANIMATIONAPP

## Твоя роль и принципы работы

**Коммуникация:**
- Общайся с пользователем только на русском языке
- Внутренние рассуждения и пометки (для себя, если не требует внимания пользователя) пиши на английском (экономия токенов)
- Будь краток, точен, самостоятелен, но прислушивайся к пользователю
- Минимизируй комментарии своих действий, которые не требуют внимания пользователя
- Никогда не отправляй одиночное сообщение типа "Understood." Это трата токенов. Ответ всегда ведет к решению/действию/вопросу/завершению.
- Перед составлением спеки (requirements, design, tasks), задайся вопросом, действительно ли и насколько это необходимо сейчас? Если необходимо, то каждый ли из трёх её компонентов? Экономим время и токены соизмеримо.

**Контекст пользователя:**
- Middle Геймдев разработчик с базой Godot и принципами нодовой работы/композиции
- Не знаком с веб разработкой и её паттернами
- Цель: не только рабочий проект, но и понимание архитектуры для самостоятельной работы

**Документирование:**
- Документируй код кратко, понятно, на русском
- Только там, где неочевидно - код должен быть самодокументирующим
- Экономь токены - не перечитывай и не дублируй одни и те же места многократно

**MCP Godot:**
- Доступен для прямого взаимодействия с Godot
- Проект: `D:\AnimationApp\project.godot`
- **ВАЖНО**: Никогда не редактируй файлы при запущенном тесте - сначала останови процесс

**Технические принципы:**
- Используй `action_...` команды из input map вместо InputEventMouse/Button
- Создавай скрипты/сцены в правильной структуре папок
- **КРИТИЧНО**: Если переменная представляет enum - используй тип enum, НЕ int!
  - ❌ `var tool_type: int`
  - ✅ `var tool_type: ToolType.Type`

**Дебаг:**
- Когда отладка системы перестаёт быть необходима, не забудь удалять все print()

## Цель проекта

Приложение для рисования пиксельарта на Godot 4.6 с поэтапным развитием:

1. **Этап 1 (текущий):** Редактор пиксельарта с инструментами рисования
2. **Этап 2 (планируется):** Полигонизация слоёв в меши + скелетная анимация
3. **Этап 3 (планируется):** Настройка и экспорт правил роста/эволюции пикселей (клеточные автоматы)

## Архитектурные принципы

**Основные принципы:**
- **Слабая связанность** - компоненты общаются через EventBus и Services
- **Высокая связность** - каждый модуль отвечает за одну область
- **Зоны ответственности** - если UI, то только UI; если Core, то Core
- **Принцип имени** - зона ответственности ~= имя компонента (соизмеримо, не обязательно именовать точь-в-точь)
- **God-object контроль** - при обнаружении предлагать декомпозицию

**Пример правильного разделения:**
- `layers_panel.gd` должен отвечать только за UI панели слоёв
- Логика слоёв - в LayerService
- Связь через EventBus/Services, не прямые вызовы

## Текущая архитектура

**Архитектурный паттерн:** EventBus + AppState + Services

### Структура проекта

```
res://
├── assets/globals/          # Автолоад синглтоны
│   ├── event_bus.gd        # Шина событий - центр коммуникации
│   ├── app_state.gd        # Реактивное состояние приложения
│   ├── services.gd         # Service Locator для доступа к сервисам
│   ├── history.gd          # Простой автолод с общим UndoRedo
│   └── tool_type.gd        # Enum типов инструментов (autoload)
│
├── assets/services/         # Бизнес-логика (Node-based сервисы)
│   ├── tool_service.gd     # Управление инструментами и их настройками (tool_properties)
│   ├── layer_service.gd    # Управление слоями через int ID
│   ├── canvas_service.gd   # Управление холстом
│   ├── color_service.gd    # Управление цветами
│   ├── cursor_service.gd   # Управление курсором с override системой
│   └── tree_service.gd     # [ПУСТОЙ] Сервис для дерева (пока не используется)
│
├── assets/core              # Чистая логика (RefCounted)
│   ├── quick_tools.gd      # Control-нода: горячие клавиши + color picker + undo/redo
│   └── tools/              # Классы инструментов
│       ├── base_tool.gd    # Базовый класс инструмента
│       ├── brush_tool.gd   # Кисть
│       ├── eraser_tool.gd  # Ластик
│       ├── fill_tool.gd    # Заливка
│       └── selection_tool.gd # Выделение с state machine
│
├── assets/                  # UI компоненты и ресурсы
│   ├── canvas_renderer.gd  # Отрисовка overlay (pixel preview, selection gizmo, border)
│   ├── canvas_camera.gd    # Камера холста (зум, панорамирование)
│   ├── draw_container.gd   # Роутинг input к активному инструменту
│   ├── scripts/
│   │   ├── draw_layer.gd   # Слой рисования (работает через layer_id)
│   │   └── cursor_sprite.gd # Визуальный курсор (Sprite2D)
│   ├── ui_components/      # UI компоненты
│   │   ├── layers/         # Панель слоёв (layers_panel.gd)
│   │   ├── tree/           # Компоненты дерева (tree.gd, tree_panel.gd, leaf.gd)
│   │   ├── draw_menu.gd    # Меню файловых операций
│   │   ├── main_tabs.gd    # Переключение вкладок (Draw/Animation/Evo)
│   │   └── tool_properties/ # Панель настроек инструментов
│   ├── tool_button.gd      # Кнопки инструм��нтов
│   ├── swatch.gd           # Цветовые образцы
│   ├── swatch_picker.gd    # ColorPicker для свотчей
│   └── window_panel.gd     # Базовый класс для панелей окон
│
├── assets/data/            # Ресурсы данных
│   └── project.gd          # Project Resource (данные проекта)
│
└── app.tscn / app.gd       # Главная сцена - инициализация сервисов
```

### Ключевые компоненты

**1. EventBus (assets/globals/event_bus.gd)**
- Централизованная система событий
- Все компоненты подписываются на события вместо прямых вызовов
- События: `tool_selected`, `primary_color_changed`, `layer_created`, etc.

**2. AppState (assets/globals/app_state.gd)**
- Реактивное состояние с автоматическими уведомлениями
- Свойства: `current_tool`, `primary_color`, `secondary_color`, `active_layer_id`, `current_tab`
- При изменении автоматически эмитит события через EventBus

**3. Services (assets/globals/services.gd)**
- Service Locator для доступа к бизнес-логике
- Доступ: `Services.tool.select_tool()`, `Services.layer.create_layer()`
- Все сервисы регистрируются при инициализации

**4. LayerService - система на int ID**
- **КРИТИЧНО**: Вся логика работает через уникальные int ID
- Имена слоёв - только UI labels для пользователя
- Пользователь может назвать 100 слоёв одинаково - логика не сломается
- Маппинг: `layer_id (int) -> layer_data (Dictionary)`
- Автоинкремент ID через `_next_layer_id` с пулом переиспользуемых ID

**5. History (autoload) - Godot-API undo/redo система**
- Работает на основе встроенного класса UndoRedo
- `max_steps = 77`
- Поддержка undo/redo для слоёв (create/delete/visibility)

## Система рисования

**DrawContainer (assets/draw_container.gd):**
- SubViewportContainer для canvas рисования
- Роутинг input событий к активному инструменту (глобальный и локальный)
- Преобразование координат мыши в пиксельные координаты холста
- Управление активным слоем через LayerService
- Cursor sprite visibility management

**CanvasRenderer (assets/canvas_renderer.gd):**
- Отрисовка overlay поверх холста через _draw()
- Pixel preview (квадратик-прицел для brush/fill)
- Selection gizmo (пунктирная рамка для selection tool)
- Selection pixels overlay (при перемещении выделения)
- Canvas border (рамка холста)
- Контрастный stroke для видимости на разных цветах

**Tool классы (core/tools/):**
- **BaseTool** - базовый класс с интерфейсом (`on_press`, `on_drag`, `on_release`, `on_hover`, `on_resize`, `should_draw_preview`)
- **BrushTool** - рисует пиксели с blend-ом, поддерживает квадратную и круглую форму
- **EraserTool** - стирает пиксели (`Color.TRANSPARENT`)
- **FillTool** - заливка области flood fill алгоритмом (contiguous/non-contiguous режимы)
- **SelectionTool** - выделение с state machine (IDLE → SELECTING → SELECTED → MOVING)
- Инструменты вызывают `layer.set_pixel()` напрямую
- Размер кисти и другие настройки хранятся в ToolService

**DrawLayer (assets/scripts/draw_layer.gd):**
- Extends TextureRect - визуальное отображение слоя
- Работает через `layer_id` (int), независим от UI Layer компонента
- Методы: `set_pixel()`, `get_pixel()`, `update_image()` для манипуляции изображением
- Встроенная поддержка undo/redo через History.undo_redo
- Создаётся через `CanvasService.create_draw_layer()`

## Функциональные системы

**Инструменты:**
- Кнопки инструментов (`tool_button.gd`) используют EventBus для уведомлений
- ToolService управляет экземплярами инструментов и их настройками
- Переключение инструмента меняет `active_tool` в ToolService
- **Настройки инструментов** хранятся в `tool_properties` Dictionary в ToolService
  - Каждый инструмент имеет свой набор настроек (size, shape, contiguous, etc.)
  - UI настроек синхронизируется через EventBus
- **Поддерживаемые инструменты:**
  - **Brush**: рисование с настройками размера и формы (квадрат/круг), blend colors
  - **Eraser**: стирание с настройкой размера
  - **Fill**: заливка с режимом contiguous (связанная область или весь цвет)
  - **Selection**: выделение прямоугольных областей с перемещением пикселей

**Цвета:**
- Swatch'и (`swatch.gd`) работают через ColorService и EventBus
- Корректный order: 0=primary, 1=secondary
- ColorPicker (`swatch_picker.gd`) синхронизируется с цветовой системой
- Swap colors (клавиша X) меняет местами primary/secondary
- **QuickTools** добавляет color picker (P) с preview overlay

**Слои:**
- LayersPanel (`assets/ui_components/layers/layers_panel.gd`) работает на int ID
- Drag-and-drop переупорядочивание с анимацией (lerp)
- Visibility toggle для всех слоёв одной кнопкой
- Маппинг UI Layer -> layer_id через метаданные
- Создание/удаление слоёв через LayerService с undo/redo

**Курсор:**
- CursorService управляет визуальным состоянием курсора
- CursorSprite (Sprite2D) создаётся динамически в UI CanvasLayer
- Override система: POINTER на UI hover, GRAB при drag камеры, DRAG при перемещении выделения
- Маппинг инструментов на иконки курсора (ARROW, POINTER, GRAB, DRAG)
- Скрытие курсора для brush/eraser/fill инструментов

**Камера:**
- CanvasCamera управляет зумом и панорамированием холста
- Поддерживает колесо мыши для зума и средняя кнопка для панорамирования
- Интегрирована с системой координат для корректного преобразования позиций мыши
- Clamping позиции камеры по границам холста

**UI Навигация:**
- **MainTabs** (assets/ui_components/main_tabs.gd) - Control для управления активной вкладкой
  - `active_tab: int` - текущая вкладка (0=Draw, 1=Animation, 2=Evo)
  - При изменении эмитит `active_tab_changed` сигнал
  - Обновляет `AppState.current_tab`
- **Tab** (assets/ui_components/tab.gd) - отдельная панель вкладки
  - Обрабатывает mouse input через `_gui_input`
  - При нажатии устанавливает `main_tabs.active_tab = _id`
  - Визуальные состояния: base, hover, pressed (с tween-анимацией)
- **UI** (assets/scripts/ui.gd) - CanvasLayer, обрабатывает видимость элементов
  - Подписывается на `EventBus.tab_changed`
  - Маппинг табов к группам: `{0: "Draw", 1: "Animation", 2: "Evo"}`
  - При смене таба показывает элементы соответствующей группы, скрывает остальные
  - UI элементы помещаются в группы "Draw", "Animation", "Evo" в app.tscn
- **DrawMenu** - меню для импорта/экспорта изображений
- **TreePanel** - панель дерева (пока пустая, для этапа 2)

---

## Временные тесты и сомнительные решения

> Ниже перечислены архитектурные решения, требующие пересмотра:

1. **TreeService (assets/services/tree_service.gd)**
   - ПУСТОЙ сервис - только регистрируется в Services

3. **cursor.gd.uid** в assets/globals/
   - Файл .uid существует, но соответствующий cursor.gd не найден
   - Вопрос: Очистить .uid файл или это остаток от удалённого кода?


---

## TODO: Очистка проекта

- [ ] Удалить cursor.gd.uid если файл не используется