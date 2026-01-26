class_name State extends RefCounted

var state_name: StringName
var state_machine: StateMachine

func enter(from: StringName) -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass
