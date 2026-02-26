class_name FillProps extends Resource

## Resource для хранения свойств заливки
## Использует сигналы для уведомления об изменениях

signal contiguous_changed(new_contiguous: bool)

var _contiguous: bool = true

@export var contiguous: bool = true:
	set(value):
		if _contiguous != value:
			_contiguous = value
			contiguous_changed.emit(_contiguous)
	get:
		return _contiguous
