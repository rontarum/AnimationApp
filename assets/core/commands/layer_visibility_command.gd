class_name LayerVisibilityCommand
extends LayerCommand

## Команда изменения видимости слоя

var previous_visibility: bool
var new_visibility: bool

func _init(target_layer_id: int, visible: bool) -> void:
	super._init(target_layer_id)
	new_visibility = visible
	
	var layer_data = _get_layer_data(layer_id)
	previous_visibility = layer_data.get("visible", true)
	
	var layer_name = layer_data.get("name", "Unknown")
	var action = "Show" if visible else "Hide"
	description = action + " layer: " + layer_name

func execute() -> void:
	print("[LayerVisibilityCommand] Execute: ", description)
	
	if not _layer_exists(layer_id):
		push_error("[LayerVisibilityCommand] Layer not found: " + str(layer_id))
		return
	
	layer_service.set_layer_visibility(layer_id, new_visibility)

func undo() -> void:
	print("[LayerVisibilityCommand] Undo: ", description)
	
	if not _layer_exists(layer_id):
		push_error("[LayerVisibilityCommand] Layer not found: " + str(layer_id))
		return
	
	layer_service.set_layer_visibility(layer_id, previous_visibility)