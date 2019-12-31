extends Area2D

var speed : = 100.0
var path : = PoolVector2Array()# setget set_path
var goal : = Vector2()

func _ready() -> void:
	set_process(false)
	#self.play("idle")
	
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
		
	
#func set_path(value : PoolVector2Array) -> void:
#	path = value
	#if value.size() == 0:
	#	return
	#set_process(true)
	
func _input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton \
    and event.button_index == BUTTON_LEFT \
    and event.is_pressed():
        self.on_click()

func on_click():
    print("Click")