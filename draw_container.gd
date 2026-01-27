class_name DrawContainer
extends SubViewportContainer

@export var canvas_size: Vector2i = Vector2i(32, 32)
@onready var draw_canvas: SubViewport = $DrawCanvas

static var instance: DrawContainer

var mouse_pos: Vector2
var slide_pos: Vector2

var active_layer: Node
var is_hold: bool = false

var selection_rect: Rect2
var selection_start: Vector2
var selection_start_draw: Vector2
var selection_end_draw: Vector2

func _init() -> void:
	instance = self

func _ready() -> void:
	size = canvas_size
	Globals.image_copied.connect(_clear)
	
	# Новая архитектура: подписка на события слоев через EventBus
	EventBus.layer_selected.connect(_on_layer_selected)
	
	queue_redraw()

func _process(delta: float) -> void:
	mouse_pos = get_local_mouse_position()
	slide_pos = lerp(slide_pos, floor(mouse_pos), 36.9 * delta)
	
	if is_hold and active_layer:
		if Cursor.mode != Util.ToolType.BRUSH and Cursor.mode != Util.ToolType.ERASER:
			return
		if mouse_pos.x < 0.0 or mouse_pos.y < 0.0 or mouse_pos.x >= size.x or mouse_pos.y >= size.y: 
			return
		
		match Cursor.mode:
			Util.ToolType.BRUSH:
				active_layer.set_pixel(floor(mouse_pos), Cursor.primary_swatch)
			Util.ToolType.ERASER:
				active_layer.set_pixel(floor(mouse_pos), Color.TRANSPARENT)
	queue_redraw()

func create_draw_layer(layer: Layer) -> void:
	var draw_layer := DrawLayer.new(canvas_size, layer)
	draw_canvas.add_child(draw_layer, true)
	draw_layer.name = "DrawLayer" + str(draw_layer.get_index())

func _clear() -> void:
	for c in draw_canvas.get_children():
		if c is TextureRect: continue
		c.queue_free()

func _draw() -> void:
	_draw_square()
	_draw_selection()
	
	draw_rect(Rect2(get_rect()), Color("454b7386"), false)

func _draw_square() -> void:
	if Cursor.mode != Util.ToolType.BRUSH and Cursor.mode != Util.ToolType.ERASER:
		return
	if mouse_pos.x < 0.0 or mouse_pos.y < 0.0 or mouse_pos.x >= size.x or mouse_pos.y >= size.y: 
		return
	
	var rect: Rect2 = Rect2()
	rect.position = slide_pos
	rect.end = slide_pos + Vector2(1, 1)
	
	var pixel: Color = draw_canvas.get_texture().get_image().get_pixelv(floor(mouse_pos))
	var color: Color = Cursor.primary_swatch
	var stroke: Color = Color(Color.WHITE - pixel, 1.0) if pixel.a > 0.0 else Color.BLACK
	if color.a > 0:
		stroke = Color(Color.WHITE - color, 1.0) if color.a > 0.0 else Color.BLACK
	
	if Cursor.mode == Util.ToolType.BRUSH:
			draw_rect(rect, color, true)
	
	draw_rect(rect, stroke, false)
	if CanvasCamera.instance.zoom_value.x >= 8.0:
		draw_rect(Rect2(mouse_pos - Vector2(0.04, 0.04), Vector2(0.08, 0.08)), stroke, false, -1.0)

func _draw_selection() -> void:
	if Cursor.mode != Util.ToolType.SELECTION:
		return
	if mouse_pos.x < 0.0 or mouse_pos.y < 0.0 or mouse_pos.x >= size.x or mouse_pos.y >= size.y: 
		return
	
	var pixel: Color = draw_canvas.get_texture().get_image().get_pixelv(floor(mouse_pos))
	var stroke: Color = Color(Color.WHITE - pixel, 1.0) if pixel.a > 0.0 else Color.BLACK
	
	draw_rect(selection_rect, stroke, false, 1.0)
	#draw_rect(selection_rect, Color(0.0, 0.0, 0.0, 0.514), false)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
			if not active_layer: 
				return
			is_hold = true
			selection_start = event.position
			
	if event.is_action_released("action"):
		is_hold = false
			
	if is_hold and event is InputEventMouseMotion:
		
		var selection_end: Vector2 = event.position
		var diff := selection_end - selection_start
		
		selection_start_draw = selection_start_draw.lerp(selection_start.snapped(Vector2.ONE), 0.1)
		selection_end_draw = selection_end_draw.lerp(diff.snapped(Vector2.ONE), 0.1)
		selection_rect = Rect2(selection_start_draw, selection_end_draw).abs()
		queue_redraw()

func _on_layer_selected(layer_id: int) -> void:
	# Обработка пустого состояния (нет слоёв)
	if layer_id == -1:
		active_layer = null
		print("[DrawContainer] No active layer (empty state)")
		return
	
	# Находим соответствующий draw layer по ID
	var draw_layer = Services.canvas.get_draw_layer(layer_id)
	if draw_layer:
		active_layer = draw_layer
		print("[DrawContainer] Selected layer: ID=", layer_id)
	else:
		print("[DrawContainer] Draw layer not found: ID=", layer_id)

func _on_mouse_entered() -> void:
	if Cursor.mode == Util.ToolType.BRUSH or Cursor.mode == Util.ToolType.ERASER:
		CursorSprite.instance.hide()

func _on_mouse_exited() -> void:
	if Cursor.mode == Util.ToolType.BRUSH or Cursor.mode == Util.ToolType.ERASER:
		CursorSprite.instance.show()
