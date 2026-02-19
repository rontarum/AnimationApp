class_name NewProjectDialog
extends Window

signal confirmed()

@onready var width_spin: SpinBox = $WidthSpin
@onready var height_spin: SpinBox = $HeightSpin

func _ready() -> void:
	# Connect Create button to emit confirmed with values
	$CreateButton.pressed.connect(_on_create_pressed)

func _on_create_pressed() -> void:
	hide()
	# Emit custom signal with values - DrawMenu will connect to this
	# For now, we store values for DrawMenu to read
	get_tree().root.set_meta("new_project_width", width_spin.value)
	get_tree().root.set_meta("new_project_height", height_spin.value)
	confirmed.emit()
