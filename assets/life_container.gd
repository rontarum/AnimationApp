class_name LifeContainer extends SubViewportContainer

@onready var life_canvas: SubViewport = $LifeCanvas

var root_item: Node2D = Node2D.new()
var active_item: SpriteMesh

var mouse_pos: Vector2

func _ready() -> void:
	root_item.name = "RootItem"
	#root_item.position = life_canvas.size * 0.5
	life_canvas.add_child(root_item, true)
	
	EventBus.tab_changed.connect(_on_tab_changed)

func _on_tab_changed(tab: int) -> void:
	if tab == 1:
		_items_from_layers()

func _items_from_layers() -> void:
	var layers: Dictionary = Services.canvas.get_all_layers()
	if layers.is_empty():
		return
	
	for layer: DrawLayer in layers.values():
		
		var image := layer.get_image()
		var rect := image.get_used_rect()
		if rect.has_area():
			var trimmed := Image.create(rect.size.x, rect.size.y, false, image.get_format())
			trimmed.blit_rect(image, rect, Vector2.ZERO)
			image = trimmed
			
		var item := SpriteMesh.new()
		item.name = layer.get_layer_name()
		item.texture = ImageTexture.create_from_image(image)
		root_item.add_child(item)
