class_name Keen5LevelSession
extends GalaxyLevelSession
## One Keen 5 level being played: the Galaxy level ([GalaxyLevelSession])
## with Keen 5's Keen ([Keen5Keen]: the keycard, the security doors, the
## exit door), Keen 5's creatures ([Keen5Creatures], milestone E4) for
## the difficulty, its platforms ([Keen5Platforms]) and its fuses and the
## QED ([Keen5Fuses], E5); objects fall asleep 6 tiles beyond the view
## (Keen 4: 4). How it was left gives the value the original keeps for a
## done level ([method result]; docs/keen5/gameplay.md).

## Objects sleep this many tiles beyond the view (Omni CK_activeLimit,
## EPISODE.CK5).
const SLEEP_MARGIN := 6
## What a done level counts as (Omni levelsDone): 1 left by a door (also
## to Korath III), 14 ended by its fuse (LS_KorathFuse); the QED's end
## ends the game (LS_DestroyedQED, 15).
const DONE := 1
const DONE_BY_FUSE := 14
const DONE_BY_QED := 15


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


## What the level counts as now that it is done ([constant DONE],
## [constant DONE_BY_FUSE], [constant DONE_BY_QED]); 0 while it is not.
func result() -> int:
	if not is_done():
		return 0
	match ending():
		Keen5LevelEnd.FUSE_ENDING:
			return DONE_BY_FUSE
		Keen5LevelEnd.QED_ENDING:
			return DONE_BY_QED
	return DONE


## The fuses of the level not broken yet.
func fuses_remaining() -> int:
	var carried := inventory as Keen5Inventory
	return carried.fuses_remaining if carried != null else 0


## Sets up the level as [method GalaxyLevelSession.begin] does, with Keen
## 5's sleep margin; the fuses are counted again (Omni CK5_ScanInfoLayer).
func begin(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> bool:
	var keen_5 := carried as Keen5Inventory
	if keen_5 != null:
		keen_5.fuses_remaining = 0
	if not super(data, game_rules, level_map, carried, random_start, level, map_number):
		return false
	world.sleep_margin = SLEEP_MARGIN
	return true


func _new_keen() -> GalaxyKeen:
	return Keen5Keen.new()


## The creatures, platforms and fuses of the info plane, for the
## difficulty played.
func _place_info(info: int, cell: Vector2i) -> void:
	if info == Keen5Fuses.COUNTER_INFO:
		var carried := inventory as Keen5Inventory
		if carried != null:
			Keen5Fuses.count_info(world, cell, carried, rules.sprites)
		return
	Keen5Creatures.place_info(world, info, cell, difficulty, rules.sprites)
	Keen5Platforms.place_info(world, info, cell, difficulty, rules.sprites)
