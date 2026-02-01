extends Node

var undo_redo: UndoRedo = UndoRedo.new()

func _init() -> void:
	undo_redo.max_steps = 77
