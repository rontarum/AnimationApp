class_name IconTriggerButton extends CheckBox

@export var hover_color: Color = Color(3.299, 1.667, 1.519, 1.0)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	modulate = hover_color

func _on_mouse_exited() -> void:
	modulate = Color.WHITE
