class_name Keen5LevelSession
extends GalaxyLevelSession
## One Keen 5 level being played: the Galaxy level ([GalaxyLevelSession])
## with Keen 5's Keen ([Keen5Keen]: the keycard, the security doors, the
## exit door) and Keen 5's creatures ([Keen5Creatures], milestone E4) for
## the difficulty; objects fall asleep 6 tiles beyond the view (Keen 4: 4).
## The platforms of the info plane come in milestone E5
## (docs/keen5/gameplay.md).

## Objects sleep this many tiles beyond the view (Omni CK_activeLimit,
## EPISODE.CK5).
const SLEEP_MARGIN := 6


## The level [param level_map] of Keen 5 ([param data], [param rules]) with
## Keen carrying [param carried], or null when Keen does not stand in it
## (see [method GalaxyLevelSession.start]).
static func start_level(
	data: GalaxyData,
	rules: GalaxyGameRules,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> Keen5LevelSession:
	var session := Keen5LevelSession.new()
	if not session.begin(data, rules, level_map, carried, random_start, level, map_number):
		return null
	return session


## Whether Keen left the level by the door to Korath III
## ([constant Keen5Keen.KORATH_ENDING]), not by the exit door or walking
## out.
func left_for_korath() -> bool:
	return ending() == Keen5Keen.KORATH_ENDING


## Sets up the level as [method GalaxyLevelSession.begin] does, with Keen
## 5's sleep margin.
func begin(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> bool:
	if not super(data, game_rules, level_map, carried, random_start, level, map_number):
		return false
	world.sleep_margin = SLEEP_MARGIN
	return true


func _new_keen() -> GalaxyKeen:
	return Keen5Keen.new()


## The creatures of the info plane, for the difficulty played.
func _place_info(info: int, cell: Vector2i) -> void:
	Keen5Creatures.place_info(world, info, cell, difficulty, rules.sprites)
