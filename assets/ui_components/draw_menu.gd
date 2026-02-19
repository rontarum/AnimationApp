class_name DrawMenu extends MenuButton
enum Ids {NEW, OPEN, SAVE, SAVE_AS, IMPORT, EXPORT_PNG, EXPORT_LAYERS_AS_PNG}

var popup: PopupMenu

func _ready() -> void:
	popup = get_popup()
	popup.index_pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed(id: int) -> void:
	match id:
		Ids.IMPORT:
			var import_image_dialog: FileDialog = %ImportImageDialog
			import_image_dialog.popup_file_dialog()
		Ids.EXPORT_PNG:
			var export_png_dialog: FileDialog = %ExportPNGDialog
			export_png_dialog.popup_file_dialog()
		Ids.EXPORT_LAYERS_AS_PNG:
			var export_layers_dialog: FileDialog = %ExportLayersDialog
			export_layers_dialog.popup_file_dialog()

func _on_export_png_dialog_file_selected(path: String) -> void:
	var canvas: CanvasService = Services.canvas
	canvas.save_canvas_image(path)


func _on_export_layers_dialog_dir_selected(dir: String) -> void:
	var canvas: CanvasService = Services.canvas
	canvas.save_layers_as_pngs(dir)


func _on_import_image_dialog_file_selected(path: String) -> void:
	var image: Image = Image.new()
	image.load(path)
	var canvas: CanvasService = Services.canvas
	canvas.import_image(image, path)
