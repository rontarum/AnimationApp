class_name Tab extends Panel

signal tab_hovered(id: int)
signal tab_unhovered(id: int)
signal tap_pressed(id: int)

var base_color: Color = Color("f6efef")
var hover_color: Color = Color("e5e0e4")
var pressed_color: Color = Color("000000")

var font_base_color: Color = Color("454b73")
var font_pressed_color: Color = Color("ffffff")

var _id: int

var tween: Tween

@onready var main_tabs: MainTabs = get_parent()
@onready var label: Label = get_child(0)

func _ready() -> void:
	_id = get_index()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	main_tabs.active_tab_changed.connect(_on_active_tab_changed)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		if _id != main_tabs.active_tab:
			main_tabs.active_tab = _id
			

func _on_mouse_entered() -> void:
	if _id != main_tabs.active_tab:
		Services.cursor.set_override(ToolType.Type.POINTER)
		tween = _create_tween()
		tween.tween_property(self, "self_modulate", hover_color, 0.07)

func _on_mouse_exited() -> void:
	Services.cursor.set_override(ToolType.Type.ARROW)
	if _id != main_tabs.active_tab:
		tween = _create_tween()
		tween.tween_property(self, "self_modulate", Color.WHITE, 0.07)

func _on_active_tab_changed(id: int) -> void:
	Services.cursor.set_override(ToolType.Type.ARROW)
	if id != _id:
		tween = _create_tween()
		tween.tween_property(self, "self_modulate", Color.WHITE, 0.1)
		tween.tween_property(label, "theme_override_colors/font_color", font_base_color, 0.21)
	else:
		self_modulate = pressed_color
		tween = _create_tween()
		tween.tween_property(label, "theme_override_colors/font_color", font_pressed_color, 0.21)

func _create_tween() -> Tween:
	if tween:
		if tween.is_running():
			tween.stop()
		tween.kill()
	tween = create_tween()
	return tween
	
