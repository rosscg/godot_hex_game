extends Node2D

var sprite_dict = {}


func _process(delta):
	for unit in get_parent().get_parent().get_parent().unit_manager.unit_list:
		if unit.team == 2: #TODO: Active player
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