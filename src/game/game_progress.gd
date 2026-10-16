class_name GameProgress
extends RefCounted
## One game from start to finish: what Keen carries ([Inventory]), which
## levels he has completed, which ship parts he has put back into his ship
## and where he stands on the world map.
##
## Completed levels are marked "done" on the map and cannot be entered again.
## With the extra levels on there is one exception: the level with the pogo
## stick stays open until Keen has it, so that it cannot be missed for good.
## The map position is where Keen entered the last level: after the level,
## whether he completed it or died, he is back on the map there.

## The level of Keen 1 where the pogo stick lies.
const POGO_LEVEL := 5

var inventory := Inventory.new()
## The ship parts Keen has put back into his ship (see [ShipRepair]), in the
## order of [enum Inventory.ShipPart]. Only used with the extra levels on.
var installed_parts: Array[bool] = [false, false, false, false]
## Top left of Keen's sprite on the world map; [constant Vector2.INF] until
## he has walked there (he then starts at the start cell of the map).
var map_position := Vector2.INF
var _completed: Dictionary[int, bool] = {}


func complete_level(level_number: int) -> void:
	_completed[level_number] = true


func is_completed(level_number: int) -> bool:
	return _completed.get(level_number, false)


## Whether Keen may enter level [param level_number] from the map: when he
## has not completed it yet, or when it is the pogo level and he left the
## pogo stick behind ([param replays_pogo_level], with the extra levels on).
func can_enter(level_number: int, replays_pogo_level: bool) -> bool:
	if not is_completed(level_number):
		return true
	return replays_pogo_level and level_number == POGO_LEVEL and not inventory.has_pogo


func install_part(part: Inventory.ShipPart) -> void:
	installed_parts[part] = true


## Whether every part is back in the ship: then it can fly home.
func all_parts_installed() -> bool:
	return not installed_parts.has(false)


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
		"installed_parts": installed_parts.duplicate(),
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
	# Games saved before the ship could be repaired have no installed parts.
	var installed: Variant = data.get("installed_parts", [])
	if installed is Array and installed.size() == game.installed_parts.size():
		for part in installed.size():
			game.installed_parts[part] = bool(installed[part])
	return game
