class_name BaseCommand
extends RefCounted

## Базовый класс для всех команд в системе Undo/Redo
## Реализует Command Pattern с методами execute() и undo()
##
## Команды - это чистая логика (RefCounted), без зависимостей от Node.
## Они инкапсулируют операции с возможностью отката.

# Описание команды для отладки и UI
var description: String = ""

# Временная метка создания команды
var timestamp: float = 0.0

func _init() -> void:
	timestamp = Time.get_ticks_msec() / 1000.0

## Выполнить команду
## Должен быть переопределён в наследниках
func execute() -> void:
	assert(false, "execute() must be implemented in " + get_script().get_global_name())

## Отменить команду
## Должен быть переопределён в наследниках  
func undo() -> void:
	assert(false, "undo() must be implemented in " + get_script().get_global_name())

## Возвращает приблизительный размер команды в байтах для оптимизации памяти
## Переопределяется в наследниках для точного подсчёта
func get_memory_usage() -> int:
	# Базовый размер: описание + timestamp
	var base_size = description.length() * 4 + 8  # String UTF-8 + float64
	return base_size

## Проверяет, можно ли выполнить команду
## Переопределяется в наследниках для специфических проверок
func can_execute() -> bool:
	return true

## Проверяет, можно ли отменить команду
## Переопределяется в наследниках для специфических проверок
func can_undo() -> bool:
	return true