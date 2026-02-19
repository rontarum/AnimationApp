# Project Save/Load — Задачи

## Файлы

- **Новые:** `assets/globals/project_manager.gd`, `assets/data/draw_layer_data.gd`, `assets/data/project_data.gd`
- **Изменяемые:** `assets/ui_components/draw_menu.gd`, `assets/services/canvas_service.gd`, `assets/services/layer_service.gd`, `app.tscn`

---

## 1. Создать Data Resources

- [-] 1.1 Создать `assets/data/draw_layer_data.gd` — Resource для данных слоя
- [x] 1.2 Создать `assets/data/project_data.gd` — Resource для данных проекта

---

## 2. Расширить CanvasService

- [x] 2.1 Добавить метод `get_all_layer_images() -> Dictionary` — возвращает {layer_id: PackedByteArray}
- [x] 2.2 Добавить метод `set_all_layer_images(images: Dictionary)` — устанавливает изображения для слоёв
- [x] 2.3 Добавить метод `clear_canvas()` — очищает все слои

---

## 3. Расширить LayerService

- [x] 3.1 Добавить метод `get_all_layers() -> Array[Dictionary]` — возвращает массив {id, name, visible}
- [x] 3.2 Добавить метод `clear_layers()` — удаляет все слои
- [x] 3.3 Добавить метод `restore_layers(layers: Array[Dictionary])` — восстанавливает слои из данных

---

## 4. Создать ProjectManager

- [-] 4.1 Создать `assets/globals/project_manager.gd` как autoload
- [x] 4.2 Реализовать сигналы: `project_saved`, `project_loaded`, `project_closed`, `auto_save_*`
- [x] 4.3 Реализовать `save_project(path: String) -> bool`
- [x] 4.4 Реализовать `load_project(path: String) -> bool`
- [x] 4.5 Реализовать `new_project(size: Vector2i)`
- [ ] 4.6 Реализовать `auto_save() -> bool`
- [x] 4.7 Реализовать `has_unsaved_changes() -> bool`
- [x] 4.8 Настроить таймер автосохранения (60 секунд)
- [x] 4.9 Зарегистрировать в autoload как "ProjectManager"

---

## 5. Обновить DrawMenu

- [x] 5.1 Добавить FileDialog `ProjectSaveDialog` в app.tscn
- [x] 5.2 Добавить FileDialog `ProjectOpenDialog` в app.tscn
- [x] 5.3 Создать кастомный `NewProjectDialog` (Control с полями Width/Height)
- [x] 5.4 Добавить обработчик `NEW` → показ NewProjectDialog
- [x] 5.5 Добавить обработчик `OPEN` → показ ProjectOpenDialog
- [x] 5.6 Добавить обработчик `SAVE` → вызов ProjectManager.auto_save()
- [x] 5.7 Добавить обработчик `SAVE_AS` → показ ProjectSaveDialog

---

## 6. Интегрировать автосохранение

- [ ] 6.1 Добавить вызов `ProjectManager.auto_save()` при переключении вкладки (AppState)
- [x] 6.2 Добавить action "save" в Input Map (если нет)
- [x] 6.3 Добавить обработку action "save" в AppState._input()

---

## 7. Тестирование

- [-] 7.1 Написать unit тесты для DrawLayerData
- [-] 7.2 Написать unit тесты для ProjectData
- [-] 7.3 Написать property-based тесты для save/load цикла
- [-] 7.4 Проверить вручную: сохранение, загрузка, новый проект
- [-] 7.5 Проверить автосохранение при переключении вкладки
- [x] 7.6 Проверить автосохранение по таймеру

---

## Готовность

- [ ] Все задачи выполнены
- [ ] Код проходит диагностику (без warnings)
- [ ] Тесты проходят