class_name EraserProps extends Resource

## Resource для хранения свойств ластика
## Использует сигналы для уведомления об изменениях

signal size_changed(new_size: int)

var _size: int = 1

@export var size: int = 1:
	set(value):
		var clamped = clamp(value, 1, 10)
		if _size != clamped:
			_size = clamped
			size_changed.emit(_size)
	get:
		return _size
