## Todo:

### Next:
* terrain cell index error - selected unit moving, mouse over deep water (impassable)
* Fix: units move to next cell for combat even if it's away from target unit.
* Units can still cross over / fight in same cell
* Select unit by raycast, not cell_occupied

### Mid:
* Teams
* Unit facing direction
* Disable interface during turn processing
* Stop units backtracking to centre of grid when in combat

### Low Priority:
* States - march, route, retreat, combat, ranged combat, fortify, stationary
* Units currently store their own astar node - probably only need to store one node per unit type
* Debug tile terrain index error eg: (430, 110)

### Lowest Priority:
* Declaring variables -- when to use onready, what := is for, when to declare type
