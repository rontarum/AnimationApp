class_name FillTool extends BaseTool

## Инструмент заливки - заполняет область одинакового цвета
## 
## Зона ответственности:
## - Flood fill алгоритм для связанных областей (contiguous)
## - Заливка всех пикселей цвета (non-contiguous)

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if not layer:
		return
	
	var target_color: Color = layer.get_pixel(position)
	
	# Если цвет уже совпадает, ничего не делаем
	if target_color.is_equal_approx(color) or target_color == color:
		return
	
	var is_contiguous: bool = Services.tool.get_tool_property("contiguous")
	
	if is_contiguous:
		_flood_fill_contiguous(position, layer, target_color, color)
	else:
		_flood_fill_all(layer, target_color, color)

func on_drag(_position: Vector2i, _layer: DrawLayer, _color: Color) -> void:
	# Fill не использует drag
	pass

func on_release(_position: Vector2i, _layer: DrawLayer, _color: Color) -> void:
	# Fill не требует действий при release
	pass

func on_hover(position: Vector2i) -> void:
	preview_position = position

func should_draw_preview() -> bool:
	return false  # Fill не показывает preview

## Flood fill для связанной области (contiguous)
func _flood_fill_contiguous(start_pos: Vector2i, layer: DrawLayer, target_color: Color, fill_color: Color) -> void:
	var canvas_size: Vector2i = layer.get_image_size()
	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {}  # String key -> bool
	visited[start_pos] = true
	
	if start_pos.x < 0 or start_pos.y < 0 or start_pos.x >= canvas_size.x or start_pos.y >= canvas_size.y:
		return
	
	while queue.size() > 0:
		var pos: Vector2i = queue.pop_back()
		layer.set_pixel(pos, fill_color)
		
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor: Vector2i = pos + offset
			
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= canvas_size.x or neighbor.y >= canvas_size.y:
				continue
				
			visited[neighbor] = true
			queue.append(neighbor)
	layer.update_image()

## Заливка всех пикселей данного цвета (non-contiguous)
func _flood_fill_all(layer: DrawLayer, target_color: Color, fill_color: Color) -> void:
	var canvas_size: Vector2i = layer.get_image_size()
	
	
	for x in range(canvas_size.x):
		for y in range(canvas_size.y):
			var pos = Vector2i(x, y)
			var current_color: Color = layer.get_pixel(pos)
			if _colors_match(current_color, target_color):
				layer.set_pixel(pos, fill_color)

func _colors_match(a: Color, b: Color) -> bool:
	if a.a == 0.0 and b.a == 0.0:
		return true
	return a.is_equal_approx(b)
