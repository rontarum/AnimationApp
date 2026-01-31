## EventBus - Централизованная шина событий
## 
## Используется для слабосвязанной коммуникации между компонентами.
## Компоненты эмитят события, другие подписываются на них.
##
## Пример использования:
##   EventBus.tool_selected.emit(ToolType.Type.BRUSH)
##   EventBus.tool_selected.connect(_on_tool_selected)

extends Node

# === TOOL EVENTS ===
signal tool_selected(tool_type: ToolType.Type)  # Выбран инструмент
signal tool_resized(size: float)
signal tool_property_changed(tool_type: ToolType.Type, property: String, value)  # Изменено свойство инструмента

# === LAYER EVENTS ===
signal layer_created(layer_id: int)  # Создан новый слой
signal layer_deleted(layer_id: int)  # Удалён слой
signal layer_selected(layer_id: int)  # Выбран активный слой
signal layer_reordered(from_index: int, to_index: int)  # Изменён порядок слоёв
signal layer_cleared(layer_id: int) # Слой очищен
signal layer_visibility_changed(layer_id: int, visible: bool)  # Видимость слоя
signal layer_all_visibility_changed(visible: bool) # Обратный сигнал для UI
signal layer_renamed(layer_id: int, new_name: String)  # Переименован слой
signal layer_rename_requested(layer_id: int, new_name: String)  # UI запрос переименования
signal layer_create_requested(layer_name: String)  # UI запрос создания
signal layer_delete_requested(layer_id: int)  # UI запрос удаления
signal layer_clear_requested(layer_id: int) # UI запрос очистки
signal layer_visibility_requested(layer_id: int, visible: bool)

# === CANVAS EVENTS ===
signal canvas_resized(new_size: Vector2i)  # Изменён размер холста

# === COLOR EVENTS ===
signal primary_color_changed(color: Color)  # Изменён основной цвет
signal secondary_color_changed(color: Color)  # Изменён вторичный цвет
signal color_picked(color: Color)  # Цвет взят пипеткой

# === CAMERA EVENTS ===
signal camera_zoom_changed(zoom: Vector2)  # Изменён зум камеры
signal camera_position_changed(position: Vector2)  # Изменена позиция камеры

# === UI EVENTS ===
signal ui_element_focused(element: Node)  # UI элемент получил фокус
signal ui_element_hovered(element: Node, hovered: bool)  # Наведение на UI элемент

# === HISTORY EVENTS ===
signal undo_requested()  # Запрошена отмена
signal redo_requested()  # Запрошен повтор
signal command_executed(description: String)  # Команда выполнена
signal command_undone(description: String)  # Команда отменена
signal undo_availability_changed(available: bool)  # Доступность undo изменилась
signal redo_availability_changed(available: bool)  # Доступность redo изменилась

# === SYSTEM EVENTS ===
signal app_ready()  # Приложение готово
signal app_closing()  # Приложение закрывается
