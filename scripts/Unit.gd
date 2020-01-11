extends Node2D

#var unit_types = ['fencer', 'general', 'bandit', 'footpad']
var unit_types = ['fencer', 'marshal', 'lieutenant', 'spearman']
var speed : = 100.0
var strength : = randi()%11 + 1
var terrain_dict = {'grass': 1000, 'marsh': 2000, 'mountain': 5000}


var path : = PoolVector2Array()
var goal : = Vector2()
var current_hex


func _ready() -> void:
	set_process(false)
	$AnimatedSprite.animation = unit_types[randi() % unit_types.size()]


func _process(delta: float) -> void:
	var move_distance : = speed * delta
	_move_along_path(move_distance)


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
	# Full strength bar is 40 px wide
	draw_line(Vector2(-20,30), Vector2((-20+float(strength)/10*40), 30), Color(255, 0, 0), 4)
	# Unit needs orders:
	if len(path) == 0 and strength > 0:
		draw_circle(Vector2(16,-20), 5, Color( 0, 0, 1, 1 ))


func take_damage(damage):
	if strength > damage:
		strength -= damage
		update()
		return false
	else:
		strength = 0
		update()
		path = PoolVector2Array([]) # Stop moving
		$AnimatedSprite.play($AnimatedSprite.animation + '_die')
		yield($AnimatedSprite, "animation_finished" )
		queue_free()
		return true


func set_goal(goal_to_set):
	self.goal = goal_to_set