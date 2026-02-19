class_name DrawMenu extends MenuButton
enum Ids {NEW, OPEN, SAVE, SAVE_AS, IMPORT, EXPORT_PNG, EXPORT_LAYERS_AS_PNG}

var popup: PopupMenu

func _ready() -> void:
	popup = get_popup()
	popup.index_pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed(id: int) -> void:
	match id:
		Ids.NEW:
			_show_new_project_dialog()
		Ids.OPEN:
			var open_dialog: FileDialog = %ProjectOpenDialog
			open_dialog.popup_file_dialog()
		Ids.SAVE:
			# Если проект ещё не сохранён, показываем Save As
			if ProjectManager.current_project_path == "":
				var save_dialog: FileDialog = %ProjectSaveDialog
				save_dialog.popup_file_dialog()
			else:
				ProjectManager.auto_save()
		Ids.SAVE_AS:
			var save_dialog: FileDialog = %ProjectSaveDialog
			save_dialog.popup_file_dialog()
		Ids.IMPORT:
			var import_image_dialog: FileDialog = %ImportImageDialog
			import_image_dialog.popup_file_dialog()
		Ids.EXPORT_PNG:
			var export_png_dialog: FileDialog = %ExportPNGDialog
			export_png_dialog.popup_file_dialog()
		Ids.EXPORT_LAYERS_AS_PNG:
			var export_layers_dialog: FileDialog = %ExportLayersDialog
			export_layers_dialog.popup_file_dialog()

func _show_new_project_dialog() -> void:
	var dialog: NewProjectDialog = %NewProjectDialog
	dialog.popup_centered()

func _on_new_project_dialog_confirmed() -> void:
	var dialog: NewProjectDialog = %NewProjectDialog
	var width: int = int(dialog.width_spin.value)
	var height: int = int(dialog.height_spin.value)
	ProjectManager.new_project(Vector2i(width, height))

func _on_project_save_dialog_file_selected(path: String) -> void:
	ProjectManager.save_project(path)

func _on_project_open_dialog_file_selected(path: String) -> void:
	ProjectManager.load_project(path)

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
