class_name Keen4Progress
extends GalaxyProgress
## How far a game of Keen 4 has come, beyond what Keen carries
## ([Keen4Inventory]): the council members rescued (the eighth ends the
## game, D8), whether Keen has the wetsuit (he can swim on the world map),
## which levels are done (the world map's flags and fences), where Keen
## stood on the map when he entered the last level, which level was just
## finished (its flag is thrown) and whether the Foot carried him off (he
## flies on the map). Omni `ck_def.h` ck_gameState: membersRescued, wetsuit,
## levelsDone, mapPosX/Y; ck_lastLevelFinished; levelState LS_Foot.
## On the shared [GalaxyProgress] since milestone E13, with Keen 4's own
## format in a saved game (the levels done as a list).

## The rescues that end the game (Omni CK4_NumCouncilsToRescue).
const COUNCIL_COUNT := 8
## The names in [method to_dictionary].
const RESCUED_KEY := "rescued"
const WETSUIT_KEY := "wetsuit"

var rescued := 0
var wetsuit := false
## The last level ended on the Foot.
var foot_flight := false


## One more council member rescued; returns how many were rescued before
## him (which of Keen's answers he hears).
func rescue() -> int:
	rescued += 1
	return rescued - 1


## Whether all of them are rescued.
func all_rescued() -> bool:
	return rescued >= COUNCIL_COUNT


## The world map was set up: the flag thrown and the Foot's flight are
## used up.
func map_shown() -> void:
	super()
	foot_flight = false


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
	progress.load_dictionary(saved)
	return progress


## Takes over what [param saved] keeps ([method to_dictionary]).
func load_dictionary(saved: Dictionary) -> void:
	_done.clear()
	rescued = int(saved.get(RESCUED_KEY, 0))
	wetsuit = bool(saved.get(WETSUIT_KEY, false))
	for level: Variant in saved.get(DONE_KEY, []):
		mark_done(int(level))
	var place: Array = saved.get(POSITION_KEY, [0, 0])
	if place.size() == 2:
		map_position = Vector2i(int(place[0]), int(place[1]))
