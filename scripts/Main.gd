extends Node2D

onready var map : Node2D = $Map
onready var unit_manager : Node2D = $UnitManager
onready var distance_label : Label = $Distance_Label

#onready var left_dragging = false


func _process(delta: float) -> void:
	# Show planned path if unit is selected
	if unit_manager.selected_unit:
		var path = map.display_path(unit_manager.selected_unit)
		distance_label.text = str(len(path)) + ' days'
		distance_label.rect_position = get_global_mouse_position() + Vector2( 20.0, 0.0 )
		distance_label.show()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		 # Create new unit on A key press:
		if event.get_scancode() == KEY_A and event.is_pressed() and not event.is_echo():
			var hex_coordinates = map.tilemap.get_hex_coordinates(get_global_mouse_position())
			unit_manager.create_unit(hex_coordinates)
			return
		
	if not event is InputEventMouseButton:
		return
	
	# Deselect on right click:
	if event.button_index != BUTTON_LEFT:
		unit_manager.selected_unit = null
		map.selected_hex_sprite.visible = false
		distance_label.hide()
		map.line_2d.clear_points()
		if unit_manager.selected_unit:
			unit_manager.selected_unit.planned_path.visible = false
		#map.tilemap_overlay.clear()
		return
	
	#left_dragging = event.pressed

	if not event.pressed: # left click released
		if not unit_manager.selected_unit:
			var selected_hex = map.tilemap.get_hex_coordinates(get_global_mouse_position())
			for x in unit_manager.unit_list:
				if selected_hex in x.current_hexes:
					unit_manager.selected_unit = x
					x.planned_path.visible = true
					map.selected_hex_sprite.visible = true
					map.selected_hex_sprite.position = map.tilemap.get_centre_coordinates_from_hex(selected_hex)
					return
		else:
			#map.tilemap_overlay.clear()
			var path = map.tilemap.find_path(unit_manager.selected_unit.position, get_global_mouse_position(), unit_manager.selected_unit.terrain_dict)
			var position_path = []
			for p in path:
				position_path.append(map.tilemap.get_centre_coordinates_from_hex(p))
			position_path.remove(0)
			# TODO: move into unit class:
			unit_manager.selected_unit.path = PoolVector2Array(position_path)
			unit_manager.selected_unit.planned_path.visible = false
			unit_manager.selected_unit.update()
			unit_manager.selected_unit.goal = event.global_position
			unit_manager.selected_unit = null
			map.selected_hex_sprite.visible = false
			map.line_2d.clear_points()

			distance_label.hide()


func _on_Button_button_up():
	unit_manager.activate_units(true)
	#yield(get_tree().create_timer(3.0), "timeout")
	#unit_manager.activate_units(false)

