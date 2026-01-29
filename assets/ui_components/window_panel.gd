class_name WindowPanel extends Panel



func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_exit_button_mouse_entered() -> void:
	Services.cursor.set_override(ToolType.Type.POINTER)

func _on_exit_button_mouse_exited() -> void:
	Services.cursor.clear_override()
