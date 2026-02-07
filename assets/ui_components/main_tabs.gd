class_name MainTabs extends Control

signal active_tab_changed(id: int)

var active_tab: int:
	set = set_active_tab

@onready var draw_tab: Panel = $DrawTab
@onready var anim_tab: Panel = $AnimTab
@onready var evo_tab: Panel = $EvoTab

func set_active_tab(id: int) -> void:
	if id != active_tab:
		active_tab = id
		active_tab_changed.emit(active_tab)
