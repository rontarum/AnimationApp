extends Node

var draw_container: DrawContainer
var current_layer: SubViewport

var canvas_size := Vector2(32.0, 32.0)

signal image_copied
