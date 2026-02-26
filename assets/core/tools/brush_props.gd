class_name BrushProps extends Resource

## Resource для хранения свойств кисти
## Использует сигналы для уведомления об изменениях

signal size_changed(new_size: int)
signal shape_changed(new_shape: int)

var _size: int = 1
var _shape: int = 0

@export var size: int = 1:
	set(value):
		var clamped = clamp(value, 1, 10)
		if _size != clamped:
			_size = clamped
			size_changed.emit(_size)
	get:
		return _size

@export var shape: int = 0:  # 0=square, 1=circle
	set(value):
		if _shape != value:
			_shape = value
			shape_changed.emit(_shape)
	get:
		return _shape
