extends Node2D

onready var planned_path_line : Line2D = $PlannedPath
onready var goal_sprite : Sprite = $GoalSprite
onready var tilemap : Node2D = get_parent().map.tilemap
onready var map : Node2D = get_parent().map
onready var unit_manager : Node2D = get_parent()
onready var turn_manager : Node2D = get_parent().get_parent().turn_manager
#onready var selected_unit : Node2D = get_parent().selected_unit
#onready var sprite : Sprite = $Sprite

var base_speed : = 30	# Speed is calculated as base_speed / terrain_speed
var unit_type
var team
var terrain_dict
var planned_path : = PoolVector2Array()
var smoothed_planned_path : = PoolVector2Array()
var occupied_cells = PoolVector2Array()
var last_cell
var second_last_cell
var goal : = Vector2()
var in_combat = null

var speed : float
var move_distance : float


func _ready() -> void:	
	set_process(false)
	occupied_cells = tilemap.get_neighbours(tilemap.get_cell_from_coordinates(self.position), 1, true)
	return


func _process(delta: float) -> void:
	# Use terrain speed for next cell in path (rather than current position):
	if len(planned_path) > 0:
		speed = base_speed / terrain_dict[tilemap.get_tile_terrain(
			tilemap.get_cell_from_coordinates( planned_path[0] ))]
		move_distance = speed * delta

	# Draw unit path and goal
	planned_path_line.clear_points()
	if self.goal:
		planned_path_line.add_point(Vector2(0,0))
		# Adding extra beginning points for smoothing (at severity=3)
		if len(self.smoothed_planned_path) > 1:
			planned_path_line.add_point((self.smoothed_planned_path[0] - position)/2)
			planned_path_line.add_point((((self.smoothed_planned_path[0] - position)/2) + (self.smoothed_planned_path[0] - position) + (self.smoothed_planned_path[1] - position))/3)
		for point in self.smoothed_planned_path:
			planned_path_line.add_point(point - position)
		# Remove smoothed-past point:
		if planned_path_line.get_point_count() > 3:
			planned_path_line.remove_point(3)
		goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.goal), true) - self.position
		if tilemap.get_cell_from_coordinates(self.goal) == tilemap.get_cell_from_coordinates(self.position):
			# Arrived at goal
			self.goal = Vector2(0,0)
			#self.goal_sprite.visible = false
			self.goal_sprite.position = Vector2(0,0)
			
	# Moved to new cell, update displayed path line and occupied_cells
	if occupied_cells[0] != tilemap.get_cell_from_coordinates(self.position):
		if len(smoothed_planned_path) > 2:
			self.smoothed_planned_path.remove(0)
			# Square tilemap has doubled points in line. Remove extra: 
			if tilemap.cell_half_offset == 2:
				self.smoothed_planned_path.remove(0)
		# Update occupied_cells
		#occupied_cells = [tilemap.get_cell_from_coordinates(self.position)]
		occupied_cells = tilemap.get_neighbours(tilemap.get_cell_from_coordinates(self.position), 1, true)
	return


func _move_along_path(move_distance: float) -> void:
	# If already in planned cell and past the midway point, remove it from path to prevent backtracking.
	if len(planned_path) > 1 and tilemap.get_cell_from_coordinates(planned_path[0]) == tilemap.get_cell_from_coordinates(self.position):
		# Already closer to next cell, don't go to middle of current cell.
		if (planned_path[0]-planned_path[1]).length() > (tilemap.get_cell_from_coordinates(self.position)-planned_path[1]).length():
			planned_path.remove(0)
	
	var start_point : = position
	for i in range(planned_path.size()):
		var distance_to_next : = start_point.distance_to(planned_path[0])
		if move_distance <= distance_to_next:
			position = start_point.linear_interpolate(planned_path[0], move_distance / distance_to_next)
			break
		else:
			if len(planned_path) == 1:
				position = planned_path[0]
				planned_path.remove(0)
			else:
				move_distance -= distance_to_next
				start_point = planned_path[0]
				planned_path.remove(0)


func set_goal(goal_to_set, path_to_set=null, avoid_teammates=false):
	# Update the goal and path for a unit
	if tilemap.get_cellv(tilemap.get_cell_from_coordinates(goal_to_set)) in tilemap.impassable_tile_ids:
		# Goal is in impassable terrain
		return false
	self.goal = goal_to_set
	if path_to_set:
		self.planned_path = path_to_set
	# Calculate path if not provided:
	else:
		self.planned_path = self.calc_unit_path(goal_to_set, false, avoid_teammates)
		if len(self.planned_path) > 0: #TODO remove is bad if on the far side to next cell -- could cut corners.
			self.planned_path.remove(0)
	# Create Smoothed planned_path for display on map:
	self.smoothed_planned_path = map.smooth(self.planned_path)
	############ Repeating below as _process begins off, can change if this design is changed ### TODO: create as func?
	self.planned_path_line.clear_points()
	planned_path_line.add_point(Vector2(0,0))
	# Adding extra beginning points for smoothing (at severity=3)
	if len(self.smoothed_planned_path) > 1:
		planned_path_line.add_point((Vector2(0,0) + (self.smoothed_planned_path[0] - position))/2)
		planned_path_line.add_point((((self.smoothed_planned_path[0] - position)/2) + (self.smoothed_planned_path[0] - position) + (self.smoothed_planned_path[1] - position))/3)
	for point in self.smoothed_planned_path:
		planned_path_line.add_point(point - position)
	if planned_path_line.get_point_count() > 3:
		# Remove smoothed-past point:
		planned_path_line.remove_point(3)		
	############ Finished repeat ###
	self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.goal), true) - self.position
	toggle_overlay(unit_manager.overlay_on)


func select_unit(select=true):
	self.toggle_overlay(select or unit_manager.overlay_on)
	self.selected_poly.visible = select
	# Update unit_manager:
	if select:
		if unit_manager.selected_unit:
			unit_manager.selected_unit.select_unit(false)
		unit_manager.selected_unit = self


func calc_path_cost(path):
	if len(path) == 0:
		return 0
	path.remove(0)
	var cost = 0
#	if not path:
#		path = self.planned_path
	for p in path:
		cost += terrain_dict[tilemap.get_tile_terrain(p)]
	return cost


func calc_unit_path(goal_to_set, as_cell_coords = false, avoid_teammates = false, obstacles = PoolVector2Array()):
		# Navigate around teammates:
		if avoid_teammates:
			for unit in unit_manager.unit_list:
				if unit == self or unit.team != self.team:
					continue
				if tilemap.get_cell_from_coordinates(unit.position) == tilemap.get_cell_from_coordinates(goal_to_set):
					continue
				#obstacles.append(tilemap.get_cell_from_coordinates(unit.position))
				obstacles += unit.occupied_cells
		var path = tilemap.find_path_or_closest(self.position, goal_to_set, unit_manager.unit_astar_nodes[self.unit_type], as_cell_coords, obstacles)
		return path
		

func toggle_overlay(toggle, force_display_path=false):
	self.goal_sprite.visible = toggle and in_combat == null and self.team == turn_manager.active_player
	self.planned_path_line.visible = ( toggle or force_display_path ) and in_combat == null and self.team == turn_manager.active_player
	
	