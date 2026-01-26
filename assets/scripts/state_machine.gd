class_name StateMachine extends RefCounted

var owner: Node

var states: Dictionary[StringName, State] = {}
var current_state: State

func add_state(name: String, state: State) -> void:
	states[name.to_lower()] = state
	state.state_machine = self

func set_initial_state(state_name: StringName) -> void:
	change_state(state_name)

func change_state(new_state_name: StringName) -> void:
	if current_state:
		current_state.exit()
	
	current_state = states.get(new_state_name)
	if current_state:
		current_state.enter(new_state_name)
	else:
		push_error("State not found: " + new_state_name)

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
