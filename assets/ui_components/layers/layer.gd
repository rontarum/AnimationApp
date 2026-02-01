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
@onready var layer_visible: IconTriggerButton = $LayerMargin/LayerVisible

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	label.text_submitted.connect(_on_name_submitted)
	# layer_visible.toggled уже подключен в сцене
	EventBus.layer_all_visibility_changed.connect(_on_layer_all_visibility_changed)
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed)
	#layer_name = str("Layer")
	#label.text = layer_name

func set_preview(tex: Texture2D) -> void:
	preview.texture = tex

func set_active(val: bool) -> void:
	is_active = val
	current_color = pressed_color if val else common_color
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
			# Возвращаем правильный цвет после отпускания
			var target_color = active_color if is_active else common_color
			_animate_color(target_color)
			
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
	else:
		# Правильная архитектура: UI эмитит событие, не вызывает сервис напрямую
		var layer_id = get_meta("layer_id", -1)
		if layer_id != -1:
			layer_name = text
			EventBus.layer_rename_requested.emit(layer_id, text)
			name_changed.emit(self, text)
		else:
			push_error("[Layer] No layer_id found in metadata")
	
	label.apply_ime()
	label.release_focus()

func _on_layer_visible_toggled(toggled_on: bool) -> void:
	var layer_id = get_meta("layer_id", -1)
	if layer_id != -1:
		EventBus.layer_visibility_requested.emit(layer_id, toggled_on)
		
func _on_layer_all_visibility_changed(val: bool) -> void:
	layer_visible.set_pressed_no_signal(val)

func _on_layer_visibility_changed(layer_id: int, visible: bool) -> void:
	# Синхронизируем UI кнопку только для нашего слоя
	var my_layer_id = get_meta("layer_id", -1)
	if my_layer_id == layer_id:
		layer_visible.set_pressed_no_signal(visible)
