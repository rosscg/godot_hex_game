extends TileMap

#var grid_cell_height = 72
var grid_cell_height = cell_size.y
#var grid_cell_width = 54
var grid_cell_width = cell_size.x
#var grid_dimensions = Vector2(19,8)
var grid_dimensions = get_used_rect()

func _ready():
	print(tile_set.get_tiles_ids())


func is_left(point: Vector2, a: Vector2, b: Vector2):
     return ((b.x - a.x)*(point.y - a.y) - (b.y - a.y)*(point.x - a.x)) < 0


func get_hex_coordinates(point: Vector2):
	### Converts global coordinates into hex grid coordinates.
	### Expects flat-top grid where odd columns start lower i.e. at (0, 36)
	
	var triangle_width = grid_cell_height - grid_cell_width

	# Handle y offsets for odd columns
	if int(point.x/grid_cell_width) % 2 != 0:
		point.y -= grid_cell_height/2

	# Get coordinates of grid square
	var grid_coord = Vector2(int(point.x/grid_cell_width), int(point.y/grid_cell_height))
	# Handle null space above alternating columns
	if point.y < 0:
		grid_coord.y -= 1
	# Get mouse coordinates within the grid square
	var local_mouse_coord = Vector2(fmod(point.x, grid_cell_width), fmod(point.y, grid_cell_height))

	# Is point outside hex, in top left corner, so belongs to adjacent hex:
	if is_left(local_mouse_coord, Vector2(0, grid_cell_height/2 - 1), Vector2(triangle_width - 1, 0)):
		grid_coord.x -= 1
		if fmod(grid_coord.x, 2) != 0:
			grid_coord.y -= 1
	# Is point outside hex, in bottom left corner:
	if is_left(local_mouse_coord, Vector2(triangle_width - 1, grid_cell_height - 1), Vector2(0, grid_cell_height/2)):
		grid_coord.x -= 1
		if fmod(grid_coord.x, 2) == 0:
			grid_coord.y += 1

	#if 0 <= grid_coord.x and grid_coord.x < grid_dimensions.x and 0 <= grid_coord.y and grid_coord.y < grid_dimensions.y:
	if grid_dimensions.has_point(grid_coord):
		return grid_coord
	else:
		return null


func get_coordinates_from_hex(point: Vector2):
	### Returns top right corner global coordinates of hex grid position
	var coordinates = Vector2(point.x * grid_cell_width, point.y * grid_cell_height)
	if int(point.x) % 2 != 0:
		coordinates.y += grid_cell_height / 2
	return coordinates