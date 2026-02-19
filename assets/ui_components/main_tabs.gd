class_name MainTabs extends Control

signal active_tab_changed(id: int)

var active_tab: int:
	set = set_active_tab

func _ready() -> void:
	active_tab = 0
	active_tab_changed.emit(active_tab)

func set_active_tab(id: int) -> void:
	if id != active_tab:
		active_tab = id
		active_tab_changed.emit(active_tab)
		
		AppState.current_tab = id
