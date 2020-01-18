extends Node2D

onready var tilemap : TileMap = get_parent().get_parent().get_node('TileMap_SquareLarge')
onready var map : Node2D = get_parent().get_parent()
var fog_cells = []


func _ready() -> void:
	fog_cells = tilemap.get_used_cells()


func _process(delta):
#	fog_cells = tilemap.get_used_cells()
#	for unit in get_parent().get_parent().get_parent().unit_manager.unit_list:
#		for cell in tilemap.get_neighbours(unit.occupied_cells[0], 4, true):
#			fog_cells.erase(cell)

	#get_parent().get_node('Sprite').position = Vector2(200,200)

	update()


func _draw():
	for unit in get_parent().get_parent().get_parent().unit_manager.unit_list:
		var coords = unit.position
		coords.y = (tilemap.grid_dimensions.end.y * tilemap.grid_cell_height)-coords.y
		for x in range(1, 100):
			draw_circle(coords, x, Color( 1, 1, 1, min(3.0/x, 1.0)))
#	for cell in fog_cells:
#		var coords = tilemap.get_coordinates_from_cell(cell, false)
#		# Flip Y axis:
#		coords.y = (tilemap.grid_dimensions.end.y * tilemap.grid_cell_height)-coords.y
#		#draw_circle(coords, 10, Color( 1, 1, 1, 1 ))
#		draw_rect(Rect2(coords.x, coords.y - tilemap.grid_cell_height, tilemap.grid_cell_width, tilemap.grid_cell_height), Color( 1, 1, 1, 1 ))
