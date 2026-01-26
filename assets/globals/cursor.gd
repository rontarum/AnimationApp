extends Node

signal focus_changed(node: Node)

var icons: Dictionary[Util.ToolType, Resource] = {
	Util.ToolType.ARROW: preload("uid://dcruge44xhvb5"),
	Util.ToolType.POINTER: preload("uid://dnie07jd2k76c"),
	Util.ToolType.GRAB: preload("uid://c52jc2rf8n66q"),
	
}

var focus: Node
var mode: Util.ToolType = Util.ToolType.ARROW

var state_machine: StateMachine

var primary_swatch: Color
var secondary_swatch: Color

@onready var icon := Sprite2D.new()

func _ready() -> void:
	state_machine = StateMachine.new()
	state_machine.owner = self
	state_machine.add_state("arrow", ArrowState.new())
	state_machine.add_state("brush", BrushState.new())
	state_machine.set_initial_state("arrow")

func set_focus(node: Node):
	focus = node
	focus_changed.emit(node)

func set_mode(type: Util.ToolType) -> void:
	mode = type
	var new_state_name: StringName = Util.ToolType.keys()[type].to_lower()
	state_machine.change_state(new_state_name)

func get_icon(type: Util.ToolType) -> Resource:
	return icons.get(type)

func _input(event: InputEvent) -> void:
	state_machine.handle_input(event)
