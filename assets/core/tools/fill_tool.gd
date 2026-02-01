class_name FillTool extends BaseTool

## Инструмент заливки - заполняет область одинакового цвета
## 
## Зона ответственности:
## - Flood fill алгоритм для связанных областей (contiguous)
## - Заливка всех пикселей цвета (non-contiguous)

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if not layer:
		return
	layer.start_changes()
	
	var target_color: Color = layer.get_pixel(position)
	
	# Если цвет уже совпадает, ничего не делаем
	if target_color.is_equal_approx(color) or target_color == color:
		return
	
	var is_contiguous: bool = Services.tool.get_tool_property("contiguous")
	
	if is_contiguous:
		_flood_fill_contiguous(position, layer, target_color, color)
	else:
		_flood_fill_all(layer, target_color, color)

func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void:
	if layer:
		layer.finish_changes()

func on_hover(position: Vector2i) -> void:
	preview_position = position

func should_draw_preview() -> bool:
	return true

## Flood fill для связанной области (contiguous)
func _flood_fill_contiguous(start_pos: Vector2i, layer: DrawLayer, target_color: Color, fill_color: Color) -> void:
	var canvas_size: Vector2i = layer.get_image_size()
	if start_pos.x < 0 or start_pos.y < 0 or start_pos.x >= canvas_size.x or start_pos.y >= canvas_size.y:
		return
		
	var queue: Array[Vector2i] = [start_pos]
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(canvas_size.x * canvas_size.y)
	visited[start_pos.y * canvas_size.x + start_pos.x] = 1
	
	
	while queue.size() > 0:
		var pos: Vector2i = queue.pop_back()
		layer.set_pixel(pos, fill_color)
		
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor: Vector2i = pos + offset
			
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= canvas_size.x or neighbor.y >= canvas_size.y:
				continue
				
			var idx: int = neighbor.y * canvas_size.x + neighbor.x
			
			if visited[idx] == 1:
				continue
			if not _colors_match(layer.get_pixel(neighbor), target_color):
				continue
				
			visited[idx] = 1
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
	layer.update_image()

func _colors_match(a: Color, b: Color) -> bool:
	if a.a == 0.0 and b.a == 0.0:
		return true
	return a.is_equal_approx(b)
