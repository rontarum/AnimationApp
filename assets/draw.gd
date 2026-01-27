class_name Draw
extends Node2D

enum {PENCIL, ERASER}

@export var canvas_texture: TextureRect
@export var viewport: SubViewportContainer
var state: int = PENCIL

var canvas: Image
var image_texture: ImageTexture
var mouse_pos: Vector2

var picker_pos: Vector2
var swatch: Color

static var instance: Draw

@onready var draw_canvas: SubViewport = $"../VPContainer/Layer0"

signal canvas_changed
signal state_changed

func _init() -> void:
	instance = self

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	
	canvas = Image.create_empty(DrawViewport.canvas_size.x, DrawViewport.canvas_size.y, 0, Image.FORMAT_RGBA8)
	
	var canv := draw_canvas.get_texture().get_image()
	canvas.copy_from(canv)
	
	image_texture = ImageTexture.create_from_image(canvas)
	canvas_texture.texture = image_texture
	canvas_changed.connect(update)
	
	DrawViewport.image_copied.emit()
	
	state_changed.connect(on_state_change)

func _process(delta: float) -> void:
	mouse_pos = viewport.get_local_mouse_position()
	canvas_texture.material.set_shader_parameter("mouse_pos", mouse_pos)
	
	
	if Input.is_action_pressed("picker"):
		color_pick()
	
	if Input.is_action_pressed("action"):
		match_state()
	
	if Input.is_key_label_pressed(KEY_ALT):
		canvas_texture.material.set_shader_parameter("is_picking", true)
	else:
		canvas_texture.material.set_shader_parameter("is_picking", false)

func match_state() -> void:
	match state:
		PENCIL:
			canvas.set_pixelv(mouse_pos, swatch)
			canvas_changed.emit()
		ERASER:
			canvas.set_pixelv(mouse_pos, Color(Color.WHITE, 0.0))
			canvas_changed.emit()
			

func color_pick() -> void:
	picker_pos = get_viewport().get_mouse_position() * get_viewport().get_final_transform()
	var screen_image: Image = get_viewport().get_texture().get_image()
	swatch = screen_image.get_pixelv(picker_pos)
	canvas_texture.material.set_shader_parameter("swatch", swatch)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pencil"):
		state = PENCIL
		state_changed.emit()
	if event.is_action_pressed("eraser"):
		state = ERASER
		state_changed.emit()

func update() -> void:
	image_texture.update(canvas)

func on_state_change() -> void:
	canvas_texture.material.set_shader_parameter("state", state)
