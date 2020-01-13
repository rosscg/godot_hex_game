extends TileMap

# Add 1,1 to grid coordinates as otherwise Vector2(0,0) parses as null:
var grid_offset = Vector2(1,1)

var grid_cell_height = cell_size.y
var grid_cell_width = cell_size.x
var grid_dimensions = get_used_rect()

var tile_id_types = {1: 'grass', 2: 'dirt', 3: 'lowhills', 4: 'forest', 6: 'marsh', 8: 'mountain', 
						10: 'water', 11: 'deepwater', 12: 'road'}
var impassable_tile_ids = [11] # Tile id 11 'deepwater' considered impassable


func _ready() -> void:
	# Check for vacant cells in tilemap:
	if len(get_used_cells()) != grid_dimensions.end.x * grid_dimensions.end.y:
		print(grid_dimensions.end.x * grid_dimensions.end.y - len(get_used_cells()), ' cells missing from tilemap: ', self.name)
		for x in range(grid_dimensions.end.x):
			for y in range(grid_dimensions.end.y):
				if Vector2(x, y) + grid_offset in get_used_cells():
					continue
				print(Vector2(x, y))


func _is_left(point: Vector2, a: Vector2, b: Vector2):
     return ((b.x - a.x)*(point.y - a.y) - (b.y - a.y)*(point.x - a.x)) < 0


func get_cell_coordinates(point: Vector2):
	### Converts global coordinates into cell grid coordinates.
	# Width of cell that isn't entirely contained by the 'main' hex, used for coordinate mapping
	var triangle_width = abs(grid_cell_height - grid_cell_width)
	# Handle offsets for odd columns:
	if self.cell_half_offset == 0: # offset in the x coordinate: (pointy top)
		if int(point.y/grid_cell_height) % 2 != 0:
			point.x -= grid_cell_width/2
	elif self.cell_half_offset == 1: # offset in y coordinate (flat top)
		if int(point.x/grid_cell_width) % 2 != 0:
			point.y -= grid_cell_height/2
	# Get coordinates of grid square
	var grid_coord = Vector2(int(point.x/grid_cell_width), int(point.y/grid_cell_height))
	# Handle null space above/left of alternating columns
	if self.cell_half_offset == 0 and point.x < 0: # pointy top
		grid_coord.x -= 1
	elif self.cell_half_offset == 1 and point.y < 0: # flat top
		grid_coord.y -= 1
	# Get mouse coordinates within the grid square
	var local_mouse_coord = Vector2(fmod(point.x, grid_cell_width), fmod(point.y, grid_cell_height))
	# Is point outside hex, so belongs to adjacent hex:
	if self.cell_half_offset == 0: # pointy top
		if _is_left(local_mouse_coord, Vector2(0, triangle_width - 1), Vector2(grid_cell_width/2 - 1, 0)):
			grid_coord.y -= 1
			if fmod(grid_coord.y, 2) != 0:
				grid_coord.x -= 1
		if _is_left(local_mouse_coord, Vector2(grid_cell_width/2 - 1, 0), Vector2(grid_cell_width, triangle_width - 1)):
			grid_coord.y -= 1
			if fmod(grid_coord.y, 2) == 0:
				grid_coord.x += 1
	elif self.cell_half_offset == 1: # flat top
		if _is_left(local_mouse_coord, Vector2(0, grid_cell_height/2 - 1), Vector2(triangle_width - 1, 0)):
			grid_coord.x -= 1
			if fmod(grid_coord.x, 2) != 0:
				grid_coord.y -= 1
		if _is_left(local_mouse_coord, Vector2(triangle_width - 1, grid_cell_height - 1), Vector2(0, grid_cell_height/2)):
			grid_coord.x -= 1
			if fmod(grid_coord.x, 2) == 0:
				grid_coord.y += 1
	if grid_dimensions.has_point(grid_coord):
		return grid_coord + grid_offset
	else:
		return null


func get_coordinates_from_cell(point: Vector2, centred = false):
	point -= grid_offset
	### Returns top right corner global coordinates of cell grid position
	var coordinates = Vector2(point.x * grid_cell_width, point.y * grid_cell_height)
	# Handle offsets for odd columns if hex grid:
	if self.cell_half_offset == 0: # offset in the x coordinate: (pointy top)
		if int(point.y) % 2 != 0:
			coordinates.x += grid_cell_width / 2
	elif self.cell_half_offset == 1: # offset in y coordinate (flat top)
		if int(point.x) % 2 != 0:
			coordinates.y += grid_cell_height / 2
	if centred: 
		coordinates += cell_size/2
	return coordinates


func is_outside_map_bounds(point):
	point -= grid_offset
	return point.x < 0 or point.y < 0 or point.x >= grid_dimensions.end.x or point.y >= grid_dimensions.end.y


func _calculate_point_index(cell):
	return cell.x + grid_dimensions.end.x * cell.y


func create_astar_node(terrain_dict=null):
	var astar_node = AStar.new()
	
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
		#print(point)
		#print(tile_id)
		if terrain_dict:
			weight = terrain_dict[tile_id_types[tile_id]] * 1000 # Multiply by 1000 to reduce effect of cell_counter
		astar_node.add_point(cell_index, Vector3(point.x, point.y, 0.0), weight+cell_counter)
		cell_counter += 0.001

	for point in walkable_cells_list:
		var point_index = _calculate_point_index(point)
		var points_relative
		if self.cell_half_offset == 2: # no offset: squares
			points_relative = PoolVector2Array([
				Vector2(point.x - 1, point.y - 1),
				Vector2(point.x - 1, point.y),
				Vector2(point.x - 1, point.y + 1),
				Vector2(point.x, point.y - 1),
				Vector2(point.x, point.y + 1),
				Vector2(point.x + 1, point.y - 1),
				Vector2(point.x + 1, point.y),
				Vector2(point.x + 1, point.y + 1)
				])
		else:
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
	#var point_path_ids = astar_node.get_id_path(_calculate_point_index(path_start_position), _calculate_point_index(path_end_position))
	#var total_weight = 0
	#for x in point_path_ids:
	#	total_weight += astar_node.get_point_weight_scale(x)
	#print(total_weight)
	##################
	return astar_node


func find_path(start_pos, end_pos, astar_node):
	var path_start_position = get_cell_coordinates(start_pos)
	var path_end_position = get_cell_coordinates(end_pos)
	if not path_end_position: 
		# Out of bounds
		return []
	if self.get_cellv(path_end_position) in impassable_tile_ids or self.get_cellv(path_start_position) in impassable_tile_ids:
		# Path begins or ends on impassable terrain
		return []
	var point_path = astar_node.get_point_path(_calculate_point_index(path_start_position), _calculate_point_index(path_end_position))
	var point_path2 = []
	for p in point_path:
		point_path2.append(Vector2(p.x, p.y))
	return point_path2


func get_tile_terrain(cell_point):
	return tile_id_types[self.get_cellv(cell_point)]


func get_cellv(point: Vector2):
	# Override to handle grid_offset
	point -= grid_offset
	return get_cell(point.x, point.y)


func get_used_cells_by_id(tile_id):
	# Override to handle grid_offset
	var cells = []
	for c in .get_used_cells_by_id(tile_id):
		cells.append(c + grid_offset)
	return cells


func get_used_cells():
	# Override to handle grid_offset
	var cells = []
	for c in .get_used_cells():
		cells.append(c + grid_offset)
	return cells