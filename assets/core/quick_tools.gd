class_name QuickTools extends Control

var mouse_pos: Vector2
var vp_image: Image



var preview_color: Color = Color.TRANSPARENT
var outline_color: Color = Color.WHITE
var preview_size: Vector2 = Vector2(32.0, 32.0)
var offset: Vector2 = Vector2(6.0, 6.0)

func _ready() -> void:
	top_level = true

func _draw() -> void:
	if not AppState.is_color_picking:
		return
	
	var rect := Rect2(mouse_pos + offset, preview_size)
	
	draw_rect(rect, preview_color, true)
	draw_rect(rect, outline_color, false)
	draw_circle(mouse_pos, 6.0, outline_color, false, -1.0, false)

func _input(event: InputEvent) -> void:
	_hotkeys_tools(event)
	_quick_picker(event)
	
	if event.is_action_pressed("undo") and not Input.is_key_pressed(KEY_SHIFT):
		History.undo_redo.undo()
	if event.is_action_pressed("redo"):
		History.undo_redo.redo()


func _hotkeys_tools(event: InputEvent) -> void:
	if event.is_action_pressed("brush"):
		Services.tool.select_tool(ToolType.Type.BRUSH)
	if event.is_action_pressed("eraser"):
		Services.tool.select_tool(ToolType.Type.ERASER)
	if event.is_action_pressed("fill"):
		Services.tool.select_tool(ToolType.Type.FILL)
	if event.is_action_pressed("selection"):
		Services.tool.select_tool(ToolType.Type.SELECTION)

func _quick_picker(event: InputEvent) -> void:
	if event.is_action_pressed("picker"):
		AppState.is_color_picking = true
		
		# Скрываем курсор СРАЗУ
		Services.cursor.hide_cursor()
		
		await get_tree().physics_frame
		
		mouse_pos = get_global_mouse_position()
		vp_image = get_viewport().get_texture().get_image()
		preview_color = vp_image.get_pixelv(mouse_pos)
		outline_color = Color.WHITE - preview_color * 0.5
		outline_color.a = 1.0
		queue_redraw()
	
	if event.is_action_released("picker"):
		AppState.is_color_picking = false
		
		Services.cursor.show_cursor()
		
		queue_redraw()
	
	if event.is_action_pressed("action") and AppState.is_color_picking:
		AppState.is_color_picking = false
		Services.color.set_primary_color(preview_color)
		Services.cursor.show_cursor()
		
		queue_redraw()
	
	if event.is_action_pressed("cancel") and AppState.is_color_picking:
		AppState.is_color_picking = false
		Services.color.set_secondary_color(preview_color)
		Services.cursor.show_cursor()
		
		queue_redraw()
	
	
	if event is InputEventMouseMotion and AppState.is_color_picking:
		mouse_pos = get_global_mouse_position()
		# Обновляем изображение viewport при каждом движении
		vp_image = get_viewport().get_texture().get_image()
		preview_color = vp_image.get_pixelv(mouse_pos)
		queue_redraw()
