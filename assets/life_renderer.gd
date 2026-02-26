class_name LifeRenderer extends Node2D

enum VertexState {PASSIVE, HOVERED, ACTIVE}
enum EdgeState {BOUND, PASSIVE, ACTIVE, POLYGON}

@export var vertex_icons: Array[Texture2D]

@export var life_container: LifeContainer
@export var life_canvas: SubViewport

var mouse_pos: Vector2 = Vector2.ZERO
var slide_pos: Vector2 = Vector2.ZERO

var active_tool = null

func _ready() -> void:
	add_to_group("Life", true)
	EventBus.tool_selected.connect(_on_active_tool_changed)
	active_tool = Services.tool.get_active_life_tool()

func _process(delta: float) -> void:
	if not life_container or not visible:
		return
	
	mouse_pos = life_container.get_local_mouse_position()
	slide_pos = lerp(slide_pos, round(mouse_pos), 63.9 * delta)
	queue_redraw()

func _draw() -> void:
	if not active_tool or not active_tool is MeshTool:
		return
	
	if not _in_boundary():
		return
	var mesh_tool: MeshTool = active_tool as MeshTool
	_draw_point(slide_pos, VertexState.PASSIVE)

func draw_vertex(vertex: PackedVector2Array) -> void:
	for point: Vector2 in vertex:
		_draw_point(point, VertexState.PASSIVE)

func _draw_point(pos: Vector2, state: VertexState) -> void:
	var icon: Texture2D
	icon = vertex_icons[state]
	var offset := Vector2(0.25, 0.25)
	var rect := Rect2(pos - offset, Vector2(0.5, 0.5))
	draw_texture_rect(icon, rect, false)
	

func _on_active_tool_changed(tool) -> void:
	active_tool = Services.tool.get_active_life_tool()
	print(active_tool)

func _in_boundary() -> bool:
	if mouse_pos.x < 0.0 or mouse_pos.y < 0.0:
		return false
	if mouse_pos.x >= life_container.size.x or mouse_pos.y >= life_container.size.y:
		return false
	return true
