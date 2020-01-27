extends TileMap

# Add 1,1 to grid coordinates as otherwise Vector2(0,0) parses as null:
var grid_offset = Vector2(1,1) # Change to Vector2(0,0) to disable.

var grid_cell_height = cell_size.y
var grid_cell_width = cell_size.x
var grid_dimensions = get_used_rect()

var tile_id_types = {0: 'dark_grass', 1: 'grass', 2: 'dirt', 3: 'lowhills', 4: 'forest', 5: 'lightforest', 6: 'marsh', 
						7: 'hillforest', 8: 'mountain', 9: 'snow', 10: 'water', 11: 'deepwater', 12: 'road'}
var impassable_tile_ids = [10, 11] # Tile id 11 'deepwater' considered impassable


func _ready() -> void:
	return # Temp skip check. TODO: reenable
	### Map integrity checks ###
	# Check for vacant cells in tilemap:
	if len(get_used_cells()) != grid_dimensions.end.x * grid_dimensions.end.y:
		print('ERROR: ', grid_dimensions.end.x * grid_dimensions.end.y - len(get_used_cells()), ' cells missing from tilemap: ', self.name)
		for x in range(grid_dimensions.end.x):
			for y in range(grid_dimensions.end.y):
				if Vector2(x, y) + grid_offset in get_used_cells():
					continue
				print(Vector2(x, y))
	# Check all terrain types are defined in tile_id_types:
	var detected_cell_ids = {}
	for cell in get_used_cells():
		detected_cell_ids[get_cellv(cell)] = true
	for cell_id in detected_cell_ids.keys():
		if cell_id in tile_id_types.keys():
			continue
		print('ERROR: terrain type not defined in ', self.name, ' for cell id: ', cell_id)


func _is_left(point: Vector2, a: Vector2, b: Vector2):
     return ((b.x - a.x)*(point.y - a.y) - (b.y - a.y)*(point.x - a.x)) < 0


func get_cell_from_coordinates(point: Vector2):
	### Converts global coordinates into cell grid coordinates. ###
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


func get_coordinates_from_cell(cell: Vector2, centred = false):
	cell -= grid_offset
	### Returns top right corner global coordinates of cell grid position
	var coordinates = Vector2(cell.x * grid_cell_width, cell.y * grid_cell_height)
	# Handle offsets for odd columns if hex grid:
	if self.cell_half_offset == 0: # offset in the x coordinate: (pointy top)
		if int(cell.y) % 2 != 0:
			coordinates.x += grid_cell_width / 2
	elif self.cell_half_offset == 1: # offset in y coordinate (flat top)
		if int(cell.x) % 2 != 0:
			coordinates.y += grid_cell_height / 2
	if centred: 
		coordinates += cell_size/2
	return coordinates


func is_outside_map_bounds(cell):
	cell -= grid_offset
	return cell.x < 0 or cell.y < 0 or cell.x >= grid_dimensions.end.x or cell.y >= grid_dimensions.end.y


func _calculate_point_index(cell):
	return cell.x + grid_dimensions.end.x * cell.y


func create_astar_node(terrain_dict=null, obstacles=[]):
	var astar_node = AStar.new()
	
	var walkable_cells_list = []
	for tile_id in impassable_tile_ids:
		obstacles += get_used_cells_by_id(tile_id)

	for cell in self.get_used_cells():
		if cell in obstacles:
			continue
		walkable_cells_list.append(cell)
		var cell_index = _calculate_point_index(cell)
		# Set weight for tile using unit move speeds
		var weight = 100
		var tile_id = self.get_cellv(cell)
		if terrain_dict:
			# Weight is multiplied to reduce effect of random addition which is used for tie-breaking.
			weight = terrain_dict[tile_id_types[tile_id]] * 100
		astar_node.add_point(cell_index, Vector3(cell.x, cell.y, 0.0), weight + randf())

	for cell in walkable_cells_list:
		var cell_index = _calculate_point_index(cell)
		var neighbouring_cells = get_neighbours(cell)
		for neighbour_cell in neighbouring_cells:
			var neighbour_index = _calculate_point_index(neighbour_cell)
			if not astar_node.has_point(neighbour_index):
				continue
			astar_node.connect_points(cell_index, neighbour_index, false)
	
	#### Debugging ####
	# Inefficient vertical path chosen on odd columns using weights 1000 and 5000
	#var point_path_ids = astar_node.get_id_path(_calculate_point_index(path_start_position), _calculate_point_index(path_end_position))
	#var total_weight = 0
	#for x in point_path_ids:
	#	total_weight += astar_node.get_point_weight_scale(x)
	#print(total_weight)
	##################
	return astar_node


