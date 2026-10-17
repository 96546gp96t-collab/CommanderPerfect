class_name Keen2Progress
extends GameProgress
## One game of Keen 2 from start to finish: what Keen carries (a
## [Keen2Inventory]), which levels he has completed and where he stands on
## the world map, as [GameProgress] keeps them for Keen 1.
##
## Keen 2 has no ship parts: it has eight cities, each with a Tantalus Ray
## machine in its level. A city is saved when its level is completed (as in
## Commander Genius; how the original keeps Keen from leaving before the
## machine is destroyed is still to be seen, docs/keen2/research.md). When
## all eight are saved, the ending starts. See docs/keen2/gameplay.md.

## The levels of the cities, in the order of the city names in KEEN2.EXE:
## London, Cairo, Sydney, New York, Paris, Rome, Moscow, Washington.
const CITY_LEVELS: PackedInt32Array = [4, 6, 7, 9, 11, 13, 15, 16]


func _init(keen_inventory: Inventory = null) -> void:
	inventory = keen_inventory if keen_inventory != null else Keen2Inventory.new()


## Whether level [param level_number] is one of the cities.
static func is_city(level_number: int) -> bool:
	return level_number in CITY_LEVELS


## For each city (in the order of [constant CITY_LEVELS]), whether it is saved.
func saved_cities() -> Array[bool]:
	var saved: Array[bool] = []
	for number in CITY_LEVELS:
		saved.append(is_completed(number))
	return saved


func saved_city_count() -> int:
	return saved_cities().count(true)


## Whether every city is saved: then the game is won.
func all_cities_saved() -> bool:
	return not saved_cities().has(false)
