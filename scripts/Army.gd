extends "res://scripts/Unit.gd"

# Detachment Testing
#var detachment_list = []
#var formation = 'column'
#var orientation = 'N'

onready var status_sprite : AnimatedSprite = $StatusSprite
onready var selected_poly : Polygon2D = $SelectedPoly

var strength
var stored_path : = PoolVector2Array()


func init(unit_type, data_dict, strength, start_coordinates, team=1, team_colour=Color( 0.55, 0, 0, 1 )): #TODO: remove defaults?
	self.team = team
	self.unit_type = unit_type
	self.terrain_dict = data_dict
	
	self.strength = strength
	self.position = start_coordinates
	var res = load('res://assets/units/' + unit_type + '.png')
	get_node("Sprite").texture = res
	get_node("TeamPoly").color = team_colour
	#get_node("TeamSprite").texture = load('res://assets/units/' + team_sprite_dict[team] + '.png')


func _ready() -> void:
	
	set_process(false)
	
	#Add occupied cell to map array
	for cell in occupied_cells:
		map.cell_array[cell.x][cell.y] = self.name

	return


func _process(delta: float) -> void:
	
	var starting_cell = tilemap.get_cell_from_coordinates(self.position)
	
	._process(delta)

	# Detachment Testing	
	# Use slowest move speed when moving with detachments:
#	if len(detachment_list) > 0 and len(planned_path) > 0:
#		var speed_list = [base_speed / terrain_dict[tilemap.get_tile_terrain(
#			tilemap.get_cell_from_coordinates( planned_path[0] ))]]
#		for d in detachment_list:
#			if d.speed > 0:
#				speed_list.append(d.speed)
#		move_distance = speed_list.min() * delta
		
	# Temporarily store planned path elsewhere during combat:
	if in_combat:
		if len(self.planned_path) > 0:
			if len(self.stored_path) == 0:
				self.stored_path.append_array(self.planned_path)
			# Check if in_combat unit not killed by another unit:
			if is_instance_valid(self.in_combat):
				self.planned_path = PoolVector2Array([in_combat.position])
				##############################
				self.planned_path_line.clear_points()
				for point in self.planned_path:
					self.planned_path_line.add_point(point - position)
				###################################
			else:
				in_combat = null
	# Combat over, resume path:
	else:
		if len(self.stored_path) > 0:
			self.planned_path = PoolVector2Array()
			self.planned_path.append_array(stored_path)
			self.stored_path = PoolVector2Array()
	# Halt movement during combat:
	if in_combat:
		pass
	else:
		_move_along_path(move_distance)
		
	if starting_cell != tilemap.get_cell_from_coordinates(self.position):
		
		second_last_cell = last_cell
		last_cell = starting_cell
		
		# Detachment Testing
#		for d in detachment_list:
#			d.update_destination()
			
	# Redraw health bars etc
	update()
	return


func _move_along_path(move_distance: float) -> void:
	# Wait if next cell is still occupied:
	if len(planned_path) > 0:
		var next_cell = tilemap.get_cell_from_coordinates(planned_path[0])
		if map.cell_array[next_cell.x][next_cell.y] and map.cell_array[next_cell.x][next_cell.y] != self.name:
			# Find alternate route unless the occupied cell is the goal, in which case, wait.
			if next_cell != tilemap.get_cell_from_coordinates(self.goal):
				self.planned_path = self.calc_unit_path(self.goal, false, true, PoolVector2Array([next_cell]))
				self.planned_path.remove(0)
			# If waiting, move to centre of cell:
			else:
				self.planned_path.insert(0, tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.position), true))
		._move_along_path(move_distance)
	# Update map cell array
	var cell_point = tilemap.get_cell_from_coordinates(self.position)
	if cell_point != occupied_cells[0]:
		for cell in occupied_cells:
			map.cell_array[cell.x][cell.y] = null
		for cell in tilemap.get_neighbours(tilemap.get_cell_from_coordinates(self.position), 1, true):
			map.cell_array[cell.x][cell.y] = self.name


func _draw():
	# Full strength bar is 20 px wide:
	draw_line(Vector2(-10,14), Vector2((-10+float(strength)/10*20), 14), Color( 0.55, 0, 0, 1), 5)
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
		for cell in occupied_cells:
			map.cell_array[cell.x][cell.y] = null
		#$AnimatedSprite.play($AnimatedSprite.animation + '_die')
		#yield($AnimatedSprite, "animation_finished" )
		if get_parent().selected_unit == self:
			get_parent().selected_unit = null
			
		# Detachment Testing
#		for d in detachment_list:
#			d.queue_free()

		queue_free()
		return true


func toggle_combat(opponent):
	self.in_combat = opponent
	if opponent:
		self.status_sprite.visible = true
		self.goal_sprite.visible = false
		self.planned_path_line.visible = false
	else:
		self.status_sprite.visible = false
		self.goal_sprite.visible = self.goal and (unit_manager.overlay_on or unit_manager.selected_unit == self) and \
										self.team == get_node("/root/Main").turn_manager.active_player
		self.planned_path_line.visible = self.goal and (unit_manager.overlay_on or unit_manager.selected_unit == self) and \
										self.team == get_node("/root/Main").turn_manager.active_player


func get_messenger_time():
	var base_coordinates
	for b in unit_manager.building_list:
		if b["team"] == self.team:
			base_coordinates = b["instance"].position
			# If square tilemap, base spans 2x2 grid so choose a cell middle point:
			if map.tilemap.cell_half_offset == 2:
				base_coordinates += Vector2(map.tilemap.grid_cell_width/2, map.tilemap.grid_cell_width/2)
			break
	var messenger_astar = unit_manager.unit_astar_nodes['messenger']
	var messenger_dict = unit_manager.unit_data['messenger']
	var messenger_path = tilemap.find_path(base_coordinates, self.position, messenger_astar, true)
	var messenger_time = tilemap.get_time_for_path(messenger_path, self.base_speed * 3, messenger_dict) # TODO: Keep multiplied synchronous
	return messenger_time
	
	
func process_logic():
	# Recalculate path
	if self.goal:
		self.set_goal(self.goal, null, true)
	# Get cells in radius and check for enemies
	var neighbours = tilemap.get_neighbours(occupied_cells[0], 4)
	for cell in neighbours:
		var target_unit = unit_manager.get_unit_in_cell(cell)
		if target_unit and target_unit.team != self.team:
			# Target first unit detected
			self.set_goal(target_unit.position)
			# TODO: instead, calculate propensity to attack per enemy and choose
			# favoured target.
			# TODO: need to reset goal once target dies
			break
