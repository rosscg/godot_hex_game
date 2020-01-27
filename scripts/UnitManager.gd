extends Node

onready var map : Node2D = get_owner().get_node("Map")
const unit_scene = preload("res://scenes/Army.tscn")
const messenger_scene = preload("res://scenes/Messenger.tscn")
const building_scene = preload("res://scenes/Building.tscn")
# Detachment Testing
#const detachment_scene = preload("res://scenes/Detachment.tscn")

var unit_list = []
var messenger_list = []
var building_list = []
var selected_unit = null
var overlay_on : bool = false
var unit_data = {}

var team_colour_dict = {1: Color( 0.55, 0, 0, 1 ), 2: Color( 0, 0, 0.55, 1 ) } # Red, Blue


func _ready() -> void:
	unit_data = load_unit_data()['movement_costs']
	
	# Temporary place city sprite:
	var building_instance = building_scene.instance()
	if map.tilemap.cell_half_offset == 2: # Squares
		building_instance.position = Vector2(340,640)
	else: # Hex
		building_instance.position = map.tilemap.get_coordinates_from_cell(Vector2(18, 46), true)
	building_instance.get_node('TeamFlag').color = team_colour_dict[1]
	add_child(building_instance)
	building_list.append({"team": 1, "instance": building_instance})
	
	building_instance = building_scene.instance()
	if map.tilemap.cell_half_offset == 2: # Squares
		building_instance.position = Vector2(1180,140)
	else: # Hex
		building_instance.position = map.tilemap.get_coordinates_from_cell(Vector2(68, 11), true)
	building_instance.get_node('TeamFlag').color = team_colour_dict[2]
	add_child(building_instance)
	building_list.append({"team": 2, "instance": building_instance})


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
	var unit_type = unit_data.keys()[randi() % (unit_data.size() - 1)]
	var unit_terrain_dict = unit_data[unit_type]
	var strength = randi()%5 + 6
	var team = get_parent().turn_manager.active_player
	unit_instance.init(unit_type, unit_terrain_dict, strength, \
		map.tilemap.get_coordinates_from_cell(cell_coordinates, true), team, team_colour_dict[team])
	#unit_instance.set_name("unit")
	add_child(unit_instance)
	unit_list.append(unit_instance)
	
	
	# Detachment Testing
#	var detachment_instance = detachment_scene.instance()
#	detachment_instance.init(unit_instance, 1, unit_type, unit_terrain_dict, strength, \
#		unit_instance.position + Vector2(20,0), team, team_colour_dict[team])
#	add_child(detachment_instance)
#	unit_instance.detachment_list.append(detachment_instance)
#	var detachment_instance2 = detachment_scene.instance()
#	detachment_instance2.init(unit_instance, 2, unit_type, unit_terrain_dict, strength, \
#		unit_instance.position + Vector2(-20,0), team, team_colour_dict[team])
#	add_child(detachment_instance2)
#	unit_instance.detachment_list.append(detachment_instance2)
	
	return unit_instance


func create_messenger():
	var messenger_instance = messenger_scene.instance()
	# Create random unit type:
	var unit_terrain_dict = unit_data['messenger']
	var team = get_parent().turn_manager.active_player
	# Get coordinates of first friendly base in list:
	var base_coordinates
	for b in building_list:
		if b["team"] == team:
			base_coordinates = b["instance"].position
			# If square tilemap, base spans 2x2 grid so choose a cell middle point:
			if map.tilemap.cell_half_offset == 2:
				base_coordinates += Vector2(map.tilemap.grid_cell_width/2, map.tilemap.grid_cell_width/2)
			break
	messenger_instance.init('messenger', unit_terrain_dict, 0, base_coordinates, team)
	add_child(messenger_instance)
	messenger_list.append(messenger_instance)
	return messenger_instance


func activate_units(active):
	for unit in unit_list:
		unit.set_process(active)
		# Detachment Testing
		#for d in unit.detachment_list:
		#	d.set_process(active)
	for messenger in messenger_list:
		messenger.set_process(active)


func get_unit_in_cell(cell_coordinates, ignored_unit=null):
	for unit in unit_list:
		if unit != ignored_unit:
			#if map.tilemap.get_cell_from_coordinates(unit.position) == cell_coordinates:
			if cell_coordinates in unit.occupied_cells:
				return unit
	return false


func detect_combat():
	# TODO: Currently won't initiate when two units 'swap' cells. -- should be working now
	for unit in unit_list:
		for occupied_cell in unit.occupied_cells:
			for neighbour in map.tilemap.get_neighbours(occupied_cell):# + occupied_cell:
				var target_unit = get_unit_in_cell(neighbour, unit)
				if target_unit and target_unit.team != unit.team:
					unit.toggle_combat(target_unit)
					#target_unit.in_combat = unit


func resolve_combat():
	for unit in unit_list:
		var target_unit = unit.in_combat
		if target_unit:
			if not is_instance_valid(target_unit) or target_unit.take_damage(1): # TODO: change to unit's attack value
				unit_list.erase(target_unit)
				for unit_check in unit_list:
					if unit_check.in_combat == target_unit:
						unit_check.toggle_combat(null)


func toggle_overlay():
	# Show/hide the path and goals of all units
	overlay_on = !overlay_on
	for unit in unit_list + messenger_list:
		if unit == selected_unit:
			continue
#		if unit.team != get_owner().turn_manager.active_player:
#			continue
		#var toggle = unit.team == get_parent().turn_manager.active_player and \
		#				overlay_on and unit.goal != Vector2(0,0)
		var toggle = overlay_on and unit.goal != Vector2(0,0)
		#unit.toggle_overlay(toggle, unit.in_combat)
		unit.toggle_overlay(toggle)