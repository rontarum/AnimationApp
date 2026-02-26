Изучил Known Architectural Risks детально. Вижу более серьёзную картину:

Критический анализ рисков
🔴 Критичные (блокируют развитие):
Tool property management - словари вместо типов, MeshProperties → MeshTool коммуникация сломана
SpriteMesh в tests/ - нарушает структуру, будет проблема при расширении
LifeService минимальная - заглушка, нужна полноценная реализация для Life режима
🟡 Средние (усложняют поддержку):
CanvasService mixed responsibilities - рисование + file I/O в одном месте
Layer ordering в UI - должно быть в LayerService
File dialogs scattered - разбросаны по DrawMenu
🟢 Низкие (технический долг):
Services locator antipattern - сложно тестировать
EventBus много сигналов - сложно трассировать
AppState implicit setters - неочевидное поведение
Пересмотренная рекомендация
Сначала исправить критичные риски, потом роадмап.

Почему:

Роадмап требует MeshTool функциональность, но коммуникация MeshProperties → MeshTool сломана
SpriteMesh в tests/ будет мешать при добавлении новых Life компонентов
LifeService заглушка не даст реализовать TreePanel синхронизацию
Предлагаемый план рефакторинга:

Этап 1: Tool Props System (решает 🔴#1)
Ресурсы Props
Создать типизированные классы для tool properties вместо словарей
Реализовать паттерн коммуникации Properties → Tool через EventBus/сигналы
Применить к BrushProperties, FillProperties, MeshProperties
Этап 2: Структура Life компонентов (решает 🔴#2, 🔴#3)
Переместить SpriteMesh в assets/life/
Расширить LifeService для управления SpriteMesh и Life логикой
Создать базу для Life инструментов
Этап 3: Service responsibilities (решает 🟡#4, 🟡#5, 🟡#6)
Разделить CanvasService на CanvasService + FileService
Переместить layer ordering в LayerService
Централизовать file dialogs
После этого роадмап пойдёт гораздо легче.