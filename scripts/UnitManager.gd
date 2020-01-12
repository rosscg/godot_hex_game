extends Node

onready var map : Node2D = get_owner().get_node("Map")

onready var unit_list = []
onready var selected_unit = null
onready var overlay_on : bool = false


func _process(delta: float) -> void:
	detect_combat()


func create_unit(hex_coordinates):
	if get_unit_in_hex(hex_coordinates):
		print('cell already occupied')
		return
	var unit_scene = load("res://scenes/Unit.tscn")
	var unit_instance = unit_scene.instance()
	#unit_instance.set_name("unit")
	if not hex_coordinates and hex_coordinates != Vector2(0,0): 
		# Clicked outside of map
		return
	unit_instance.position = map.tilemap.get_centre_coordinates_from_hex(hex_coordinates)
	add_child(unit_instance)
	unit_list.append(unit_instance)
	return unit_instance


func activate_units(active):
	for unit in unit_list:
		unit.set_process(active)


func get_unit_in_hex(hex_coordinates, ignored_unit=null):
	for unit in unit_list:
		if unit != ignored_unit:
			#if map.tilemap.get_hex_coordinates(unit.position) == hex_coordinates:
			if hex_coordinates in unit.current_hexes:
				return unit
	return false


func detect_combat():
	# TODO: Currently won't initiate when two units 'swap' hexes.
	for unit in unit_list:
		for occupied_hex in unit.current_hexes:
			#var hex = map.tilemap.get_hex_coordinates(unit.position)
			var unit2 = get_unit_in_hex(occupied_hex, unit)
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