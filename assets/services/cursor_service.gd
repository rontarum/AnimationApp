class_name CursorService extends Node

## Сервис управления визуальным состоянием курсора
## Зона ответственности: иконки курсора, видимость, интеграция с инструментами

# Маппинг инструментов на иконки курсора
var tool_icons: Dictionary[ToolType.Type, Resource] = {
	ToolType.Type.ARROW: preload("uid://dcruge44xhvb5"),
	ToolType.Type.POINTER: preload("uid://dnie07jd2k76c"),
	ToolType.Type.GRAB: preload("uid://c52jc2rf8n66q"),
	ToolType.Type.DRAG: preload("uid://dwypmwotmiaop")
}

var cursor_sprite: CursorSprite
var _override_icon: ToolType.Type = ToolType.Type.ARROW  # Временный override
var _is_overridden: bool = false  # Флаг активного override

func _ready() -> void:
	Services.register("cursor", self)
	
	# Ждём один кадр, чтобы GUI CanvasLayer точно существовал
	await get_tree().process_frame
	
	# Находим GUI CanvasLayer и добавляем туда CursorSprite
	var ui_layer = get_tree().root.get_node_or_null("App/UI")
	if ui_layer:
		cursor_sprite = CursorSprite.new()
		cursor_sprite.name = "CursorSprite"
		ui_layer.add_child(cursor_sprite)
		cursor_sprite.z_index = 3
	else:
		push_error("[CursorService] UI CanvasLayer not found!")
		return
	
	# Подписываемся на события
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.ui_element_hovered.connect(_on_ui_element_hovered)	
	# Устанавливаем начальную иконку
	change_icon(AppState.current_tool)

func _on_tool_selected(tool_type: ToolType.Type) -> void:
	if not _is_overridden:
		change_icon(tool_type)

func _on_ui_element_hovered(_element: Node, hovered: bool) -> void:
	if hovered:
		set_override(ToolType.Type.POINTER)
	else:
		clear_override()

## Меняет иконку курсора в зависимости от инструмента
func change_icon(tool_type: ToolType.Type) -> void:
	var icon = tool_icons.get(tool_type)
	if not icon:
		# Fallback на arrow для недостающих иконок
		icon = tool_icons.get(ToolType.Type.ARROW)
	
	if icon and cursor_sprite:
		cursor_sprite.set_cursor_texture(icon)

## Устанавливает временный override курсора (для UI hover, drag и т.д.)
func set_override(tool_type: ToolType.Type) -> void:
	_is_overridden = true
	_override_icon = tool_type
	change_icon(tool_type)

## Снимает override и возвращает курсор текущего инструмента
func clear_override() -> void:
	_is_overridden = false
	change_icon(AppState.current_tool)

## Показывает курсор
func show_cursor() -> void:
	if cursor_sprite:
		cursor_sprite.show_cursor()

## Скрывает курсор
func hide_cursor() -> void:
	if cursor_sprite:
		cursor_sprite.hide_cursor()
