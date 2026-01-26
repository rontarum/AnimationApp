class_name ArrowState extends State

var icon = preload("uid://dcruge44xhvb5")

var owner: Node

var is_pressed: bool = false
var is_selecting: bool = false

var start_pos: Vector2
var diff: Vector2

func _init() -> void:
	state_name = "arrow"

func enter(from: StringName) -> void:
	owner = state_machine.owner
	Cursor.mode = Util.ToolType.ARROW

func handle_input(event: InputEvent) -> void:
	var drawer := CursorDrawer.instance
	var rect: Rect2
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_selecting = true
			start_pos = event.position
		else:
			is_selecting = false
			drawer.is_selecting = false
			drawer.queue_redraw()
	elif is_selecting and event is InputEventMouseMotion:
		var x_min = min(start_pos.x, event.position.x)
		var y_min = min(start_pos.y, event.position.y)
		rect = Rect2(x_min, y_min,
			max(start_pos.x, event.position.x) - x_min,
			max(start_pos.y, event.position.y) - y_min)
		drawer.queue_redraw()
	drawer.draw_selection(rect)
