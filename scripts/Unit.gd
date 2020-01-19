extends Node2D

onready var planned_path_line : Line2D = $PlannedPath
onready var goal_sprite : Sprite = $GoalSprite
onready var status_sprite : AnimatedSprite = $StatusSprite
onready var selected_poly : Polygon2D = $SelectedPoly
onready var tilemap : Node2D = get_parent().map.tilemap
onready var map : Node2D = get_parent().map
onready var unit_manager : Node2D = get_parent()
#onready var selected_unit : Node2D = get_parent().selected_unit
#onready var sprite : Sprite = $Sprite

var team_sprite_dict = {1: 'team_red', 2: 'team_blue'}
var base_speed : = 30	# Speed is calculated as base_speed / terrain_speed
var team
var strength
var unit_type
var terrain_dict
var stored_path : = PoolVector2Array()
var planned_path : = PoolVector2Array()
var goal : = Vector2()
var astar_node
var occupied_cells = []
var in_combat = null
#var occupied_cells_local = []

#var mask_tex = preload('res://assets/mask_test.png')
#var light

func init(unit_type, data_dict, strength, start_coordinates, team=1):
	self.unit_type = unit_type
	self.terrain_dict = data_dict
	self.strength = strength
	self.position = start_coordinates
	self.team = team
	var res = load('res://assets/units/' + unit_type + '.png')
	get_node("Sprite").texture = res
	get_node("TeamSprite").texture = load('res://assets/units/' + team_sprite_dict[team] + '.png')


func _update_fow():
	for cell in occupied_cells:
		for cell2 in tilemap.get_neighbours(cell, 3):
			map.get_node('Viewport').get_node('fow').fog_cells.erase(cell2)
	
func _ready() -> void:
	set_process(false)
	
	occupied_cells = [tilemap.get_cell_from_coordinates(self.position)]
	for cell in occupied_cells:
		map.cell_array[cell.x][cell.y] = self

	# Each unit stores its own astar node
	astar_node = tilemap.create_astar_node(terrain_dict)
	
	# Functionality used for units which occupy multiple cells (WIP):
#	occupied_cells_local = PoolVector2Array([Vector2(0, 0)])
#	for i in occupied_cells_local:
#		occupied_cells.append(tilemap.get_cell_from_coordinates(self.position) + i)
#    var imageTexture = TextureRect.ImageTexture.new()
#    var dynImage = Image.new()
#    dynImage.create(256,256,false,Image.FORMAT_DXT5)
#    dynImage.fill(Color(1,0,0,1))
#    imageTexture.create_from_image(dynImage)
#    self.texture = imageTexture

# Engine currently doesn't support multiple 2d light masks.
#	self.light = Light2D.new()
#	self.light.texture = mask_tex
#	self.light.range_item_cull_mask = map.get_node("MapImageFOW").light_mask
#	self.light.mode = 3
#	self.light.enabled = true
#	self.light.scale = Vector2(10, 10)
#	self.add_child(light)
	
	return


func _process(delta: float) -> void:
	# Speed based on first cell occupied in occupied_cells:
	var speed : float = base_speed / terrain_dict[tilemap.get_tile_terrain(occupied_cells[0])]
	var move_distance : = speed * delta

	# Temporarily store planned path elsewhere during combat:
	if in_combat:
		if len(planned_path) > 0:
			if len(self.stored_path) == 0:
				self.stored_path.append_array(planned_path)
			#self.planned_path = PoolVector2Array([])
			if is_instance_valid(in_combat):
				self.planned_path = PoolVector2Array([in_combat.position])
			#	for p in tilemap.find_path(self.position, tilemap.get_coordinates_from_cell(in_combat.occupied_cells[0], true), self.astar_node):
			#		self.planned_path.append(tilemap.get_coordinates_from_cell(p, true))
					#self.planned_path.remove(0)
			else:
				# in_combat unit killed by another unit
				in_combat = null
	else:
		if len(self.stored_path) > 0:
			self.planned_path = PoolVector2Array()
			self.planned_path.append_array(stored_path)
			self.stored_path = PoolVector2Array()

	if in_combat:
		pass
	else:
		_move_along_path(move_distance)

	# Update occupied_cells occupied
	occupied_cells = [tilemap.get_cell_from_coordinates(self.position)]
#	for i in occupied_cells_local:
#		occupied_cells.append(tilemap.get_cell_from_coordinates(self.position) + i)
	
	# Draw unit path and goal
	planned_path_line.clear_points()
	if self.goal:
		planned_path_line.add_point(Vector2(0,0))
		for point in map.smooth(self.planned_path):
			planned_path_line.add_point(point - position)
		goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.goal), true) - self.position
		if tilemap.get_cell_from_coordinates(self.goal) == tilemap.get_cell_from_coordinates(self.position):
			# Arrived at goal
			self.goal = Vector2(0,0)
			self.goal_sprite.visible = false
	return


func _move_along_path(move_distance: float) -> void:
	var start_point : = position
	for i in range(planned_path.size()):
		# Wait if next cell is still occupied:
		var next_cell = tilemap.get_cell_from_coordinates(planned_path[0])
		if map.cell_array[next_cell.x][next_cell.y] and map.cell_array[next_cell.x][next_cell.y] != self:
			break
		var distance_to_next : = start_point.distance_to(planned_path[0])
		if move_distance <= distance_to_next:
			position = start_point.linear_interpolate(planned_path[0], move_distance / distance_to_next)
			break
		else:
			move_distance -= distance_to_next
			start_point = planned_path[0]
			planned_path.remove(0)
	# Update map cell array
	var cell_point = tilemap.get_cell_from_coordinates(self.position)
	if cell_point != occupied_cells[0]:
		map.cell_array[occupied_cells[0].x][occupied_cells[0].y] = null
		map.cell_array[cell_point.x][cell_point.y] = self
	update()


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
		var global_path = tilemap.find_path(self.position, goal_to_set, self.astar_node)
		self.planned_path = PoolVector2Array([])
		for p in global_path:
			self.planned_path.append(tilemap.get_coordinates_from_cell(p, true))
		self.planned_path.remove(0)
	### Repeating below as _process begins off, can change if this design is changed ###
	self.planned_path_line.clear_points()
	self.planned_path_line.add_point(Vector2(0,0))
	for point in map.smooth(self.planned_path):
		planned_path_line.add_point(point - position)
	self.goal_sprite.position = tilemap.get_coordinates_from_cell(tilemap.get_cell_from_coordinates(self.goal), true) - self.position
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
		path = self.planned_path
	for p in path:
		cost += terrain_dict[tilemap.get_tile_terrain(p)]
	return cost


func toggle_combat(opponent):
	self.in_combat = opponent
	if opponent:
		self.status_sprite.visible = true
		self.goal_sprite.visible = false
	else:
		self.status_sprite.visible = false
		self.goal_sprite.visible = self.goal and (unit_manager.overlay_on or unit_manager.selected_unit == self) and \
										self.team == get_node("/root/Main").turn_manager.active_player
	