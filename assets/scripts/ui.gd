class_name UI extends CanvasLayer

var _tab_groups: Dictionary = {
	0: "Draw",
	1: "Animation",
	2: "Evo"
}

func _ready() -> void:
	EventBus.tab_changed.connect(_on_tab_changed)

func _on_tab_changed(tab: int) -> void:
	for id: int in _tab_groups:
		var group_name: String = _tab_groups[id]
		var should_show: bool = (id == tab)
		for node: Control in get_tree().get_nodes_in_group(group_name):
			node.visible = should_show
	
	
