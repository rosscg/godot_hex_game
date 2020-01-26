extends "res://scripts/Unit.gd"

onready var status_sprite : AnimatedSprite = $StatusSprite
onready var selected_poly : Polygon2D = $SelectedPoly

var strength
var stored_path : = PoolVector2Array()
#var occupied_cells_local = []


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
		map.cell_array[cell.x][cell.y] = self

	# Each unit stores its own astar node
	astar_node = tilemap.create_astar_node(terrain_dict)

	return


func _process(delta: float) -> void:
	._process(delta)
	# Temporarily store planned path elsewhere during combat:
	if in_combat:
		if len(planned_path) > 0:
			if len(self.stored_path) == 0:
				self.stored_path.append_array(planned_path)
			# Check if in_combat unit not killed by another unit:
			if is_instance_valid(in_combat):
				self.planned_path = PoolVector2Array([in_combat.position])
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
	# Update occupied_cells
	occupied_cells = [tilemap.get_cell_from_coordinates(self.position)]
	# Redraw health bars etc
	update()
	return


func _move_along_path(move_distance: float) -> void:
	# Wait if next cell is still occupied:
	if len(planned_path) > 0:
		var next_cell = tilemap.get_cell_from_coordinates(planned_path[0])
		if map.cell_array[next_cell.x][next_cell.y] and map.cell_array[next_cell.x][next_cell.y] != self:
			# Find alternate route unless the occupied cell is the goal, in which case, wait.
			if next_cell != tilemap.get_cell_from_coordinates(self.goal):
				self.planned_path = self.calc_unit_path(self.goal, false, [next_cell])
				self.planned_path.remove(0)
			# If waiting, move to centre of cell:
			else:
				self.planned_path.insert(0, tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.position), true))
		._move_along_path(move_distance)
	# Update map cell array
	var cell_point = tilemap.get_cell_from_coordinates(self.position)
	if cell_point != occupied_cells[0]:
		map.cell_array[occupied_cells[0].x][occupied_cells[0].y] = null
		map.cell_array[cell_point.x][cell_point.y] = self


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
		queue_free()
		return true


func toggle_combat(opponent):
	self.in_combat = opponent
	if opponent:
		self.status_sprite.visible = true
		self.goal_sprite.visible = false
	else:
		self.status_sprite.visible = false
		self.goal_sprite.visible = self.goal and (unit_manager.overlay_on or unit_manager.selected_unit == self) and \
										self.team == get_node("/root/Main").turn_manager.active_player