func find_path(start_pos, end_pos, astar_node, as_cell_coords=false, obstacles=[]):
	var path_start_position = get_cell_from_coordinates(start_pos)
	var path_end_position = get_cell_from_coordinates(end_pos)
	if not path_end_position: 
		# Out of bounds
		return []
	if self.get_cellv(path_end_position) in impassable_tile_ids or self.get_cellv(path_start_position) in impassable_tile_ids:
		# Path begins or ends on impassable terrain
		return []
	# Disable obstacles in astar node:
	for obstacle in obstacles:
		astar_node.set_point_disabled(_calculate_point_index(obstacle))
	var cell_path = PoolVector2Array([])
	for p in astar_node.get_point_path(_calculate_point_index(path_start_position), _calculate_point_index(path_end_position)):
		if as_cell_coords:
			cell_path.append(Vector2(p.x, p.y))
		else:
			cell_path.append(get_coordinates_from_cell(Vector2(p.x, p.y), true))
	# Reset obstacles
	for obstacle in obstacles:
		astar_node.set_point_disabled(_calculate_point_index(obstacle), false)
	return cell_path


func find_path_for_time(cell_path, base_speed, milliseconds, terrain_dict):
	var cell_path_truncated = PoolVector2Array([])
	for i in range(len(cell_path)-1):
		var cell_distance
		var travel_time
		if self.cell_half_offset == 0: # Pointy top hex grid
			if cell_path[i+1].y == cell_path[i].y:
				# Horizontal movement
				cell_distance = cell_size.x
			else:
				cell_distance = sqrt((pow(cell_size.y , 2) + pow((cell_size.x/2), 2)))
		elif self.cell_half_offset == 1: # Flat top hex grid
			if cell_path[i+1].x == cell_path[i].x:
				# Horizontal movement
				cell_distance = cell_size.y
			else:
				cell_distance = sqrt((pow(cell_size.x , 2) + pow((cell_size.y/2), 2)))
		else: # Square grid
			if cell_path[i+1].x != cell_path[i].x and cell_path[i+1].y != cell_path[i].y:
				# Diagonal movement
				cell_distance = sqrt(pow(cell_size.x, 2) + pow(cell_size.y, 2)) 
			else:
				cell_distance = cell_size.x
		travel_time = (cell_distance * terrain_dict[get_tile_terrain(cell_path[i+1])])/base_speed
		if milliseconds - travel_time < 0:
			break
		milliseconds -= travel_time * 1000
		cell_path_truncated.append(cell_path[i+1])
	return cell_path_truncated


func get_time_for_path(cell_path, base_speed, terrain_dict):
	var milliseconds = 0
	for i in range(len(cell_path)-1):
		var cell_distance
		var travel_time
		if self.cell_half_offset == 0: # Pointy top hex grid
			if cell_path[i+1].y == cell_path[i].y:
				# Horizontal movement
				cell_distance = cell_size.x
			else:
				cell_distance = sqrt((pow(cell_size.y , 2) + pow((cell_size.x/2), 2)))
		elif self.cell_half_offset == 1: # Flat top hex grid
			if cell_path[i+1].x == cell_path[i].x:
				# Horizontal movement
				cell_distance = cell_size.y
			else:
				cell_distance = sqrt((pow(cell_size.x , 2) + pow((cell_size.y/2), 2)))
		else: # Square grid
			if cell_path[i+1].x != cell_path[i].x and cell_path[i+1].y != cell_path[i].y:
				# Diagonal movement
				cell_distance = sqrt(pow(cell_size.x, 2) + pow(cell_size.y, 2)) 
			else:
				cell_distance = cell_size.x
		travel_time = (cell_distance * terrain_dict[get_tile_terrain(cell_path[i+1])])/base_speed * 1000
		milliseconds += travel_time
	return milliseconds
	

