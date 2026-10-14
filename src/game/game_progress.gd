class_name GameProgress
extends RefCounted
## One game from start to finish: what Keen carries ([Inventory]), which
## levels he has completed and where he stands on the world map.
##
## Completed levels are marked "done" on the map and cannot be entered again.
## The map position is where Keen entered the last level: after the level,
## whether he completed it or died, he is back on the map there.

var inventory := Inventory.new()
## Top left of Keen's sprite on the world map; [constant Vector2.INF] until
## he has walked there (he then starts at the start cell of the map).
var map_position := Vector2.INF
var _completed: Dictionary[int, bool] = {}


func complete_level(level_number: int) -> void:
	_completed[level_number] = true


func is_completed(level_number: int) -> bool:
	return _completed.get(level_number, false)


## Numbers of the completed levels, in ascending order.
func completed_levels() -> PackedInt32Array:
	var numbers := PackedInt32Array(_completed.keys())
	numbers.sort()
	return numbers
