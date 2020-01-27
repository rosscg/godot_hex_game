## Todo:

### Now:
* BUG: Path line does not hide during combat, or does not point to attacked unit.

### Next:
* One astar node per unit type
* Units can still cross over / fight in same cell
* Calc path possible in one turn

### Mid:
* Try changing combat detection radius to +1
* Create team manager, store available messenger count.
* Fix messenger redrawing target unit orders flickering & change messenger goal sprite colour.
* Fix: units move to next cell for combat even if it's away from target unit. (Only relevant if units move after detecting combat, currently disabled.)
* Stop units backtracking to centre of grid when in combat (Done?)
* Unit facing direction
* Generals/Unit AI

### Low Priority:
* States - march, route, retreat, combat, ranged combat, fortify, stationary
* Units currently store their own astar node - probably only need to store one node per unit type
* Disable interface during turn processing
* Decide on whether to keep occupied_cells as an array
* Change Army to animated sprite and set sprite with code.

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