func get_tile_terrain(cell):
	if self.get_cellv(cell) == -1:		# Debugging
		print(cell)
	return tile_id_types[self.get_cellv(cell)]


func get_cellv(cell: Vector2):
	# Override to handle grid_offset
	cell -= grid_offset
	return get_cell(cell.x, cell.y)


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


func get_neighbours(cell, radius=1, include_self = false):
	var neighbouring_cells
	var neighbouring_cells_within_map = PoolVector2Array([])
	if self.cell_half_offset == 2: # no offset: squares
		neighbouring_cells = PoolVector2Array([
			Vector2(cell.x - 1, cell.y - 1),
			Vector2(cell.x - 1, cell.y),
			Vector2(cell.x - 1, cell.y + 1),
			Vector2(cell.x, cell.y - 1),
			Vector2(cell.x, cell.y + 1),
			Vector2(cell.x + 1, cell.y - 1),
			Vector2(cell.x + 1, cell.y),
			Vector2(cell.x + 1, cell.y + 1)])
	elif self.cell_half_offset == 1: # Flat-top hex grid
		if fmod(cell.x, 2) != 0:
			neighbouring_cells = PoolVector2Array([
				Vector2(cell.x, cell.y - 1),
				Vector2(cell.x + 1, cell.y - 1),
				Vector2(cell.x + 1, cell.y),
				Vector2(cell.x, cell.y + 1),
				Vector2(cell.x - 1, cell.y),
				Vector2(cell.x - 1, cell.y - 1)])
		else:
			neighbouring_cells = PoolVector2Array([
				Vector2(cell.x, cell.y - 1),
				Vector2(cell.x + 1, cell.y),
				Vector2(cell.x + 1, cell.y + 1),
				Vector2(cell.x, cell.y + 1),
				Vector2(cell.x - 1, cell.y + 1),
				Vector2(cell.x - 1, cell.y)])
	else: # Pointy-top hex grid
		if fmod(cell.y, 2) != 0:
			neighbouring_cells = PoolVector2Array([
				Vector2(cell.x, cell.y - 1),
				Vector2(cell.x + 1, cell.y),
				Vector2(cell.x, cell.y + 1),
				Vector2(cell.x - 1, cell.y - 1),
				Vector2(cell.x - 1, cell.y),
				Vector2(cell.x - 1, cell.y + 1)])
		else:
			neighbouring_cells = PoolVector2Array([
				Vector2(cell.x + 1, cell.y - 1),
				Vector2(cell.x + 1, cell.y),
				Vector2(cell.x + 1, cell.y + 1),
				Vector2(cell.x, cell.y + 1),
				Vector2(cell.x - 1, cell.y),
				Vector2(cell.x, cell.y - 1)])
	for neighbour_cell in neighbouring_cells:
		if not is_outside_map_bounds(neighbour_cell):
			neighbouring_cells_within_map.append(neighbour_cell)

	# Get cells in radius from cell recursively:
	var new_cells = PoolVector2Array([])
	new_cells.append_array(neighbouring_cells_within_map)
	if radius > 1:
		for cell2 in new_cells:
			new_cells = PoolVector2Array([])
			for cell3 in get_neighbours(cell2, radius-1):
				if cell3 in new_cells or cell3 in neighbouring_cells_within_map or cell3 == cell:
					continue
				new_cells.append(cell3)
			neighbouring_cells_within_map.append_array(new_cells)
	if include_self:
		neighbouring_cells_within_map.append(cell)
	return neighbouring_cells_within_map