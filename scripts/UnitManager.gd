extends Node

onready var map : Node2D = get_owner().get_node("Map")
const unit_scene = preload("res://scenes/Unit.tscn")

var unit_list = []
var selected_unit = null
var overlay_on : bool = false
var unit_data = {}


func _ready() -> void:
	unit_data = load_unit_data()


#func _process(_delta: float) -> void:
#	detect_combat()


func load_unit_data():
	var file = File.new()
	file.open("res://assets/units/unit_data.json", file.READ)
	var text = file.get_as_text()
	var result_json = JSON.parse(text)
	if result_json.error == OK:
		var data = result_json.result
		return data
	else:
		print("Error: ", result_json.error)
		print("Error Line: ", result_json.error_line)
		print("Error String: ", result_json.error_string)


func create_unit(cell_coordinates):
	if get_unit_in_cell(cell_coordinates):
		print('cell already occupied')
		return
	if not cell_coordinates: 
		# Clicked outside of map
		return
	var unit_instance = unit_scene.instance()
	# Create random unit type:
	var unit_type = unit_data.keys()[randi() % unit_data.size()]
	var unit_terrain_dict = unit_data[unit_type]
	var strength = randi()%5 + 6
	unit_instance.init(unit_type, unit_terrain_dict, strength, map.tilemap.get_coordinates_from_cell(cell_coordinates, true))
	#unit_instance.set_name("unit")
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
	# TODO: Currently won't initiate when two units 'swap' cells. -- should be working now
	for unit in unit_list:
		for occupied_cell in unit.occupied_cells:
			for neighbour in map.tilemap.get_neighbours(occupied_cell):# + occupied_cell:
				var target_unit = get_unit_in_cell(neighbour, unit)
				if target_unit:
					unit.toggle_combat(target_unit)
					#target_unit.in_combat = unit
	return


func resolve_combat():
	for unit in unit_list:
		var target_unit = unit.in_combat
		if target_unit:
			if not is_instance_valid(target_unit) or target_unit.take_damage(1): # TODO: change to unit's attack value
				unit_list.erase(target_unit)
				unit.toggle_combat(null)
				#target_unit = null


func toggle_overlay():
	# Show/hide the path and goals of all units
	overlay_on = !overlay_on
	for unit in unit_list:
		if unit == selected_unit:
			continue
		unit.goal_sprite.visible = overlay_on and unit.goal != Vector2(0,0)
		unit.planned_path_line.visible = overlay_on