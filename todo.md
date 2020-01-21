## Todo:

### Now:

### Next:
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

### Long-Term Features:
Weather - overlay
Night and day (depending on scale)


## Notes:
* Units recalculate paths but won't move at all if the route is impossible, whereas they should probably still move towards the goal.
* Units competing over a goal cell overlap.
* Units crossing diagonally will overlap. Consider an exclusion radius around units?
