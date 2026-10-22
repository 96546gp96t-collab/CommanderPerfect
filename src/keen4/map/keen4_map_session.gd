class_name Keen4MapSession
extends RefCounted
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

## Info values (Omni): Keen on the map, Miragia.
const MAP_KEEN_INFO := Keen4Episode.MAP_KEEN_INFO
const MIRAGIA_INFO := 33
## Done levels mark the map (Omni ck_minDoneLevel, ck_maxDoneLevel).
const FIRST_DONE_LEVEL := 1
const LAST_DONE_LEVEL := 17
## The high byte of an info word: a fence to remove, a flag holder.
const FENCE := 0xD0
const FLAG_HOLDER := 0xF0
const LEVEL_MASK := 0xFF
const KIND_SHIFT := 8
## Where a flag stands from its holder's corner, and where a thrown one
## ends (Omni, Keen 4).
const FLAG_OFFSET := Vector2i(0x60, -0x1E0)
const THROW_OFFSET := Vector2i(0x60, -0x260)

var map: GalaxyMap
var world: GalaxyWorld
var keen: Keen4MapKeen
var camera: GalaxyCamera
var flags: Array[GalaxyMapFlag] = []
var miragia: Keen4Miragia


## The world map [param world_map] (read fresh) for a game at
## [param progress], with the sprites of [param data]; null without a map
## Keen. [param random_start] is where the random table starts.
static func start(
	data: GalaxyData, world_map: GalaxyMap, progress: Keen4Progress, random_start := 0
) -> Keen4MapSession:
	return create(
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
static func create(
	world_map: GalaxyMap,
	tiles: GalaxyTileInfo,
	sprite_infos: Array[GalaxySpriteInfo],
	random_table: PackedByteArray,
	progress: Keen4Progress,
	random_start := 0
) -> Keen4MapSession:
	var start_place := Keen4Start.find(world_map)
	if start_place.kind != Keen4Start.Kind.WORLD_MAP:
		return null
	var session := Keen4MapSession.new()
	session.map = world_map
	session.camera = GalaxyCamera.for_map(
		Vector2i(world_map.width, world_map.height),
		GalaxyCamera.blocks_in(world_map, Keen4Episode.COLUMN_BLOCK_INFO, true),
		GalaxyCamera.blocks_in(world_map, Keen4Episode.ROW_BLOCK_INFO, false)
	)
	var world := GalaxyWorld.create(world_map, tiles, sprite_infos)
	world.camera = session.camera
	world.random_table = random_table
	world.random_index = random_start
	world.map_number = Keen4Episode.WORLD_MAP
	session.world = world
	var sprites := Keen4Sprites.all()
	var at := progress.map_position
	if at == Vector2i.ZERO:
		at = start_place.position
	session.keen = Keen4MapKeen.spawn_keen4(world, at, sprites, progress.wetsuit)
	session._place_miragia()
	session._mark_done(progress, sprites)
	if progress.foot_flight:
		session.keen.fly_on_foot()
	session.camera.centre_on(at.x, 0, true, at.y)
	return session


## Runs one logic frame of [param tics] tics ending on tic [param tic],
## with [param input] held; then the view follows Keen.
func run_frame(input: KeenInput, tics: int, tic: int) -> void:
	if world.state != GalaxyWorld.LevelState.PLAYING:
		return
	world.tics = tics
	keen.begin_frame(input)
	world.run_frame(tics, tic)
	var box := keen.box
	camera.follow_map(box.left, box.top, box.right, box.bottom)


## The level Keen entered, or 0.
func entered() -> int:
	return keen.entered if world.state == GalaxyWorld.LevelState.COMPLETED else 0


## The message a frame asked for ([constant Keen4MapKeen.CANT_SWIM]), once;
## empty when none.
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


func _place_miragia() -> void:
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == MIRAGIA_INFO:
				miragia = Keen4Miragia.place(world, Vector2i(x, y))


## The done levels on the map (Omni CK_MapLevelMarkAsDone): their info
## words cleared, fences gone, flags at their holders.
func _mark_done(progress: Keen4Progress, sprites: Dictionary[StringName, int]) -> void:
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
			if kind == FENCE:
				world.set_fore_tile(cell, GalaxyTileKinds.EMPTY_TILE)
			elif kind == FLAG_HOLDER and level == progress.last_finished:
				flags.append(
					GalaxyMapFlag.throw_from(world, keen.position, cell, THROW_OFFSET, sprites)
				)
			elif kind == FLAG_HOLDER:
				flags.append(GalaxyMapFlag.wave_at(world, cell, FLAG_OFFSET, sprites))
