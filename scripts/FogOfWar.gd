extends Node2D

onready var active_player = get_node("/root/Main").get_node('TurnManager').active_player
var sprite_dict = {}	# Pair unit name to light sprite name
var live_units			# Whether unit name is still alive

func _process(delta):
	live_units = {}
	for key in sprite_dict.keys():
		live_units[key] = false
	
	for unit in get_node("/root/Main").unit_manager.unit_list:
		
		live_units[unit.get_name()] = true # Mark unit as alive
		
		if unit.team != active_player:
			continue
		var light_sprite
		if unit.get_name() in sprite_dict.keys():
			light_sprite = get_parent().get_node(sprite_dict[unit.get_name()])
		else:
			light_sprite = get_parent().get_node('Texture_Sprite').duplicate()
			light_sprite.visible = true
			get_parent().add_child(light_sprite)
			sprite_dict[unit.get_name()] = light_sprite.get_name()
		light_sprite.position = unit.position

	for unit in live_units:
		# Delete sprites for units which have died:
		if live_units[unit] == false:
			get_parent().get_node(sprite_dict[unit]).queue_free()
			sprite_dict.erase(unit)
			live_units.erase(unit)