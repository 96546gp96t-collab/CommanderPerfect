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


## Everything needed to continue this game later, as plain values for JSON.
func to_dict() -> Dictionary:
	var position := [] if not map_position.is_finite() else [map_position.x, map_position.y]
	return {
		"inventory": inventory.to_dict(),
		"completed": Array(completed_levels()),
		"map_position": position,
	}


## The game saved with [method to_dict], or null when [param data] is not one.
static func from_dict(data: Dictionary) -> GameProgress:
	var saved_inventory: Variant = data.get("inventory")
	var completed: Variant = data.get("completed")
	var position: Variant = data.get("map_position")
	if not (saved_inventory is Dictionary and completed is Array and position is Array):
		return null
	var game := GameProgress.new()
	game.inventory = Inventory.from_dict(saved_inventory)
	if game.inventory == null:
		return null
	for number: Variant in completed:
		game.complete_level(int(number))
	if position.size() == 2:
		game.map_position = Vector2(float(position[0]), float(position[1]))
	return game
