class_name Keen4MapSession
extends GalaxyMapSession
## Keen 4's world map (map 0) being played (milestone D7; Omni
## `ck4_misc.c:CK4_ScanInfoLayer`, `ck_game.c:CK_MapLevelMarkAsDone`,
## `ck_play.c:CK_MapCamera`; facts only; docs/keen4/research.md §8):
##   - the map Keen ([Keen4MapKeen]) stands where he entered the last level,
##     or on info 3 in a new game, or flies on the Foot when the last level
##     ended by it;
##   - Miragia comes and goes (info 33, [Keen4Miragia]);
##   - every done level (1-17, [Keen4Progress]) clears each info word whose
##     low byte is that level: no entrance any more; under a word 0xD0nn the
##     foreground tile goes too (the fences), at 0xF0nn a flag stands
##     ([GalaxyMapFlag]); the level just finished gets its flag thrown from
##     Keen;
##   - the view follows him as the original's map camera does;
##   - jump, pogo or fire on an entrance ends the map ([method entered]).
## The shared [GalaxyMapSession] by Keen 4's rules since milestone E13.

## Info values (Omni): Keen on the map, Miragia.
const MAP_KEEN_INFO := Keen4Episode.MAP_KEEN_INFO
const MIRAGIA_INFO := 33
## The high byte of an info word: a fence to remove (the shared gate).
const FENCE := GATE
## Where a flag stands from its holder's corner, and where a thrown one
## ends (Omni, Keen 4).
const FLAG_OFFSET := Vector2i(0x60, -0x1E0)
const THROW_OFFSET := Vector2i(0x60, -0x260)

var miragia: Keen4Miragia
## Whether Keen has the wetsuit, while the map is set up.
var _wetsuit := false


## The world map [param world_map] (read fresh) for a game at
## [param progress], with the sprites of [param data]; null without a map
## Keen. [param random_start] is where the random table starts.
static func start(
	data: GalaxyData, world_map: GalaxyMap, progress: Keen4Progress, random_start := 0
) -> Keen4MapSession:
	return start_map(data, Keen4Episode.game_rules(), world_map, progress, random_start)


## The same by [param game_rules] (the view's).
static func start_map(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	world_map: GalaxyMap,
	progress: GalaxyProgress,
	random_start := 0
) -> Keen4MapSession:
	var session := Keen4MapSession.new()
	if not session.begin_with(data, game_rules, world_map, progress, random_start):
		return null
	return session


## The same from its parts: [param tiles] the tile information,
## [param sprite_infos] the sprite table, [param random_table] the random
## numbers.
static func create(
	world_map: GalaxyMap,
	tiles: GalaxyTileInfo,
	sprite_infos: Array[GalaxySpriteInfo],
	random_table: PackedByteArray,
	progress: Keen4Progress,
	random_start := 0
) -> Keen4MapSession:
	var session := Keen4MapSession.new()
	var rules_4 := Keen4Episode.game_rules()
	if not session.begin(
		rules_4, world_map, tiles, sprite_infos, random_table, progress, random_start
	):
		return null
	return session


## Sets the map up (see [method GalaxyMapSession.begin]); then Keen flies
## on the Foot when the last level ended by it.
func begin(
	game_rules: GalaxyGameRules,
	world_map: GalaxyMap,
	tiles: GalaxyTileInfo,
	sprite_infos: Array[GalaxySpriteInfo],
	random_table: PackedByteArray,
	progress: GalaxyProgress,
	random_start := 0
) -> bool:
	var keen_4 := progress as Keen4Progress
	_wetsuit = keen_4 != null and keen_4.wetsuit
	if not super(game_rules, world_map, tiles, sprite_infos, random_table, progress, random_start):
		return false
	if keen_4 != null and keen_4.foot_flight:
		(keen as Keen4MapKeen).fly_on_foot()
	return true


## Keen 4's map Keen: he swims with the wetsuit, the Foot carries him.
func _new_keen() -> GalaxyMapKeen:
	var map_keen := Keen4MapKeen.new()
	map_keen.wetsuit = _wetsuit
	return map_keen


## Miragia comes and goes (info 33).
func _place_extras(_progress: GalaxyProgress) -> void:
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == MIRAGIA_INFO:
				miragia = Keen4Miragia.place(world, Vector2i(x, y))
