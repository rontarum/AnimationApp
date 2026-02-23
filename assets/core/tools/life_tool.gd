class_name LifeTool extends RefCounted

var undo_redo: UndoRedo

func _init() -> void:
	undo_redo = History.undo_redo

func handle_input(event: InputEvent, item: SpriteMesh) -> void:
	pass

func should_draw_preview(answer: bool = true) -> bool:
	return answer
