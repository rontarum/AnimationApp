class_name CreateLayerCommand
extends LayerCommand

## Команда создания нового слоя

var layer_name: String
var created_layer_id: int = -1
var previous_active_layer_id: int = -1

func _init(name: String) -> void:
	super._init(-1)  # ID будет назначен при создании
	layer_name = name
	description = "Create layer: " + layer_name

func execute() -> void:
	print("[CreateLayerCommand] Execute: ", description)
	
	# Сохраняем предыдущий активный слой
	previous_active_layer_id = AppState.active_layer_id
	
	# Создаём слой через сервис
	created_layer_id = layer_service.create_layer(layer_name)
	layer_id = created_layer_id
	
	print("[CreateLayerCommand] Created layer with ID: ", created_layer_id)

func undo() -> void:
	print("[CreateLayerCommand] Undo: ", description)
	
	if not _layer_exists(created_layer_id):
		push_error("[CreateLayerCommand] Layer to delete not found: " + str(created_layer_id))
		return
	
	# Удаляем созданный слой
	layer_service.delete_layer(created_layer_id)
	
	# Восстанавливаем предыдущий активный слой
	if previous_active_layer_id != -1 and _layer_exists(previous_active_layer_id):
		layer_service.select_layer(previous_active_layer_id)
	else:
		layer_service.select_layer(-1)  # Нет активного слоя