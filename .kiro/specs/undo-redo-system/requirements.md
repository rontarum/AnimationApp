# Requirements Document

## Introduction

Система Undo/Redo для редактора пиксельарта обеспечивает возможность отмены и повтора действий пользователя. Система должна поддерживать откат операций рисования (инструменты) и управления слоями, интегрируясь с существующей архитектурой EventBus + Services.

## Glossary

- **Command**: Объект, инкапсулирующий операцию с возможностью выполнения и отката
- **UndoRedoService**: Сервис управления стеком команд и их выполнением
- **CommandStack**: Стек команд для отслеживания истории операций
- **ToolCommand**: Команда для операций инструментов рисования
- **LayerCommand**: Команда для операций со слоями
- **EventBus**: Система событий для коммуникации между компонентами
- **LayerService**: Сервис управления слоями через int ID

## Requirements

### Requirement 1: Command Pattern Implementation

**User Story:** Как разработчик, я хочу реализовать Command Pattern, чтобы инкапсулировать все операции с возможностью отката.

#### Acceptance Criteria

1. THE UndoRedoService SHALL implement Command Pattern для всех операций
2. WHEN операция выполняется, THE System SHALL создать Command объект с данными для отката
3. THE Command SHALL содержать методы execute() и undo() для выполнения и отката
4. THE Command SHALL сохранять все необходимые данные для корректного отката операции

### Requirement 2: Tool Operations Undo/Redo

**User Story:** Как пользователь, я хочу отменять и повторять операции рисования, чтобы исправлять ошибки и экспериментировать.

#### Acceptance Criteria

1. WHEN пользователь рисует кистью, THE System SHALL создать BrushCommand с данными изменённых пикселей
2. WHEN пользователь стирает, THE System SHALL создать EraseCommand с данными стёртых пикселей  
3. WHEN пользователь заливает область, THE System SHALL создать FillCommand с данными заливки
4. WHEN пользователь выделяет и перемещает область, THE System SHALL создать SelectionMoveCommand
5. WHEN пользователь нажимает action "undo", THE System SHALL выполнить undo последней команды
6. WHEN пользователь нажимает action "redo", THE System SHALL выполнить redo отменённой команды

### Requirement 3: Layer Operations Undo/Redo

**User Story:** Как пользователь, я хочу отменять операции со слоями, чтобы управлять структурой проекта.

#### Acceptance Criteria

1. WHEN пользователь создаёт слой, THE System SHALL создать CreateLayerCommand
2. WHEN пользователь удаляет слой, THE System SHALL создать DeleteLayerCommand с сохранением данных слоя
3. WHEN пользователь изменяет видимость слоя, THE System SHALL создать LayerVisibilityCommand
4. WHEN пользователь перемещает слой в списке, THE System SHALL создать MoveLayerCommand
5. WHEN пользователь очищает слой в списке, THE System SHALL создать ClearLayerCommand
6. THE System SHALL корректно восстанавливать состояние слоёв при undo/redo операций

### Requirement 4: Command Stack Management

**User Story:** Как система, я должна управлять стеком команд для обеспечения корректной работы undo/redo.

#### Acceptance Criteria

1. THE UndoRedoService SHALL поддерживать стек undo команд ограниченного размера
2. THE UndoRedoService SHALL поддерживать стек redo команд
3. WHEN новая команда добавляется, THE System SHALL очищать redo стек
4. WHEN стек undo достигает лимита, THE System SHALL удалять самые старые команды
5. THE System SHALL предоставлять информацию о доступности undo/redo операций

### Requirement 5: EventBus Integration

**User Story:** Как система, я должна интегрироваться с EventBus для уведомления о состоянии undo/redo.

#### Acceptance Criteria

1. WHEN состояние undo/redo изменяется, THE UndoRedoService SHALL эмитить события через EventBus
2. THE System SHALL эмитить 'undo_availability_changed' при изменении доступности undo
3. THE System SHALL эмитить 'redo_availability_changed' при изменении доступности redo
4. THE System SHALL эмитить 'command_executed' при выполнении команды
5. THE System SHALL эмитить 'command_undone' при отмене команды

### Requirement 6: Keyboard Shortcuts

**User Story:** Как пользователь, я хочу использовать стандартные горячие клавиши для undo/redo.

#### Acceptance Criteria

1. WHEN пользователь нажимает Ctrl+Z, THE System SHALL выполнить undo операцию
2. WHEN пользователь нажимает Ctrl+Y или Ctrl+Shift+Z, THE System SHALL выполнить redo операцию
3. THE System SHALL игнорировать горячие клавиши когда undo/redo недоступны
4. THE System SHALL корректно обрабатывать горячие клавиши в любом UI контексте

### Requirement 7: Memory Management

**User Story:** Как система, я должна эффективно управлять памятью при хранении команд.

#### Acceptance Criteria

1. THE UndoRedoService SHALL ограничивать размер стека команд (по умолчанию 50 команд)
2. THE System SHALL освобождать память при удалении старых команд из стека
3. THE Command SHALL хранить только минимально необходимые данные для отката
4. THE System SHALL оптимизировать хранение данных пикселей (сжатие одинаковых областей)

### Requirement 8: State Consistency

**User Story:** Как система, я должна поддерживать консистентность состояния при undo/redo операциях.

#### Acceptance Criteria

1. WHEN выполняется undo операции, THE System SHALL корректно восстанавливать предыдущее состояние
2. WHEN выполняется redo операции, THE System SHALL корректно восстанавливать отменённое состояние  
3. THE System SHALL синхронизировать UI с состоянием после undo/redo
4. THE System SHALL обновлять AppState при изменении активного слоя через undo/redo
5. THE System SHALL корректно обрабатывать undo/redo при удалённых слоях