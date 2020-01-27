extends "res://scripts/Unit.gd"

var parent_army
var rank

func init(parent_army, rank, unit_type, data_dict, strength, start_coordinates, team=1, team_colour=Color( 0.55, 0, 0, 1 )):
	self.rank = rank
	self.team = team
	self.terrain_dict = data_dict
	self.parent_army = parent_army
	self.position = start_coordinates
	get_node("TeamPoly").color = team_colour


func _process(delta: float) -> void:
	if len(planned_path) > 0:
		._process(delta)
		._move_along_path(self.parent_army.move_distance)
		#._move_along_path(move_distance)


func update_destination():
	if parent_army.formation == 'line':
		var offset = line_formation_dict[self.parent_army.orientation]
		if rank == 2:
			offset *= Vector2(-1,-1) #TODO Check for other orientations.
		planned_path.append(self.parent_army.position + offset)
	if parent_army.formation == 'column':
		if rank == 1 and self.parent_army.last_cell:
			planned_path.append(tilemap.get_coordinates_from_cell(self.parent_army.last_cell, true))
		elif rank == 2 and self.parent_army.second_last_cell:
			planned_path.append(tilemap.get_coordinates_from_cell(self.parent_army.second_last_cell, true))

		
# TODO: update cells occupied, 
# TODO: implement combat initiation
# TODO: Handle changes in formation