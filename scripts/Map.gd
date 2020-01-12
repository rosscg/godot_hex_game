extends Node2D

onready var tilemap : TileMap = $TileMap
onready var tilemap_overlay : TileMap = $TileMapOverlay
onready var hover_hex_sprite : Sprite = $HoverHex
onready var selected_hex_sprite : Sprite = $SelectedHex
onready var line_2d : Line2D = $Line2D


func _process(delta: float) -> void:
	# Show hex hovered over
	var hex_coords = tilemap.get_hex_coordinates(get_global_mouse_position())
	if hex_coords or hex_coords == Vector2(0,0):
		hover_hex_sprite.visible = true
		hover_hex_sprite.position = tilemap.get_centre_coordinates_from_hex(hex_coords)
	else:
		hover_hex_sprite.visible = false


func display_path(selected_unit):
	hover_hex_sprite.visible = false
	tilemap_overlay.clear()
	var path = tilemap.find_path(selected_unit.position, get_global_mouse_position(), selected_unit.terrain_dict)
	#path.remove(0)
	#for p in path:
	#	tilemap_overlay.set_cellv(p, 1)
	var point_path = []
	for p in path:
		point_path.append(tilemap.get_centre_coordinates_from_hex(p))
	line_2d.points = point_path
	return path