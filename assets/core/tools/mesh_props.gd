class_name MeshProps extends Resource

## Resource для хранения свойств инструмента Mesh
## Использует сигналы для запроса операций и уведомления об изменениях

signal create_polygon_requested()
signal make_mesh_requested()
signal clear_vertices_requested()
signal vertex_count_changed(count: int)

var vertex_count: int = 0:
	set(value):
		vertex_count = value
		vertex_count_changed.emit(vertex_count)

## Методы для запроса операций
func request_create_polygon() -> void:
	create_polygon_requested.emit()

func request_make_mesh() -> void:
	make_mesh_requested.emit()

func request_clear_vertices() -> void:
	clear_vertices_requested.emit()
