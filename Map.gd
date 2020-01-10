extends Node2D

onready var tilemap : TileMap = get_node("TileMap")
onready var tilemap_overlay : TileMap = get_node("TileMapOverlay")
onready var distance_label : Label = $Distance_Label
onready var hover_hex_sprite : Sprite = $HoverHex
onready var selected_hex_sprite : Sprite = $SelectedHex
onready var unit_list = []
onready var selected_unit = null

#onready var left_dragging = false


func _process(delta: float) -> void:
	# Show hex hovered over
	var hex_coords = tilemap.get_hex_coordinates(get_global_mouse_position())
	if hex_coords or hex_coords == Vector2(0,0):
		hover_hex_sprite.visible = true
		hover_hex_sprite.position = tilemap.get_centre_coordinates_from_hex(hex_coords)
	else:
		hover_hex_sprite.visible = false

	# Show planned path if unit is selected
	if selected_unit:
		hover_hex_sprite.visible = false
		tilemap_overlay.clear()
		var path = tilemap.find_path(selected_unit.position, get_global_mouse_position())
		path.remove(0)
		for p in path:
			tilemap_overlay.set_cellv(p, 2)
		distance_label.text = str(len(path)) + ' days'
		distance_label.rect_position = get_global_mouse_position() + Vector2( 20.0, 0.0 )
		distance_label.show()
		


func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		 # Create new unit on A key press:
		if event.get_scancode() == KEY_A and event.is_pressed() and not event.is_echo():
			var scene = load("res://Unit.tscn")
			var scene_instance = scene.instance()
			#scene_instance.set_name("scene")
			var hex_coordinates = tilemap.get_hex_coordinates(get_global_mouse_position())
			if not hex_coordinates: 
				# Clicked outside of map
				return
			scene_instance.position = tilemap.get_centre_coordinates_from_hex(hex_coordinates)
			add_child(scene_instance)
			unit_list.append(scene_instance)
			return
		
	if not event is InputEventMouseButton:
		return
	
	# Deselect on right click:
	if event.button_index != BUTTON_LEFT:
		selected_unit = null
		selected_hex_sprite.visible = false
		tilemap_overlay.clear()
		return
	
	#left_dragging = event.pressed

	if not event.pressed: # left click released
		if not selected_unit:
			var selected_hex = tilemap.get_hex_coordinates(get_global_mouse_position())
			for x in unit_list:
				if tilemap.get_hex_coordinates(x.position) == selected_hex:
					selected_unit = x
					selected_hex_sprite.visible = true
					selected_hex_sprite.position = tilemap.get_centre_coordinates_from_hex(selected_hex)
					return
		else:
			tilemap_overlay.clear()
			var path = tilemap.find_path(selected_unit.position, get_global_mouse_position())
			var position_path = []
			for p in path:
				position_path.append(tilemap.get_centre_coordinates_from_hex(p))
			position_path.remove(0)
			selected_unit.path = PoolVector2Array(position_path)
			selected_unit.goal = event.global_position
			selected_unit = null
			selected_hex_sprite.visible = false
		
			distance_label.hide()


func _on_Button_button_up():
	for unit in unit_list:
		unit.set_process(true)
	yield(get_tree().create_timer(3.0), "timeout")
	for unit in unit_list:
		unit.set_process(false)

