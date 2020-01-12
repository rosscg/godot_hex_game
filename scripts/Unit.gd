extends Node2D

#var unit_types = ['fencer', 'marshal', 'lieutenant', 'spearman']
var base_speed : = 40
var strength : = randi()%11 + 1
var terrain_dict = {'grass': 2, 'water': 20, 'deepwater': 50, 'road': 1, 'dirt': 5, 
					'lowhills': 6, 'forest': 6, 'marsh': 6, 'mountain': 10}

onready var planned_path : Line2D = $PlannedPath
var path : = PoolVector2Array()
var goal : = Vector2()


var current_hexes = []
var current_local_hexes = []
#var unit_size = 4	# unit occupies 4 hexes
onready var tilemap : Node2D = get_parent().map.tilemap


func _ready() -> void:
	set_process(false)
	
	# Deploy new unit on selected hex and all neighbours:
	if fmod(tilemap.get_coordinates_from_hex(position).x, 2) == 0:
		current_local_hexes = PoolVector2Array([
			Vector2(0, 0),
			#Vector2(0, -1),
			#Vector2(1, -1), # unique
			#Vector2(1, 0),
			#Vector2(0, 1),
			#Vector2(-1, -1),  # unique
			#Vector2(-1, 0)
			])
	else:
		current_local_hexes = PoolVector2Array([
			Vector2(0, 0),
			#Vector2(0, -1),
			#Vector2(1, 0),
			#Vector2(1, 1), # unique
			#Vector2(0, 1),
			#Vector2(-1, 1), # unique
			#Vector2(-1, 0)
			])
	for i in current_local_hexes:
		current_hexes.append(tilemap.get_hex_coordinates(self.position) + i)


func _process(delta: float) -> void:
	var speed : float = base_speed / terrain_dict[tilemap.tile_id_types[tilemap.get_cellv(current_hexes[0])]]
	var move_distance : = speed * delta
	_move_along_path(move_distance)

	# Update current_hexes
	current_hexes = []
	for i in current_local_hexes:
		current_hexes.append(tilemap.get_hex_coordinates(self.position) + i)
	
	planned_path.clear_points()
	for point in path:
		planned_path.add_point(point - position)


func _move_along_path(move_distance: float) -> void:
	var start_point : = position
	for i in range(path.size()):
		var distance_to_next : = start_point.distance_to(path[0])
		if move_distance <= distance_to_next:
			position = start_point.linear_interpolate(path[0], move_distance / distance_to_next)
			break
		else:
			move_distance -= distance_to_next
			start_point = path[0]
			path.remove(0)
	update()


func _draw():
	# Full strength bar is 20 px wide
	draw_line(Vector2(-10,12), Vector2((-10+float(strength)/10*20), 12), Color(255, 0, 0), 3)
	# Unit needs orders:
	if len(path) == 0 and strength > 0:
		draw_circle(Vector2(12,-12), 4, Color( 0, 0, 1, 1 ))
		
	var hex_points = PoolVector2Array([Vector2(-5,-9), Vector2(5,-9), Vector2(9,0), Vector2(5,9), 
										Vector2(-5,9), Vector2(-9,0), Vector2(-5,-9)])

	for i in current_local_hexes:
		var world_offset = tilemap.get_coordinates_from_hex(i)
		if i == current_local_hexes[0]:
			pass
		var local_hex_points = []
		for p in hex_points:
			local_hex_points.append(p + world_offset)
		draw_colored_polygon(local_hex_points, Color( 0.55, 0, 0, 1 ))
		draw_polyline(local_hex_points, Color( 0.18, 0.31, 0.31, 1 ), 3.0)


func take_damage(damage):
	if strength > damage:
		strength -= damage
		update()
		return false
	else:
		strength = 0
		update()
		path = PoolVector2Array([]) # Stop moving
		#$AnimatedSprite.play($AnimatedSprite.animation + '_die')
		#yield($AnimatedSprite, "animation_finished" )
		queue_free()
		return true


func set_goal(goal_to_set):
	self.goal = goal_to_set