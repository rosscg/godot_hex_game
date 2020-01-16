## Todo:

### Next:
* Fix: units move to next cell for combat even if it's away from target unit.
* get_neighbours with radius
* check for missing cell terrain ids
* Units can still cross over / fight in same cell

### Mid:
* Line to targetted combat unit
* Teams
* Unit facing direction
* Disable interface during turn processing

### Low Priority:
* States - march, route, retreat, combat, ranged combat, fortify, stationary
* Units currently store their own astar node - probably only need to store one node per unit type

### Lowest Priority:
* Declaring variables -- when to use onready, what := is for, when to declare type
