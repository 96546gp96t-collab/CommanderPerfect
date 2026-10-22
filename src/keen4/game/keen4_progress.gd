class_name Keen4Progress
extends RefCounted
## How far a game of Keen 4 has come, beyond what Keen carries
## ([Keen4Inventory]): the council members rescued (the eighth ends the
## game, D8), whether Keen has the wetsuit (he can swim on the world map),
## which levels are done (the world map's flags and fences), where Keen
## stood on the map when he entered the last level, which level was just
## finished (its flag is thrown) and whether the Foot carried him off (he
## flies on the map). Omni `ck_def.h` ck_gameState: membersRescued, wetsuit,
## levelsDone, mapPosX/Y; ck_lastLevelFinished; levelState LS_Foot.

## The rescues that end the game (Omni CK4_NumCouncilsToRescue).
const COUNCIL_COUNT := 8
## The names in [method to_dictionary].
const RESCUED_KEY := "rescued"
const WETSUIT_KEY := "wetsuit"
const DONE_KEY := "levels_done"
const POSITION_KEY := "map_position"

var rescued := 0
var wetsuit := false
## Keen's place on the world map (units); zero: where the map puts him.
var map_position := Vector2i.ZERO
## The level finished last, -1 when the last level was not finished.
var last_finished := -1
## The last level ended on the Foot.
var foot_flight := false
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


## What a saved game keeps (D10 saves it): the rescues, the wetsuit, the
## levels done and the place on the map.
func to_dictionary() -> Dictionary:
	return {
		RESCUED_KEY: rescued,
		WETSUIT_KEY: wetsuit,
		DONE_KEY: Array(done_levels()),
		POSITION_KEY: [map_position.x, map_position.y],
	}


## The progress kept in [param saved] ([method to_dictionary]); missing
## parts are as in a new game.
static func from_dictionary(saved: Dictionary) -> Keen4Progress:
	var progress := Keen4Progress.new()
	progress.rescued = int(saved.get(RESCUED_KEY, 0))
	progress.wetsuit = bool(saved.get(WETSUIT_KEY, false))
	for level: Variant in saved.get(DONE_KEY, []):
		progress.mark_done(int(level))
	var place: Array = saved.get(POSITION_KEY, [0, 0])
	if place.size() == 2:
		progress.map_position = Vector2i(int(place[0]), int(place[1]))
	return progress
