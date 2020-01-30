extends "res://scripts/Unit.gd"

onready var orders_path_line : Line2D = $OrdersPath
onready var orders_goal_sprite : Sprite = $OrdersGoalSprite

var target_unit
var target_unit_orders
var home_coordinates


func init(unit_type, data_dict, strength, home_coordinates, team=1):
	self.team = team
	self.unit_type = unit_type
	self.terrain_dict = data_dict
	
	self.home_coordinates = home_coordinates
	self.position = self.home_coordinates
	self.target_unit = null
	self.target_unit_orders = null
	self.base_speed *= 3 # TODO: keep synchronous with get_messenger_time() in Army.gd


func _process(delta: float) -> void:
	._process(delta)
	_move_along_path(move_distance)
	_pass_message()
	
	# Draw orders line and goal sprite for target unit
	#TODO: Slow, only update if unit has moved from first point in line.
	if self.target_unit_orders:
		orders_path_line.clear_points()
		# TODO: Temp use Straight line for speed:
		orders_path_line.add_point(target_unit.position - self.position)
		orders_path_line.add_point(tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position)
		#for point in map.smooth(self.target_unit.calc_unit_path(self.target_unit_orders)):
		#	orders_path_line.add_point(point - self.position)
		self.orders_goal_sprite.position = tilemap.get_coordinates_from_cell(
											tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position

	# Messenger returned home, deletes self
	if self.position == self.home_coordinates and self.target_unit_orders == null:
		self.queue_free()
		unit_manager.messenger_list.erase(self)
	return


func _move_along_path(move_distance: float) -> void: # TODO: move into parent script.
	if planned_path:
		if planned_path[0].x > self.position.x:
			get_node('AnimatedSprite').flip_h = true
		elif planned_path[0].x < self.position.x:
			get_node('AnimatedSprite').flip_h = false
	._move_along_path(move_distance)



func set_goal(goal_to_set, path_to_set=null, avoid_teammates=false):
	if .set_goal(goal_to_set, path_to_set) == false:
		return # False if impassable terrain
	
	if self.target_unit_orders:
		orders_path_line.clear_points()
		#orders_path_line.add_point(self.target_unit.position - self.position)
		# TODO: Temp use Straight line for speed:
		orders_path_line.add_point(target_unit.position - self.position)
		orders_path_line.add_point(tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position)
		#for point in map.smooth(self.target_unit.calc_unit_path(self.target_unit_orders)):
		#	orders_path_line.add_point(point - self.position)
		self.orders_goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position
		self.toggle_overlay(unit_manager.overlay_on)
		#self.orders_goal_sprite.visible = unit_manager.overlay_on
		#self.orders_path_line.visible = unit_manager.overlay_on


func set_message(target_unit, target_unit_orders):
	self.target_unit = target_unit
	self.target_unit_orders = target_unit_orders
	self.set_goal(target_unit.position)
	#self.goal_sprite.position = target_unit_orders
	#self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(target_unit_orders), true) - self.position
	return


func _pass_message():
	# If reached target unit, give orders and return home:
	if self.target_unit and tilemap.get_cell_from_coordinates(self.position) == \
			tilemap.get_cell_from_coordinates(self.target_unit.position):
		self.target_unit.set_goal(self.target_unit_orders, null, true)
		self.target_unit = null
		self.target_unit_orders = null
		self.orders_path_line.clear_points()
		self.orders_goal_sprite.visible = false
		self.set_goal(self.home_coordinates)


func toggle_overlay(toggle, force_display_path=false):
	.toggle_overlay(toggle)
	orders_path_line.visible = toggle and self.team == turn_manager.active_player
	orders_goal_sprite.visible = toggle and self.team == turn_manager.active_player and self.target_unit != null