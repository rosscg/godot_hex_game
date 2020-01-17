extends Node2D

onready var tilemap : TileMap = $TileMap_SquareLarge
onready var hover_cell_sprite : Sprite = $HoverCell
onready var line_2d : Line2D = $Line2D
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
	for p in smooth(path):
		point_path.append(tilemap.get_coordinates_from_cell(p, true))
	line_2d.points = point_path
	return path


func smooth(path, severity=3):
	### Note: smoothing path for traversal (as opposed to display) can cause
	### unit to cross into wrong hex (i.e. on hairpin turns).
	if len(path) == 0:
		return path
	# Double points in path for smoother curves:
	var doubled_path = []
	for i in range(len(path)-1):
		doubled_path.append(path[i])
		doubled_path.append((path[i]+path[i+1])/2)
	doubled_path.append(path[len(path)-1])
	
	var smoothed_path = []
	for i in range(len(doubled_path)):
		var start = max(i-severity, 0)
		#var end = min(i+severity+1, len(doubled_path))
		var end = min(i+1, len(doubled_path)) # Don't look ahead for smoothing
		var sum = Vector2(0,0)
		for j in range(start, end):
			sum += doubled_path[j]
		var avg = sum / (end-start)
		smoothed_path.append(avg)
	smoothed_path.append(doubled_path[len(doubled_path)-1])
	return PoolVector2Array(smoothed_path)