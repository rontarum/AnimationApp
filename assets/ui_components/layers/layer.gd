class_name Layer extends ColorRect

signal clicked(layer: Layer)
signal drag_started(layer: Layer, mouse_pos: Vector2)
signal drag_ended(layer: Layer)
signal name_changed(layer: Layer, new_name: String)

signal moved
signal activity_changed(value: bool)


@export var common_color: Color = Color("f6efef")
@export var active_color: Color = Color("f3e8e8ff")
@export var pressed_color: Color = Color("efdfdf")


var layer_name: String
var layer_texture: ImageTexture

var is_active: bool = false

@onready var preview: TextureRect = $LayerMargin/LayerHbox/LayerPreview
@onready var label: LineEdit = $LayerMargin/LayerHbox/LayerLabel
@onready var current_color: Color = common_color

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	label.text_submitted.connect(_on_name_submitted)
	
	#layer_name = str("Layer")
	#label.text = layer_name

func set_preview(tex: Texture2D) -> void:
	preview.texture = tex

func set_active(val: bool) -> void:
	is_active = val
	current_color = active_color if val else common_color
	_animate_color(current_color)
	activity_changed.emit(is_active)

func rename(new_name: String) -> void:
	label.text = new_name
	name = new_name


func _on_mouse_entered() -> void:
	if not is_active:
		_animate_color(active_color)

func _on_mouse_exited() -> void:
	if not is_active:
		_animate_color(current_color)

func _gui_input(event: InputEvent) -> void:
	if event.is_action("action"):
		if event.is_pressed():
			clicked.emit(self)
			drag_started.emit(self, get_global_mouse_position())
			_animate_color(pressed_color)
		elif event.is_released():
			drag_ended.emit(self)
			_animate_color(current_color)
			
	if event.is_action("cancel"):
		label.edit()
		label.select_all()

func _animate_color(to: Color) -> void:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "color", to, 0.12)

func _on_name_submitted(text: String) -> void:
	if text == "":
		label.text = layer_name
	label.apply_ime()
	label.release_focus()
	name_changed.emit(self, label.text)
