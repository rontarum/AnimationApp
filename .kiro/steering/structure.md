---
inclusion: manual
---

# Фактическая файловая структура проекта (где что находится)

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
│   └── tree_service.gd     # Сервис для дерева (для этапа 2)
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
│   │   ├── cursor_sprite.gd # Визуальный курсор (Sprite2D)
│   │   └── ui.gd           # CanvasLayer для управления видимостью UI групп
│   ├── ui_components/      # UI компоненты
│   │   ├── layers/         # Панель слоёв (layers_panel.gd)
│   │   ├── tree/           # Компоненты дерева (tree.gd, tree_panel.gd, leaf.gd)
│   │   ├── draw_menu.gd    # Меню файловых операций
│   │   ├── main_tabs.gd    # Переключение вкладок (Draw/Life/Evo)
│   │   ├── tab.gd          # Отдельная вкладка с визуальными состояниями
│   │   └── tool_properties/ # Панель настроек инструментов
│   │       ├── properties_panel.gd  # Загрузка UI настроек инструментов
│   │       ├── brush_properties.gd/tscn  # Настройки кисти
│   │       ├── fill_properties.gd/tscn   # Настройки заливки
│   │       └── mesh_properties.gd/tscn   # Настройки mesh инструмента (Life)
│   ├── tool_button.gd      # Кнопки инструм��нтов
│   ├── swatch.gd           # Цветовые образцы
│   ├── swatch_picker.gd    # ColorPicker для свотчей
│   └── window_panel.gd     # Базовый класс для панелей окон
│
├── assets/data/            # Ресурсы данных
│   └── project.gd          # Project Resource (данные проекта)
│
├── assets/icons/           # Иконки
│   ├── tools/
│   │   ├── draw/          # Иконки инструментов рисования
│   │   └── life/          # Иконки Life инструментов (mesh_tool, bud_tool, stick_tool)
│   ├── buttons/           # Иконки кнопок UI
│   ├── controls/          # Иконки контролов
│   └── cursor/            # Иконки курсора
│
└── app.tscn / app.gd       # Главная сцена - инициализация сервисов
```