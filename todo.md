## Todo:

### Now:

### Next:

### Mid:
* Try changing combat detection radius to +1
* Create team manager, store available messenger count.
* Unit facing direction
* Generals/Unit AI

### Low Priority:
* Pass and display length of path for current turn in unit's overlay.
* Fix: units move to next cell for combat even if it's away from target unit. (Only relevant if units move after detecting combat, currently disabled.)
* States - march, route, retreat, combat, ranged combat, fortify, stationary
* Units currently store their own astar node - probably only need to store one node per unit type
* Disable interface during turn processing
* Decide on whether to keep occupied_cells as an array
* Change Army to animated sprite and set sprite with code.
* Blue unit path display line misses origin point for hex map when hovering NW of unit.
* Don't send messenger if path is into impassable terrain
* Consider whether astars need to be stored in units at all -- perhaps just hold them in unit_manager
* Change messenger goal sprite colour.

### Long-Term Features:
Weather - overlay
Night and day (depending on scale)
Trade/Income
Supply Wagons
Use messengers as supply / disrupting other messengers instead of sending messages


## Notes:
* Units recalculate paths but won't move at all if the route is impossible, whereas they should probably still move towards the goal.
* Units competing over a goal cell overlap.
* Units crossing diagonally will overlap. Consider an exclusion radius around units?
