class_name Keen5LevelSession
extends GalaxyLevelSession
## One Keen 5 level being played: the Galaxy level ([GalaxyLevelSession])
## with Keen 5's Keen ([Keen5Keen]: the keycard, the security doors, the
## exit door). The creatures and platforms of the info plane come in
## milestones E4 and E5 ([method _place_info]); until then the level holds
## Keen and the items only (docs/keen5/gameplay.md).


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


func _new_keen() -> GalaxyKeen:
	return Keen5Keen.new()
