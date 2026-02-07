class_name DrawMenu extends MenuButton
enum Ids {NEW, OPEN, SAVE, SAVE_AS, IMPORT, EXPORT_PNG, EXPORT_LAYERS_AS_PNG}

var popup: PopupMenu

func _ready() -> void:
	popup = get_popup()
	popup.index_pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed(id: int) -> void:
	match id:
		Ids.EXPORT_PNG:
			var canvas: CanvasService = Services.canvas
			canvas.save_canvas_image()
		Ids.EXPORT_LAYERS_AS_PNG:
			var canvas: CanvasService = Services.canvas
			canvas.save_layers_as_pngs()
