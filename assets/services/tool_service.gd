## ToolService - Управление инструментами
##
## Отвечает за выбор инструментов, их состояние и действия.
## Слушает события из EventBus и обновляет AppState.
## Управляет instances инструментов (DrawTool).

class_name ToolService
extends Node

var active_draw_tool: DrawTool = null
var active_life_tool: LifeTool = null

# Separate storage for each tool type
var draw_tool_instances: Dictionary = {}  # ToolType.Type -> DrawTool
var life_tool_instances: Dictionary = {}  # ToolType.Type -> LifeTool

# Typed property storage
var draw_properties: Dictionary = {}  # ToolType.Type -> Resource
var life_properties: Dictionary = {}  # ToolType.Type -> Resource

func _ready() -> void:
	Services.register("tool", self)
	
	_initialize_tools()
	
	# Подписка на события
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.layer_selected.connect(_on_layer_selected)
	EventBus.tab_changed.connect(_on_tab_changed)
	
	# Устанавливаем начальный инструмент
	var initial_tool_type = AppState.current_tool
	active_draw_tool = draw_tool_instances.get(initial_tool_type)
	if not active_draw_tool:
		active_life_tool = life_tool_instances.get(initial_tool_type)

## Инициализация всех инструментов и их свойств
func _initialize_tools() -> void:
	
	#------------- DRAW TOOLS -------------#
	
	# ============================================================
	# BRUSH TOOL
	# ============================================================
	draw_tool_instances[ToolType.Type.BRUSH] = BrushTool.new()
	
	var brush_props = BrushProps.new()
	brush_props.size = 1
	brush_props.shape = 0
	draw_properties[ToolType.Type.BRUSH] = brush_props
	
	var brush_tool = draw_tool_instances[ToolType.Type.BRUSH] as BrushTool
	if brush_tool:
		brush_tool.connect_to_properties(brush_props)
	
	# ============================================================
	# ERASER TOOL
	# ============================================================
	draw_tool_instances[ToolType.Type.ERASER] = EraserTool.new()
	
	var eraser_props = EraserProps.new()
	eraser_props.size = 1
	draw_properties[ToolType.Type.ERASER] = eraser_props
	
	var eraser_tool = draw_tool_instances[ToolType.Type.ERASER] as EraserTool
	if eraser_tool:
		eraser_tool.connect_to_properties(eraser_props)
	
	# ============================================================
	# FILL TOOL
	# ============================================================
	draw_tool_instances[ToolType.Type.FILL] = FillTool.new()
	
	var fill_props = FillProps.new()
	fill_props.contiguous = true
	draw_properties[ToolType.Type.FILL] = fill_props
	
	var fill_tool = draw_tool_instances[ToolType.Type.FILL] as FillTool
	if fill_tool:
		fill_tool.connect_to_properties(fill_props)
	
	# ============================================================
	# SELECTION TOOL
	# ============================================================
	draw_tool_instances[ToolType.Type.SELECTION] = SelectionTool.new()
	
	#------------- LIFE TOOLS -------------#
	
	# ============================================================
	# MESH TOOL
	# ============================================================
	life_tool_instances[ToolType.Type.MESH] = MeshTool.new()
	
	var mesh_props = MeshProps.new()
	life_properties[ToolType.Type.MESH] = mesh_props
	
	var mesh_tool = life_tool_instances[ToolType.Type.MESH] as MeshTool
	if mesh_tool:
		mesh_tool.connect_to_properties(mesh_props)

## Выбор инструмента
func select_tool(tool_type: ToolType.Type) -> void:
	AppState.current_tool = tool_type

## Возвращает активный Draw mode инструмент
func get_active_draw_tool() -> DrawTool:
	return active_draw_tool

## Возвращает активный Life mode инструмент
func get_active_life_tool() -> LifeTool:
	return active_life_tool

## Возвращает активный инструмент (deprecated, используйте get_active_draw_tool или get_active_life_tool)
func get_active_tool() -> RefCounted:
	if active_draw_tool:
		return active_draw_tool
	return active_life_tool

## Получить typed property для Draw mode инструмента
func get_draw_property(tool_type: ToolType.Type) -> Resource:
	return draw_properties.get(tool_type, null)

## Получить typed property для Life mode инструмента
func get_life_property(tool_type: ToolType.Type) -> Resource:
	return life_properties.get(tool_type, null)

## Изменить размер кисти/ластика
func resize_tool(delta: float) -> void:
	var tool_type = AppState.current_tool
	var props = get_draw_property(tool_type)
	
	if props and "size" in props:
		var new_size = clamp(props.size + delta, 1, 10)
		props.size = new_size

func reset_tool_size() -> void:
	var tool_type = AppState.current_tool
	var props = get_draw_property(tool_type)
	
	if props and "size" in props:
		props.size = 1

# ============================================================
# ОБРАБОТЧИКИ СОБЫТИЙ
# ============================================================

func _on_tab_changed(tab: int) -> void:
	select_tool(ToolType.Type.ARROW)

func _on_tool_selected(tool_type: ToolType.Type) -> void:
	# Переключаем активный инструмент
	# Сначала проверяем в draw_tool_instances, затем в life_tool_instances
	var draw_tool = draw_tool_instances.get(tool_type)
	var life_tool = life_tool_instances.get(tool_type)
	
	if draw_tool:
		active_draw_tool = draw_tool
		active_life_tool = null
	elif life_tool:
		active_life_tool = life_tool
		active_draw_tool = null
	else:
		push_warning("[ToolService] No tool instance for: ", ToolType.Type.keys()[tool_type])
		active_draw_tool = null
		active_life_tool = null

func _on_layer_selected(layer_id: int) -> void:
	# При смене слоя сбрасываем выделение в SelectionTool
	var selection_tool = draw_tool_instances.get(ToolType.Type.SELECTION) as SelectionTool
	if selection_tool:
		selection_tool.deselect()
