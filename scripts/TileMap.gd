extends TileMap

var grid_cell_height = cell_size.y
var grid_cell_width = cell_size.x
var grid_dimensions = get_used_rect()

var tile_id_types = {1: 'grass', 2: 'dirt', 3: 'lowhills', 4: 'forest', 6: 'marsh', 8: 'mountain', 
						10: 'water', 11: 'deepwater', 12: 'road'}
var impassable_tile_ids = [11] # Tile id 3 'deepwater' considered impassable


#func _ready():
	#print(get_used_cells())


func _is_left(point: Vector2, a: Vector2, b: Vector2):
     return ((b.x - a.x)*(point.y - a.y) - (b.y - a.y)*(point.x - a.x)) < 0


func get_hex_coordinates(point: Vector2):
	### Converts global coordinates into hex grid coordinates.
	### Expects flat-top grid where odd columns start lower than even i.e. at (0, grid_cell_height/2)
	# Width of cell that isn't entirely contained by the 'main' hex
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
	if _is_left(local_mouse_coord, Vector2(0, grid_cell_height/2 - 1), Vector2(triangle_width - 1, 0)):
		grid_coord.x -= 1
		if fmod(grid_coord.x, 2) != 0:
			grid_coord.y -= 1
	# Is point outside hex, in bottom left corner:
	if _is_left(local_mouse_coord, Vector2(triangle_width - 1, grid_cell_height - 1), Vector2(0, grid_cell_height/2)):
		grid_coord.x -= 1
		if fmod(grid_coord.x, 2) == 0:
			grid_coord.y += 1
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


func get_centre_coordinates_from_hex(point: Vector2):
	### Returns global coordinates of centre of hex grid position
	var coordinates = get_coordinates_from_hex(point) + Vector2(grid_cell_height/2, grid_cell_height/2)
	return coordinates
	

func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= grid_dimensions.end.x or point.y >= grid_dimensions.end.y


func _calculate_point_index(cell):
	return cell.x + grid_dimensions.end.x * cell.y


func find_path(start_pos, end_pos, terrain_dict=null):
	var astar_node = AStar.new()
	var path_start_position = get_hex_coordinates(start_pos)
	var path_end_position = get_hex_coordinates(end_pos)
	if not path_end_position and path_end_position != Vector2(0,0): # Out of bounds
		return []
	
	var walkable_cells_list = []
	var obstacles = []
	for tile_id in impassable_tile_ids:
		obstacles += get_used_cells_by_id(tile_id)
	
	var cell_counter = 0 # Cell counter forces equal paths to choose left side by adjusting weight by small amount
	for point in self.get_used_cells():
		if point in obstacles:
			continue
		walkable_cells_list.append(point)
		var cell_index = _calculate_point_index(point)
		# Set weight for tile using unit move speeds
		var weight = 1000
		var tile_id = self.get_cellv(point)
		if terrain_dict:
			weight = terrain_dict[tile_id_types[tile_id]] * 1000 # Multiply by 1000 to reduce effect of cell_counter
		astar_node.add_point(cell_index, Vector3(point.x, point.y, 0.0), weight+cell_counter)
		cell_counter += 0.001

	for point in walkable_cells_list:
		var point_index = _calculate_point_index(point)
		var points_relative
		if fmod(point.x, 2) == 0:
			points_relative = PoolVector2Array([
				Vector2(point.x, point.y - 1),
				Vector2(point.x + 1, point.y - 1),
				Vector2(point.x + 1, point.y),
				Vector2(point.x, point.y + 1),
				Vector2(point.x - 1, point.y),
				Vector2(point.x - 1, point.y - 1)])
		else:
			points_relative = PoolVector2Array([
				Vector2(point.x, point.y - 1),
				Vector2(point.x + 1, point.y),
				Vector2(point.x + 1, point.y + 1),
				Vector2(point.x, point.y + 1),
				Vector2(point.x - 1, point.y + 1),
				Vector2(point.x - 1, point.y)])
		for point_relative in points_relative:
			var point_relative_index = _calculate_point_index(point_relative)
			if is_outside_map_bounds(point_relative):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)
	
	#### Debugging ####
	# Inefficient vertical path chosen on odd columns using weights 1000 and 5000
	var point_path_ids = astar_node.get_id_path(_calculate_point_index(path_start_position), _calculate_point_index(path_end_position))
	var total_weight = 0
	for x in point_path_ids:
		total_weight += astar_node.get_point_weight_scale(x)
	print(total_weight)
	##################
	
	var point_path = astar_node.get_point_path(_calculate_point_index(path_start_position), _calculate_point_index(path_end_position))
	var point_path2 = []
	for p in point_path:
		point_path2.append(Vector2(p.x, p.y))
	
	return point_path2