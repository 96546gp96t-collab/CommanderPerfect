class_name Keen4Progress
extends RefCounted
## How far a game of Keen 4 has come, beyond what Keen carries
## ([Keen4Inventory]): the council members rescued (the eighth ends the
## game, D8), whether Keen has the wetsuit (he can swim on the world map,
## D7) and which levels are done (the world map's flags, D7). Omni
## `ck_def.h` ck_gameState: membersRescued, wetsuit, levelsDone.

## The rescues that end the game (Omni CK4_NumCouncilsToRescue).
const COUNCIL_COUNT := 8

var rescued := 0
var wetsuit := false
var _done: Dictionary[int, bool] = {}


## One more council member rescued; returns how many were rescued before
## him (which of Keen's answers he hears).
func rescue() -> int:
	rescued += 1
	return rescued - 1


## Whether all of them are rescued.
func all_rescued() -> bool:
	return rescued >= COUNCIL_COUNT


func mark_done(level: int) -> void:
	_done[level] = true


func is_done(level: int) -> bool:
	return _done.has(level)


## The levels done, in order.
func done_levels() -> PackedInt32Array:
	var levels := PackedInt32Array(_done.keys())
	levels.sort()
	return levels
