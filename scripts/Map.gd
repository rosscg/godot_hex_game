extends Node2D

#onready var tilemap : TileMap = $TileMap_SquareLarge2
onready var tilemap : TileMap = $TileMap_PointyHex
onready var hover_cell_sprite : Sprite = $HoverCell
#onready var hover_cell_sprite2 : Sprite = $HoverCell2
onready var line_2d : Line2D = $Line2D
#onready var line_2d2 : Line2D = $Line2D2
#onready var tilemap_overlay : TileMap = $TileMapOverlay
#onready var selected_cell_sprite : Sprite = $SelectedCell
var cell_array


func _ready():
	cell_array=[]
	var dimensions = tilemap.grid_dimensions.end + tilemap.grid_offset
	for x in range(dimensions.x):
		cell_array.append([])
		for y in range(dimensions.y):
			cell_array[x].append([])


func _process(_delta: float) -> void:
	# Show cell hovered over
	var cell_coords = tilemap.get_cell_from_coordinates(get_global_mouse_position())
	if cell_coords:
		hover_cell_sprite.visible = true
		hover_cell_sprite.position = tilemap.get_coordinates_from_cell(cell_coords, true)
	else:
		hover_cell_sprite.visible = false


func display_path(selected_unit):
	if not selected_unit:
		line_2d.clear_points()
#		line_2d2.clear_points()
#		hover_cell_sprite2.visible = false
		return null
	hover_cell_sprite.visible = false
	#tilemap_overlay.clear()
	var path = selected_unit.calc_unit_path(get_global_mouse_position(), true)
	#var path_truncated = tilemap.find_path_for_distance(path, 12, selected_unit.terrain_dict)
	#path.remove(0)
	#for p in path:
	#	tilemap_overlay.set_cellv(p, 1)
	var point_path = []
	#for p in smooth(path_truncated):
	for p in smooth(path):
		point_path.append(tilemap.get_coordinates_from_cell(p, true))
	line_2d.points = smooth(point_path)
	#if len(point_path) > 0:
	#	hover_cell_sprite2.position = point_path[len(point_path)-1]
	#	hover_cell_sprite2.visible = true
	#else:
	#	hover_cell_sprite2.visible = false
	#point_path = []
	#for p in smooth(path):
	#	point_path.append(tilemap.get_coordinates_from_cell(p, true))
	#line_2d2.points = point_path
	return path


func smooth(path, severity=3):
	### Warning: smoothing path for traversal (as opposed to display) can cause
	### unit to cross into wrong hex (i.e. on hairpin turns).
	if len(path) == 0:
		return path
	# Adjust points in path for smoother curves:
	var adjusted_path = []
	for i in range(len(path)-1):
		# If using square map, double path for smoothing
		# Otherwise path is simply edge intercepts between hexes
		if tilemap.cell_half_offset == 2:
			adjusted_path.append(path[i])
		adjusted_path.append((path[i]+path[i+1])/2)
	adjusted_path.append(path[len(path)-1])
	
	var smoothed_path = []
	for i in range(len(adjusted_path)):
		var start = max(i-severity, 0)
		#var end = min(i+severity+1, len(adjusted_path))
		var end = min(i+1, len(adjusted_path)) # Don't look ahead for smoothing
		var sum = Vector2(0,0)
		for j in range(start, end):
			sum += adjusted_path[j]
		var avg = sum / (end-start)
		smoothed_path.append(avg)
	smoothed_path.append(adjusted_path[len(adjusted_path)-1])
	return PoolVector2Array(smoothed_path)