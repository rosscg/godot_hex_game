extends Node

onready var unit_manager : Node2D = get_owner().get_node("UnitManager")
var time_start = 0
var turn_length_ms = 12000
var sub_turn_ms = 2000
var subturn_count
var active_player = 1


func start_turn() -> void:
	print('starting turn')
	unit_manager.activate_units(true)
	self.time_start = OS.get_ticks_msec()
	subturn_count = -1
	set_process(true)
#	yield(get_tree().create_timer(5.0), "timeout")
#	unit_manager.activate_units(false)


func end_turn():
	print('ending turn')
	unit_manager.activate_units(false)
	set_process(false)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var time_in_turn = OS.get_ticks_msec() - time_start
	if time_in_turn > turn_length_ms:
		end_turn()
		return
	
	unit_manager.detect_combat()
	
	# Process periodic subturns within main turn timer:
	if int(time_in_turn/sub_turn_ms) > subturn_count:
		subturn_count += 1
		print('subturn: ', subturn_count)
		
		# Resolve round of combat
		unit_manager.resolve_combat()
		
		# Units update path to account for new obstructions (e.g. other units)
		for unit in unit_manager.unit_list:
			unit.process_logic()
		# Messengers update goal in case target_unit has moved
		for messenger in unit_manager.messenger_list:
			if messenger.target_unit:
				messenger.set_goal(messenger.target_unit.position)