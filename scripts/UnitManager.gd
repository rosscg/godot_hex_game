extends Node

onready var map : Node2D = get_owner().get_node("Map")
onready var unit_info_gui : Node2D = get_owner().get_node("GUI/UnitInfoUI")

onready var unit_list = []
onready var selected_unit = null
onready var overlay_on : bool = false


func _process(delta: float) -> void:
	
	detect_combat()
	
	if selected_unit:
		unit_info_gui.get_node('Label').visible = true
		unit_info_gui.get_node('Polygon2D').visible = true
		unit_info_gui.get_node('Label').text = 'Infantry\n\nStrength: ' + str(selected_unit.strength) + \
												'\n' + map.tilemap.get_tile_terrain(selected_unit.occupied_cells[0]).capitalize()
	else:
		unit_info_gui.get_node('Label').visible = false
		unit_info_gui.get_node('Polygon2D').visible = false


func create_unit(cell_coordinates):
	if get_unit_in_cell(cell_coordinates):
		print('cell already occupied')
		return
	var unit_scene = load("res://scenes/Unit.tscn")
	var unit_instance = unit_scene.instance()
	#unit_instance.set_name("unit")
	if not cell_coordinates and cell_coordinates != Vector2(0,0): 
		# Clicked outside of map
		return
	unit_instance.position = map.tilemap.get_coordinates_from_cell(cell_coordinates, true)
	add_child(unit_instance)
	unit_list.append(unit_instance)
	return unit_instance


func activate_units(active):
	for unit in unit_list:
		unit.set_process(active)


func get_unit_in_cell(cell_coordinates, ignored_unit=null):
	for unit in unit_list:
		if unit != ignored_unit:
			#if map.tilemap.get_cell_coordinates(unit.position) == cell_coordinates:
			if cell_coordinates in unit.occupied_cells:
				return unit
	return false


func detect_combat():
	# TODO: Currently won't initiate when two units 'swap' cells.
	for unit in unit_list:
		for occupied_cell in unit.occupied_cells:
			#var cell = map.tilemap.get_cell_coordinates(unit.position)
			var unit2 = get_unit_in_cell(occupied_cell, unit)
			if unit2:
				resolve_combat(unit, unit2)
	return


func resolve_combat(unit1, unit2):
	# Arbitrary combat implementation
	var u1_damage = unit1.strength
	var u2_damage = unit2.strength
	if unit1.take_damage(u2_damage):
		unit_list.erase(unit1)
	if unit2.take_damage(u1_damage):
		unit_list.erase(unit2)


func toggle_overlay():
	# Show/hide the path and goals of all units
	overlay_on = !overlay_on
	for unit in unit_list:
		if unit == selected_unit:
			continue
		unit.goal_sprite.visible = overlay_on and unit.goal != Vector2(0,0)
		unit.planned_path.visible = overlay_on