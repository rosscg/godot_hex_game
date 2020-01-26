extends Node2D

onready var planned_path_line : Line2D = $PlannedPath
onready var orders_path_line : Line2D = $OrdersPath
onready var goal_sprite : Sprite = $GoalSprite
#onready var selected_poly : Polygon2D = $SelectedPoly
onready var tilemap : Node2D = get_parent().map.tilemap
onready var map : Node2D = get_parent().map
onready var unit_manager : Node2D = get_parent()

var base_speed : = 30	# Speed is calculated as base_speed / terrain_speed
var team
var unit_type
var terrain_dict
var planned_path : = PoolVector2Array()
var goal : = Vector2()
var astar_node
#var occupied_cells = []
var in_combat = null

var target_unit
var target_unit_orders
var home_coordinates


func init(unit_type, data_dict, strength, home_coordinates, team=1):
	self.unit_type = unit_type
	self.terrain_dict = data_dict
	self.home_coordinates = home_coordinates
	self.position = self.home_coordinates
	self.team = team
	self.target_unit = null
	self.target_unit_orders = null
	self.base_speed *= 6


func _ready() -> void:
	set_process(false)
	# Each unit stores its own astar node
	astar_node = tilemap.create_astar_node(terrain_dict)
	return


func _process(delta: float) -> void:
	# Speed based on first cell occupied in occupied_cells:
	var speed : float = base_speed / terrain_dict[tilemap.get_tile_terrain(tilemap.get_cell_from_coordinates(self.position))]
	var move_distance : = speed * delta

	_move_along_path(move_distance)
	_pass_message()
	
	# Draw unit path and goal
	planned_path_line.clear_points()
	if self.goal:
		planned_path_line.add_point(Vector2(0,0))
		for point in map.smooth(self.planned_path):
			planned_path_line.add_point(point - position)
		if tilemap.get_cell_from_coordinates(self.goal) == tilemap.get_cell_from_coordinates(self.position):
			# Arrived at goal
			self.goal = Vector2(0,0)
	#TODO: Slow, only update if unit has moved from first point in line.
	if self.target_unit_orders:
		orders_path_line.clear_points()
		#orders_path_line.add_point(self.target_unit.position - self.position)
		for point in map.smooth(self.target_unit.calc_unit_path(self.target_unit_orders)):
			planned_path_line.add_point(point - self.position)
		self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position
	else:
		self.goal_sprite.visible = false
	if self.position == self.home_coordinates and self.target_unit_orders == null:
		self.queue_free()
		unit_manager.messenger_list.erase(self)
	return


func _move_along_path(move_distance: float) -> void:
	if planned_path[0].x > self.position.x:
		get_node('AnimatedSprite').flip_h = true
	else:
		get_node('AnimatedSprite').flip_h = false
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
			else:
				move_distance -= distance_to_next
				start_point = planned_path[0]
				planned_path.remove(0)



func set_goal(goal_to_set, path_to_set=null):
	# Update the goal and path for a unit
	if tilemap.get_cellv(tilemap.get_cell_from_coordinates(goal_to_set)) in tilemap.impassable_tile_ids:
		# Goal is in impassable terrain
		return
	self.goal = goal_to_set
	if path_to_set:
		self.planned_path = path_to_set
	# Calculate path if not provided:
	else:
		self.planned_path = self.calc_unit_path(goal_to_set, false)
		if len(self.planned_path) > 0: #TODO remove is bad is on the far side to next cell -- could cut corners.
			self.planned_path.remove(0)
	### Repeating below as _process begins off, can change if this design is changed ###
	self.planned_path_line.clear_points()
	self.planned_path_line.add_point(Vector2(0,0))
	for point in map.smooth(self.planned_path):
		planned_path_line.add_point(point - position)
	
	if self.target_unit_orders:
		orders_path_line.clear_points()
		#orders_path_line.add_point(self.target_unit.position - self.position)
		for point in map.smooth(self.target_unit.calc_unit_path(self.target_unit_orders)):
			planned_path_line.add_point(point - self.position)
		self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position
		self.goal_sprite.visible = true

	#self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.goal), true) - self.position
	### Finished repeat ###
	#self.goal_sprite.visible = unit_manager.overlay_on and self.goal != Vector2(0,0)
	self.planned_path_line.visible = unit_manager.overlay_on
	self.orders_path_line.visible = unit_manager.overlay_on
	self.goal_sprite.visible = unit_manager.overlay_on
	self.update()



func calc_unit_path(goal_to_set, as_cell_coords = false, obstacles = []):
		var path = tilemap.find_path(self.position, goal_to_set, self.astar_node, as_cell_coords, obstacles)
		return path	


func set_message(target_unit, target_unit_orders):
	self.target_unit = target_unit
	self.target_unit_orders = target_unit_orders
	self.set_goal(target_unit.position)
	#self.goal_sprite.position = target_unit_orders
	#self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position
	return


func _pass_message():
	if self.target_unit and tilemap.get_cell_from_coordinates(self.position) == \
			tilemap.get_cell_from_coordinates(self.target_unit.position):
		print('giving orders')
		self.target_unit.set_goal(self.target_unit_orders)
		self.target_unit = null
		self.target_unit_orders = null
		self.set_goal(self.home_coordinates)