extends Node2D

onready var map : Node2D = $Map
onready var unit_manager : Node2D = $UnitManager
onready var distance_label : Label = get_node("GUI/Distance_Label")
onready var unit_info_gui : Control = get_node("GUI/UnitInfoGUI")
#onready var left_dragging = false


func _process(delta: float) -> void:
	# Show planned path if unit is selected
	var path = map.display_path(unit_manager.selected_unit)
	if unit_manager.selected_unit and map.tilemap.get_cell_coordinates(get_global_mouse_position()):
		distance_label.text = map.tilemap.get_tile_terrain(map.tilemap.get_cell_coordinates(get_global_mouse_position())).capitalize()
		distance_label.rect_position = get_global_mouse_position() + Vector2( 20.0, 0.0 )
		distance_label.show()
		unit_info_gui.visible = true
		unit_info_gui.get_node('Label').text = \
			unit_manager.selected_unit.unit_type.capitalize() + \
			'\n\nStrength: ' + str(unit_manager.selected_unit.strength) + \
			'\nOn: ' + map.tilemap.get_tile_terrain(unit_manager.selected_unit.occupied_cells[0]).capitalize() + \
			'\n\nTo: ' + map.tilemap.get_tile_terrain(map.tilemap.get_cell_coordinates(get_global_mouse_position())).capitalize() + \
			'\nDistance: ' + str(unit_manager.selected_unit.calc_path_cost(path))
	else:
		unit_info_gui.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		 # Create new unit on A key press:
		if event.get_scancode() == KEY_A and event.is_pressed() and not event.is_echo():
			var cell_coordinates = map.tilemap.get_cell_coordinates(get_global_mouse_position())
			if cell_coordinates:
				var unit = unit_manager.create_unit(cell_coordinates)
				if unit:
					unit.select_unit()
			return

	# Ignore all other keypresses
	if not event is InputEventMouseButton:
		return

	# Deselect on right (or middle) click:
	if event.button_index != BUTTON_LEFT:
		if unit_manager.selected_unit:
			unit_manager.selected_unit.select_unit(false)
			unit_manager.selected_unit = null
		#map.selected_cell_sprite.visible = false
		distance_label.hide()
		map.line_2d.clear_points()
		#map.tilemap_overlay.clear()
		return

	#left_dragging = event.pressed

 	# Left click released
	if not event.pressed:
		if unit_manager.selected_unit:
			#map.tilemap_overlay.clear()
			var path = map.tilemap.find_path(unit_manager.selected_unit.position, get_global_mouse_position(), 
												unit_manager.selected_unit.astar_node)
			var position_path = []
			for p in path:
				position_path.append(map.tilemap.get_coordinates_from_cell(p, true))
			position_path.remove(0)
			unit_manager.selected_unit.set_goal(event.global_position, PoolVector2Array(position_path))
			unit_manager.selected_unit.update()
			unit_manager.selected_unit.select_unit(false)
			unit_manager.selected_unit = null
			#map.selected_cell_sprite.visible = false
			map.line_2d.clear_points()
			distance_label.hide()
		else:
			var selected_cell = map.tilemap.get_cell_coordinates(get_global_mouse_position())
			for x in unit_manager.unit_list:
				if selected_cell in x.occupied_cells:
					x.select_unit()
					#map.selected_cell_sprite.visible = true
					#map.selected_cell_sprite.position = map.tilemap.get_coordinates_from_cell(selected_cell, centred=true)
					return


func _on_StartButton_button_up():
	unit_manager.activate_units(true)
	#yield(get_tree().create_timer(3.0), "timeout")
	#unit_manager.activate_units(false)
	return


func _on_OverlayButton_button_up():
	unit_manager.toggle_overlay()
