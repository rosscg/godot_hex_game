extends Node2D

onready var planned_path_line : Line2D = $PlannedPath
onready var goal_sprite : Sprite = $GoalSprite
onready var selected_poly : Polygon2D = $SelectedPoly
onready var tilemap : Node2D = get_parent().map.tilemap
onready var unit_manager : Node2D = get_parent()
#onready var selected_unit : Node2D = get_parent().selected_unit
#onready var sprite : Sprite = $Sprite

var base_speed : = 100	# Speed is calculated as base_speed / terrain_speed
var strength
var unit_type
var terrain_dict
var planned_path : = PoolVector2Array()
var goal : = Vector2()
var astar_node
var occupied_cells = []
#var occupied_cells_local = []


func init(unit_type, data_dict, strength, start_coordinates):
	self.unit_type = unit_type
	self.terrain_dict = data_dict
	self.strength = strength
	self.position = start_coordinates
	var res = load('res://assets/units/' + unit_type + '.png')
	get_node("Sprite").texture = res


func _ready() -> void:
	set_process(false)

	occupied_cells = [tilemap.get_cell_coordinates(self.position)]
	
	# Each unit stores its own astar node
	astar_node = tilemap.create_astar_node(terrain_dict)
	
	# Functionality used for units which occupy multiple cells (WIP):
#	occupied_cells_local = PoolVector2Array([Vector2(0, 0)])
#	for i in occupied_cells_local:
#		occupied_cells.append(tilemap.get_cell_coordinates(self.position) + i)
	return


func _process(delta: float) -> void:
	# Speed based on first cell occupied in occupied_cells:
	var speed : float = base_speed / terrain_dict[tilemap.get_tile_terrain(occupied_cells[0])]
	var move_distance : = speed * delta
	_move_along_path(move_distance)

	# Update occupied_cells occupied
	occupied_cells = [tilemap.get_cell_coordinates(self.position)]
#	for i in occupied_cells_local:
#		occupied_cells.append(tilemap.get_cell_coordinates(self.position) + i)
	
	# Draw unit path and goal
	planned_path_line.clear_points()
	if self.goal:
		planned_path_line.add_point(Vector2(0,0))
		for point in self.planned_path:
			planned_path_line.add_point(point - position)
		goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_coordinates(self.goal), true) - self.position
		if tilemap.get_cell_coordinates(self.goal) == tilemap.get_cell_coordinates(self.position):
			# Arrived at goal
			self.goal = Vector2(0,0)
			self.goal_sprite.visible = false
	return


func _move_along_path(move_distance: float) -> void:
	var start_point : = position
	for i in range(planned_path.size()):
		var distance_to_next : = start_point.distance_to(planned_path[0])
		if move_distance <= distance_to_next:
			position = start_point.linear_interpolate(planned_path[0], move_distance / distance_to_next)
			break
		else:
			move_distance -= distance_to_next
			start_point = planned_path[0]
			planned_path.remove(0)
	update()


func _draw():
	# Full strength bar is 20 px wide:
	draw_line(Vector2(-10,14), Vector2((-10+float(strength)/10*20), 14), Color(255, 0, 0), 3)
	# Circle indicates unit needs orders:
	if len(planned_path) == 0 and strength > 0:
		draw_circle(Vector2(12,-12), 4, Color( 0, 0, 1, 1 ))
	# Draw hexes in surrounding cells:	
#	var hex_points = PoolVector2Array([Vector2(-5,-9), Vector2(5,-9), Vector2(9,0), Vector2(5,9), 
#										Vector2(-5,9), Vector2(-9,0), Vector2(-5,-9)])
#	for i in occupied_cells_local:
#		var world_offset = tilemap.get_coordinates_from_hex(i)
#		if i == occupied_cells_local[0]:
#			pass
#		var local_hex_points = []
#		for p in hex_points:
#			local_hex_points.append(p + world_offset)
#		draw_colored_polygon(local_hex_points, Color( 0.55, 0, 0, 1 ))
#		draw_polyline(local_hex_points, Color( 0.18, 0.31, 0.31, 1 ), 3.0)
	return


func take_damage(damage):
	if strength > damage:
		strength -= damage
		update()
		return false
	else:
		strength = 0
		update()
		planned_path = PoolVector2Array([]) # Stop moving
		#$AnimatedSprite.play($AnimatedSprite.animation + '_die')
		#yield($AnimatedSprite, "animation_finished" )
		if get_parent().selected_unit == self:
			get_parent().selected_unit = null
		queue_free()
		return true


func set_goal(goal_to_set, path_to_set=null):
	# Update the goal and path for a unit
	self.goal = goal_to_set
	if path_to_set:
		self.planned_path = path_to_set
	# Calculate path if not provided:
	else:
		var global_path = tilemap.find_path(self.position, goal_to_set, self.astar_node)
		self.planned_path = []
		for p in global_path:
			self.planned_path.append(tilemap.get_coordinates_from_cell(p, true))
		self.planned_path.remove(0)
	### Repeating below as _process begins off, can change if this design is changed ###
	self.planned_path_line.clear_points()
	self.planned_path_line.add_point(Vector2(0,0))
	for point in self.planned_path:
		planned_path_line.add_point(point - position)
	self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_coordinates(self.goal), true) - self.position
	### Finished repeat ###
	self.goal_sprite.visible = unit_manager.overlay_on and self.goal != Vector2(0,0)
	self.planned_path_line.visible = unit_manager.overlay_on
	self.update()


func select_unit(select=true):
	self.goal_sprite.visible = (select or unit_manager.overlay_on) and self.goal != Vector2(0,0)
	self.planned_path_line.visible = (select or unit_manager.overlay_on)
	self.selected_poly.visible = select
	# Update unit_manager:
	if select:
		if unit_manager.selected_unit:
			unit_manager.selected_unit.select_unit(false)
		unit_manager.selected_unit = self


func calc_path_cost(path=null):
	var cost = 0
	if not path:
		path = self.path
	for p in path:
		cost += terrain_dict[tilemap.get_tile_terrain(p)]
	return cost