class_name GalaxyProgress
extends RefCounted
## How far a game of a Galaxy episode has come, beyond what Keen carries
## ([GalaxyInventory]); made from Keen 4's [Keen4Progress] (milestone E6;
## Omni `ck_def.h` ck_gameState: levelsDone, mapPosX/Y;
## ck_lastLevelFinished): which levels are done and the value each was
## done with (the world map's flags and gates; Keen 5 keeps 1, or 14 for a
## level its fuse ended: [Keen5Progress]), where Keen stood on the world
## map when he entered the last level, and which level was just finished.
## An episode adds its own (Keen 4's rescues and wetsuit, Keen 5's arrival
## on Korath III) in a subclass, with [method _extra_to_dictionary] and
## [method _extra_from_dictionary] for a saved game.

## The value of a level done the usual way (Omni levelsDone = 1).
const DONE := 1
## The names in [method to_dictionary].
const DONE_KEY := "levels_done"
const POSITION_KEY := "map_position"

## Keen's place on the world map (units); zero: where the map puts him.
var map_position := Vector2i.ZERO
## The level finished last, -1 when the last level was not finished.
var last_finished := -1
var _done: Dictionary[int, int] = {}


## Level [param level] is done, counting [param value] (0 is not done).
func mark_done(level: int, value := DONE) -> void:
	if value == 0:
		_done.erase(level)
	else:
		_done[level] = value


func is_done(level: int) -> bool:
	return _done.has(level)


## The value level [param level] was done with; 0 when it is not done.
func done_value(level: int) -> int:
	return _done.get(level, 0)


## The levels done, in order.
func done_levels() -> PackedInt32Array:
	var levels := PackedInt32Array(_done.keys())
	levels.sort()
	return levels


## The world map was set up for this game: what was only for that once
## (the level just finished, an episode's arrival) is used up.
func map_shown() -> void:
	last_finished = -1


## What a saved game keeps: the levels done with their values and the
## place on the map, and the episode's own ([method _extra_to_dictionary]).
func to_dictionary() -> Dictionary:
	var done := {}
	for level in done_levels():
		done[str(level)] = _done[level]
	var saved := {DONE_KEY: done, POSITION_KEY: [map_position.x, map_position.y]}
	saved.merge(_extra_to_dictionary())
	return saved


## Takes over what [param saved] keeps ([method to_dictionary]); missing
## parts are as in a new game.
func load_dictionary(saved: Dictionary) -> void:
	_done.clear()
	var done: Variant = saved.get(DONE_KEY, {})
	if done is Dictionary:
		for level: Variant in done:
			mark_done(int(level), int(done[level]))
	var place: Variant = saved.get(POSITION_KEY, [0, 0])
	if place is Array and place.size() == 2:
		map_position = Vector2i(int(place[0]), int(place[1]))
	_extra_from_dictionary(saved)


## What an episode keeps besides (nothing by default).
func _extra_to_dictionary() -> Dictionary:
	return {}


## Takes over what an episode keeps besides from [param _saved].
func _extra_from_dictionary(_saved: Dictionary) -> void:
	pass
