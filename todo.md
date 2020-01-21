## Todo:

### Now:

### Next:
* Add teammate obstructed tiles to tilemap exclusions. Or just: if can't move, recalculate path exclnext cell
* Units can still cross over / fight in same cell
* Calc path possible in one turn

### Mid:
* Fix: units move to next cell for combat even if it's away from target unit. (Only relevant if units move after detecting combat, currently disabled.)
* Stop units backtracking to centre of grid when in combat
* Unit facing direction
* Generals/Unit AI
* Messengers

### Low Priority:
* States - march, route, retreat, combat, ranged combat, fortify, stationary
* Units currently store their own astar node - probably only need to store one node per unit type
* Disable interface during turn processing

### Lowest Priority:
Weather - overlay
Night and day (depending on scale)
