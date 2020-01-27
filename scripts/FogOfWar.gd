extends Node2D

#var active_player = get_node("/root/Main").turn_manager.active_player
var sprite_dict = {}	# Pair unit name to light sprite name
var live_units			# Whether unit name is still alive


func _ready() -> void:
	set_process(false)
	

func _process(delta):
	# Create list of units with light sprites:
	live_units = {}
	for key in sprite_dict.keys():
		live_units[key] = false
	for unit in get_node("/root/Main").unit_manager.unit_list + get_node("/root/Main").unit_manager.messenger_list:
		# Mark unit as alive
		live_units[unit.get_name()] = true
		# Create or move light sprite:
		var light_sprite
		if unit.get_name() in sprite_dict.keys():
			light_sprite = get_parent().get_node(sprite_dict[unit.get_name()])
		else:
			light_sprite = get_parent().get_node('Texture_Sprite').duplicate()
			get_parent().add_child(light_sprite)
			sprite_dict[unit.get_name()] = light_sprite.get_name()
		# Move and visible light nodes for active player
		if unit.team == get_node("/root/Main").turn_manager.active_player:
			light_sprite.position = unit.position
			light_sprite.visible = true
		else:
			light_sprite.visible = false

	# Delete sprites for units which have died:
	for unit in live_units:
		if live_units[unit] == false:
			get_parent().get_node(sprite_dict[unit]).queue_free()
			sprite_dict.erase(unit)
			live_units.erase(unit)