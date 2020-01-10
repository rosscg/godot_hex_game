extends Node2D

onready var nav_2d : Navigation2D = $Navigation2D
onready var tilemap : TileMap = get_node("TileMap")
onready var tilemap_overlay : TileMap = get_node("TileMapOverlay")
onready var line_2d : Line2D = $Line2D
onready var character : AnimatedSprite = $Character
onready var distance_label : Label = $Distance_Label
onready var hover_hex : Sprite = $HoverHex

onready var left_dragging = false


func _process(delta: float) -> void:
	
	var hex_coords = tilemap.get_hex_coordinates(get_global_mouse_position())
	#tilemap_overlay.clear()
	if hex_coords or hex_coords == Vector2(0,0):
		#tilemap_overlay.set_cellv(hex_coords, 2)
		hover_hex.visible = true
		hover_hex.position = tilemap.get_centre_coordinates_from_hex(hex_coords)
	else:
		hover_hex.visible = false
	
	if left_dragging:
		#var new_path : = nav_2d.get_simple_path(character.global_position, get_global_mouse_position(), false)
		#var new_path : = nav_2d.get_simple_path(character.global_position, get_global_mouse_position())
		#line_2d.points = new_path
		
		#var distance = 0.0
		#for i in range(new_path.size()):
		#	distance += new_path[i].length()
		
		#distance_label.text = str(int(distance / 500)) + ' days'
		#distance_label.rect_position = get_global_mouse_position() + Vector2( 20.0, 0.0 )
		#distance_label.show()
		
		hover_hex.visible = false
		tilemap_overlay.clear()
		var path = tilemap.find_path(character.position, get_global_mouse_position())
		#path.remove(0)
		for p in path:
			tilemap_overlay.set_cellv(p, 2)
		distance_label.text = str(len(path)) + ' days'
		distance_label.rect_position = get_global_mouse_position() + Vector2( 20.0, 0.0 )
		distance_label.show()
		


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT:
		return
	
	left_dragging = event.pressed

	if not event.pressed:
		
		tilemap_overlay.clear()
		
		var path = tilemap.find_path(character.position, get_global_mouse_position())
		var position_path = []
		for p in path:
			position_path.append(tilemap.get_centre_coordinates_from_hex(p))
		position_path.remove(0)
		character.path = PoolVector2Array(position_path)
		character.goal = event.global_position
		
		#var new_path : = nav_2d.get_simple_path(character.global_position, event.global_position, false)
		#character.path = new_path
		#character.goal = event.global_position
		#line_2d.clear_points()
		distance_label.hide()


func _on_Button_button_up():
	character.set_process(true)
	yield(get_tree().create_timer(2.0), "timeout")
	#character.set_process(false)
	
	#var new_path : = nav_2d.get_simple_path(character.global_position, character.goal, false)
	#character.path = new_path
	#line_2d.points = new_path
