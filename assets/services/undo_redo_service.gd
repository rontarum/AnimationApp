class_name UndoRedoService
extends Node

## Сервис управления командами Undo/Redo
## Реализует Command Pattern с ограниченными стеками команд
##
## Интегрируется с EventBus для уведомлений о состоянии

# Стеки команд
var undo_stack: Array[BaseCommand] = []
var redo_stack: Array[BaseCommand] = []

# Настройки
var max_history_size: int = 50
var is_recording: bool = true

# Статистика для отладки
var total_memory_usage: int = 0

func _ready() -> void:
	# Регистрируем сервис
	Services.register("undo_redo", self)

## Выполнить команду и добавить в стек undo
func execute_command(command: BaseCommand) -> void:
	if not is_recording:
		return
	
	if not command.can_execute():
		return
	
	# Выполняем команду
	command.execute()
	
	# Добавляем в undo стек
	undo_stack.push_back(command)
	
	# Очищаем redo стек при новой команде
	_clear_redo_stack()
	
	# Проверяем лимит размера стека
	_enforce_stack_limit()
	
	# Обновляем статистику памяти
	_update_memory_usage()
	
	# Уведомляем через EventBus
	EventBus.command_executed.emit(command.description)
	_emit_availability_changed()

## Отменить последнюю команду
func undo() -> void:
	if not can_undo():
		return
	
	var command = undo_stack.pop_back()
	
	if not command.can_undo():
		# Возвращаем команду обратно в стек
		undo_stack.push_back(command)
		return
	
	# Отменяем команду
	command.undo()
	
	# Добавляем в redo стек
	redo_stack.push_back(command)
	
	# Обновляем статистику памяти
	_update_memory_usage()
	
	# Уведомляем через EventBus
	EventBus.command_undone.emit(command.description)
	_emit_availability_changed()

## Повторить отменённую команду
func redo() -> void:
	print("UndoRedoService: redo() called, can_redo=", can_redo(), ", redo_stack.size=", redo_stack.size())
	
	if not can_redo():
		print("UndoRedoService: Cannot redo - stack is empty")
		return
	
	var command = redo_stack.pop_back()
	print("UndoRedoService: Attempting to redo command: ", command.description)
	
	if not command.can_execute():
		print("UndoRedoService: Command cannot be re-executed: ", command.description)
		# Возвращаем команду обратно в стек
		redo_stack.push_back(command)
		return
	
	# Выполняем команду повторно
	command.execute()
	print("UndoRedoService: Successfully redone command: ", command.description)
	
	# Добавляем обратно в undo стек
	undo_stack.push_back(command)
	
	# Обновляем статистику памяти
	_update_memory_usage()
	
	# Уведомляем через EventBus
	EventBus.command_executed.emit(command.description)
	_emit_availability_changed()

## Проверить доступность undo
func can_undo() -> bool:
	return undo_stack.size() > 0

## Проверить доступность redo
func can_redo() -> bool:
	return redo_stack.size() > 0

## Очистить всю историю команд
func clear_history() -> void:
	undo_stack.clear()
	redo_stack.clear()
	total_memory_usage = 0
	_emit_availability_changed()

## Начать запись команд
func start_recording() -> void:
	is_recording = true

## Остановить запись команд
func stop_recording() -> void:
	is_recording = false

## Получить информацию о состоянии стеков
func get_stack_info() -> Dictionary:
	return {
		"undo_count": undo_stack.size(),
		"redo_count": redo_stack.size(),
		"memory_usage": total_memory_usage,
		"max_size": max_history_size,
		"is_recording": is_recording
	}

# === PRIVATE METHODS ===

## Очистить redo стек
func _clear_redo_stack() -> void:
	if redo_stack.size() > 0:
		redo_stack.clear()

## Обеспечить лимит размера стека
func _enforce_stack_limit() -> void:
	while undo_stack.size() > max_history_size:
		var removed_command = undo_stack.pop_front()

## Обновить подсчёт использования памяти
func _update_memory_usage() -> void:
	total_memory_usage = 0
	
	for command in undo_stack:
		total_memory_usage += command.get_memory_usage()
	
	for command in redo_stack:
		total_memory_usage += command.get_memory_usage()

## Уведомить об изменении доступности undo/redo
func _emit_availability_changed() -> void:
	EventBus.undo_availability_changed.emit(can_undo())
	EventBus.redo_availability_changed.emit(can_redo())
