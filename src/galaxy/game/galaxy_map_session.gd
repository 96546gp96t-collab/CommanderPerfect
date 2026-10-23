class_name GalaxyMapSession
extends RefCounted
## The world map of a Galaxy episode being played (made from Keen 4's
## [Keen4MapSession], milestone E6; Omni `ck_game.c:CK_LoadLevel`,
## `ck_map.c:CK_SpawnMapKeen`, `CK_MapLevelMarkAsDone`, `ck_play.c:
## CK_MapCamera`; facts only; docs/keen4/research.md §8, docs/keen5/
## research.md §8):
##   - the map Keen ([GalaxyMapKeen], or the episode's: [method _new_keen])
##     stands where he entered the last level, or on the rules' map-Keen
##     info in a new game ([method _keen_place]);
##   - every done level (1-17, [GalaxyProgress]) clears each info word whose
##     low byte is that level: no entrance any more; under a word 0xD0nn
##     the foreground tile goes too (a gate), at 0xF0nn a flag stands
##     ([GalaxyMapFlag], at the rules' offset); with
##     [member GalaxyGameRules.throws_map_flag] the level just finished gets
##     its flag thrown from Keen;
##   - the view follows him as the original's map camera does;
##   - jump, pogo or fire on an entrance ends the map ([method entered]).
## An episode adds what its map has besides through the hooks
## [method _place_extras] (after Keen is placed, before the done levels
## are marked) and [method _runs_own_frame] (a frame the episode runs
## itself, such as Keen 5's teleporters and elevators).

## Done levels mark the map (Omni ck_minDoneLevel, ck_maxDoneLevel).
const FIRST_DONE_LEVEL := 1
const LAST_DONE_LEVEL := 17
## The high byte of an info word: a gate to remove, a flag holder.
const GATE := 0xD0
const FLAG_HOLDER := 0xF0
const LEVEL_MASK := 0xFF
const KIND_SHIFT := 8

var rules: GalaxyGameRules
var map: GalaxyMap
var world: GalaxyWorld
var keen: GalaxyMapKeen
var camera: GalaxyCamera
var flags: Array[GalaxyMapFlag] = []


## The world map [param world_map] (read fresh) of [param data] by
## [param game_rules], for a game at [param progress]; null without a map
## Keen. [param random_start] is where the random table starts.
static func start_map(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	world_map: GalaxyMap,
	progress: GalaxyProgress,
	random_start := 0
) -> GalaxyMapSession:
	var session := GalaxyMapSession.new()
	if not session.begin_with(data, game_rules, world_map, progress, random_start):
		return null
	return session


## Sets the map up from [param data] (see [method start_map]); returns
## whether it has a map Keen.
func begin_with(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	world_map: GalaxyMap,
	progress: GalaxyProgress,
	random_start := 0
) -> bool:
	return begin(
		game_rules,
		world_map,
		data.tile_info,
		data.graphics.sprite_infos,
		data.executable.random_table(),
		progress,
		random_start
	)


## The same from its parts: [param tiles] the tile information,
## [param sprite_infos] the sprite table, [param random_table] the random
## numbers.
func begin(
	game_rules: GalaxyGameRules,
	world_map: GalaxyMap,
	tiles: GalaxyTileInfo,
	sprite_infos: Array[GalaxySpriteInfo],
	random_table: PackedByteArray,
	progress: GalaxyProgress,
	random_start := 0
) -> bool:
	rules = game_rules
	var start_place := GalaxyStart.find(world_map, rules)
	if start_place.kind != GalaxyStart.Kind.WORLD_MAP:
		return false
	map = world_map
	camera = GalaxyCamera.for_map(
		Vector2i(map.width, map.height),
		GalaxyCamera.blocks_in(map, rules.column_block_info, true),
		GalaxyCamera.blocks_in(map, rules.row_block_info, false)
	)
	world = GalaxyWorld.create(map, tiles, sprite_infos)
	world.camera = camera
	world.random_table = random_table
	world.random_index = random_start
	world.map_number = rules.world_map
	var at := _keen_place(start_place, progress)
	keen = _new_keen()
	keen.place(world, at, rules.sprites)
	_place_extras(progress)
	_mark_done(progress)
	camera.centre_on(at.x, 0, true, at.y)
	return true


## Runs one logic frame of [param tics] tics ending on tic [param tic],
## with [param input] held; then the view follows Keen.
func run_frame(input: KeenInput, tics: int, tic: int) -> void:
	if world.state != GalaxyWorld.LevelState.PLAYING:
		return
	world.tics = tics
	keen.begin_frame(input)
	if _runs_own_frame(tics, tic):
		return
	world.run_frame(tics, tic)
	_follow_keen()
	_after_world_frame()


## The level Keen entered, or 0.
func entered() -> int:
	return keen.entered if world.state == GalaxyWorld.LevelState.COMPLETED else 0


## The message a frame asked for, once; empty when none.
func take_conversation() -> StringName:
	var asked := world.conversation
	world.conversation = &""
	return asked


## Whether a flag is still in the air.
func throws_flag() -> bool:
	for flag in flags:
		if flag.is_thrown():
			return true
	return false


## The map Keen of the episode (not yet placed).
func _new_keen() -> GalaxyMapKeen:
	return GalaxyMapKeen.new()


## Where Keen stands when the map starts: where he entered the last level
## ([member GalaxyProgress.map_position]), or at [param start_place] in a
## new game (Omni CK_SpawnMapKeen).
func _keen_place(start_place: GalaxyStart, progress: GalaxyProgress) -> Vector2i:
	if progress.map_position != Vector2i.ZERO:
		return progress.map_position
	return start_place.position


## What the episode's map has besides, set up once Keen stands (nothing by
## default).
func _place_extras(_progress: GalaxyProgress) -> void:
	pass


## Runs a frame of the episode's own instead of the world's; returns
## whether it did (never by default).
func _runs_own_frame(_tics: int, _tic: int) -> bool:
	return false


## After the world's frame and the view (nothing by default).
func _after_world_frame() -> void:
	pass


## The view follows Keen's box (Omni CK_MapCamera).
func _follow_keen() -> void:
	var box := keen.box
	camera.follow_map(box.left, box.top, box.right, box.bottom)


## The done levels on the map (Omni CK_MapLevelMarkAsDone): their info
## words cleared, gates gone, flags at their holders.
func _mark_done(progress: GalaxyProgress) -> void:
	for y in map.height:
		for x in map.width:
			var word := map.tile(GalaxyMap.Layer.INFO, x, y)
			var level := word & LEVEL_MASK
			if level < FIRST_DONE_LEVEL or level > LAST_DONE_LEVEL:
				continue
			if not progress.is_done(level):
				continue
			var cell := Vector2i(x, y)
			world.set_info(cell, 0)
			var kind := word >> KIND_SHIFT
			if kind == GATE:
				world.set_fore_tile(cell, GalaxyTileKinds.EMPTY_TILE)
			elif kind == FLAG_HOLDER:
				flags.append(_flag_at(cell, level == progress.last_finished))


## The flag at the holder [param cell]: thrown from Keen when it is the
## level [param just_finished] and the episode throws flags, otherwise
## waving.
func _flag_at(cell: Vector2i, just_finished: bool) -> GalaxyMapFlag:
	if just_finished and rules.throws_map_flag:
		return GalaxyMapFlag.throw_from(
			world, keen.position, cell, rules.map_flag_throw_offset, rules.sprites
		)
	return GalaxyMapFlag.wave_at(
		world, cell, rules.map_flag_offset, rules.sprites, not rules.throws_map_flag
	)
