extends Node2D

onready var tilemap : TileMap = $TileMap_SquareLarge
onready var hover_cell_sprite : Sprite = $HoverCell
onready var line_2d : Line2D = $Line2D
#onready var tilemap_overlay : TileMap = $TileMapOverlay
#onready var selected_cell_sprite : Sprite = $SelectedCell


func _process(_delta: float) -> void:
	# Show cell hovered over
	var cell_coords = tilemap.get_cell_coordinates(get_global_mouse_position())
	if cell_coords:
		hover_cell_sprite.visible = true
		hover_cell_sprite.position = tilemap.get_coordinates_from_cell(cell_coords, true)
	else:
		hover_cell_sprite.visible = false


func display_path(selected_unit):
	if not selected_unit:
		line_2d.clear_points()
		return null
	hover_cell_sprite.visible = false
	#tilemap_overlay.clear()
	var path = tilemap.find_path(selected_unit.position, get_global_mouse_position(), selected_unit.astar_node)
	#path.remove(0)
	#for p in path:
	#	tilemap_overlay.set_cellv(p, 1)
	var point_path = []
	for p in path:
		point_path.append(tilemap.get_coordinates_from_cell(p, true))
	line_2d.points = point_path
	return path