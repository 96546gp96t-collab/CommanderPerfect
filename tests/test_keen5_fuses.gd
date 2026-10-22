extends "res://tests/test_case.gd"
## Checks Keen 5's fuses, the QED and the teleport lightning in hand-made
## mini levels (milestone E5): info 41 counts the fuses (on map 12 it sets
## 4 and places the QED); a pogo landing at 48 or faster breaks a fuse (its
## explosion, one fuse fewer, the rubble from the map's corner, Keen falls
## on), a jump or a slower pogo only plays its sound; the last fuse ends
## the level 60 tics later as a fuse's (14) or, on map 12, the QED's; a
## mine's piece destroys the QED, a Shelley's does not; starting into a
## door whose head-row info is 0 brings the lightning (Omni numbers;
## docs/keen5/research.md §4).

const Fixtures := preload("res://tests/keen5_machine_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const Level := preload("res://tests/keen5_level_fixtures.gd")

const TILE := 256
const COUNTER := Keen5Fuses.COUNTER_INFO
const NORMAL := GalaxyDifficulty.Level.NORMAL
## A fuse under Keen's landing spot, its upper half above it (the rows'
## cells); the floor further down.
const FUSE_ROWS: PackedStringArray = [
	"K...................",
	"##..................",
	"....................",
	"....................",
	"....................",
	"........F...........",
	"....................",
	"....................",
	"####################",
]
## The fuse's tile and the one above it, in map cells.
const FUSE_CELL := Vector2i(10, 7)
const ABOVE_FUSE := Vector2i(10, 6)
const LEVEL_END_TICS := 60
## Coming down on the pogo below the breaking speed (48), and above it.
const SLOW := 30
const FAST := 60
const FRAME_TICS := 2
## A level large enough for the QED's fixed blocks at (16, 11) and
## (16, 13).
const QED_ROWS: PackedStringArray = [
	"K...................",
	"##..................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"####################",
]
## The QED's map and its tile in the mini level (rows' cells).
const QED_MAP := 12
const QED_CELL := Vector2i(8, 5)


func test_info_41_counts_the_fuses() -> void:
	var world := Fixtures.world(
		FUSE_ROWS, Keen5Fuses.COUNTER_INFO, [Vector2i(1, 0), Vector2i(2, 0)]
	)
	assert_equal(_carried(world).fuses_remaining, 2, "two fuses")
	assert_equal(Fixtures.count(world, Keen5Qed), 0, "no QED off map 12")


func test_info_41_on_map_12_is_four_fuses_and_the_qed() -> void:
	var map := Fixtures.level(QED_ROWS)
	Keen.put_info(map, QED_CELL, Keen5Fuses.COUNTER_INFO)
	var world := _world_on_map(map, QED_MAP)
	assert_equal(_carried(world).fuses_remaining, 4, "four")
	var qed := Fixtures.first(world, Keen5Qed) as Keen5Qed
	assert_true(qed != null, "the QED")
	var corner := (QED_CELL + Vector2i(2, 2)) * TILE
	assert_equal(qed.box.left, corner.x - 0x10, "its box from 0x10 left of its tile")
	assert_equal(qed.box.top, corner.y - 0x10, "and above")
	assert_equal(qed.box.right - qed.box.left, 0x220, "0x220 wide")
	assert_equal(qed.box.bottom - qed.box.top, 0x220, "and high")
	assert_equal(qed.sprite, GalaxyObject.NO_SPRITE, "unseen")


func test_a_fast_pogo_landing_breaks_the_fuse() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(FUSE_ROWS, COUNTER, [Vector2i(1, 0)], NORMAL, sounds)
	var keen := Fixtures.keen(world)
	Fixtures.pogo_down_onto(world, FUSE_CELL, 8, FAST)
	for frame in 10:
		Fixtures.wait(world, 1)
		if world.fore_tile(FUSE_CELL.x, FUSE_CELL.y) != Fixtures.FUSE:
			break
	assert_equal(world.fore_tile(FUSE_CELL.x, FUSE_CELL.y), Fixtures.RUBBLE, "the fuse is rubble")
	assert_equal(world.fore_tile(ABOVE_FUSE.x, ABOVE_FUSE.y), Fixtures.RUBBLE, "its upper half")
	assert_true(sounds.has(&"fuse_break"), "its sound")
	assert_equal(_carried(world).fuses_remaining, 0, "none left")
	var flash := Fixtures.first(world, Keen5Flash) as Keen5Flash
	assert_true(flash != null, "the explosion")
	if flash != null:
		assert_equal(flash.position, (ABOVE_FUSE + Vector2i.LEFT) * TILE, "one tile left")
		assert_equal(flash.priority, 3, "in front")
	assert_true(Fixtures.first(world, Keen5LevelEnd) != null, "the level will end")
	var y := keen.position.y
	Fixtures.wait(world, 3)
	assert_true(keen.position.y > y, "he falls on through it")
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "not at once")
	_run_tics(world, LEVEL_END_TICS)
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "60 tics later it ends")
	assert_equal(world.ending, Keen5LevelEnd.FUSE_ENDING, "as a fuse's")


func test_the_explosion_shows_three_pictures() -> void:
	var world := Fixtures.world(FUSE_ROWS, 0, [])
	var flash := Keen5Flash.fuse_explosion(world, FUSE_CELL, Keen5Sprites.all())
	var shown: Array[int] = []
	var times: Dictionary[int, int] = {}
	for frame in 30:
		if flash.removed:
			break
		if not shown.has(flash.sprite):
			shown.append(flash.sprite)
		times[flash.sprite] = times.get(flash.sprite, 0) + FRAME_TICS
		Fixtures.wait(world, 1)
	var first := Keen5Sprites.MACHINERY[&"FUSEFLASH1"]
	assert_equal(shown, [first, first + 1, first + 2] as Array[int], "FUSEFLASH1-3")
	assert_true(flash.removed, "then gone")


func test_a_jump_or_a_slow_pogo_only_plays_the_sound() -> void:
	for pogo in [false, true]:
		var sounds: Array[StringName] = []
		var world := Fixtures.world(FUSE_ROWS, COUNTER, [Vector2i(1, 0)], NORMAL, sounds)
		var keen := Fixtures.keen(world)
		Fixtures.pogo_down_onto(world, FUSE_CELL, 8, SLOW)
		if not pogo:
			keen.set_action(keen.actions[&"fall_1"])
			keen.velocity.y = 70
		for frame in 6:
			Fixtures.wait(world, 1)
		var what := "pogo" if pogo else "jump"
		assert_equal(world.fore_tile(FUSE_CELL.x, FUSE_CELL.y), Fixtures.FUSE, "%s: whole" % what)
		assert_true(sounds.has(&"keen_land_on_fuse"), "%s: its sound" % what)
		assert_true(not sounds.has(&"fuse_break"), "%s: no break" % what)
		assert_equal(_carried(world).fuses_remaining, 1, "%s: still one" % what)
	var world := Fixtures.world(FUSE_ROWS, 0, [])
	var keen := Fixtures.keen(world)
	Fixtures.pogo_down_onto(world, FUSE_CELL, 8, SLOW)
	for frame in 3:
		Fixtures.wait(world, 1)
	assert_true(keen.action.name.begins_with("pogo"), "the slow pogo bounces off it")


func test_on_map_12_the_last_fuse_ends_it_as_the_qed() -> void:
	var map := Fixtures.level(FUSE_ROWS)
	var world := _world_on_map(map, QED_MAP)
	_carried(world).fuses_remaining = 1
	Fixtures.pogo_down_onto(world, FUSE_CELL, 8, FAST)
	_run_tics(world, LEVEL_END_TICS + 20)
	assert_equal(world.ending, Keen5LevelEnd.QED_ENDING, "the QED's end")


func test_a_mines_piece_destroys_the_qed() -> void:
	var sounds: Array[StringName] = []
	var map := Fixtures.level(QED_ROWS)
	Keen.put_info(map, QED_CELL, Keen5Fuses.COUNTER_INFO)
	# Marks in the corner blocks the broken machine is copied from.
	for x in 8:
		for y in 2:
			map.planes[GalaxyMap.Layer.FOREGROUND][y * map.width + x] = 20 + x + y * 8
	var world := _world_on_map(map, QED_MAP, sounds)
	var qed := Fixtures.first(world, Keen5Qed) as Keen5Qed
	world.camera.centre_on(qed.box.middle, qed.box.bottom)
	var shelley := _piece(world, qed, false)
	Fixtures.wait(world, 1)
	assert_true(not qed.removed, "a Shelley's piece does not")
	shelley.removed = true
	_piece(world, qed, true)
	Fixtures.wait(world, 1)
	assert_true(qed.removed, "a mine's piece destroys it")
	assert_equal(Fixtures.count(world, Keen5Flash), 4, "four explosions")
	assert_equal(sounds.count(&"fuse_break"), 4, "four sounds")
	var tile := QED_CELL + Vector2i(2, 2)
	var places: Array[Vector2i] = []
	for object in world.objects:
		if object is Keen5Flash:
			places.append(object.position / TILE + Vector2i.RIGHT)
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		assert_true(places.has(tile + corner), "one at its corner %s" % corner)
	assert_equal(world.fore_tile(16, 11), 20, "the upper block from (0, 0)")
	assert_equal(world.fore_tile(19, 12), 20 + 3 + 8, "to (19, 12)")
	assert_equal(world.fore_tile(16, 13), 24, "the lower block from (4, 0)")
	assert_equal(world.fore_tile(19, 14), 24 + 3 + 8, "to (19, 14)")
	_run_tics(world, LEVEL_END_TICS + 4)
	assert_equal(world.ending, Keen5LevelEnd.QED_ENDING, "the level ends as the QED's")


func test_the_door_to_korath_brings_the_lightning() -> void:
	for target in [Keen5Keen.KORATH_TARGET, 0x0A03]:
		var sounds: Array[StringName] = []
		var map := Keen.level(Level.DOOR_ROWS)
		# Both columns of a door hold its target, as in the game's maps.
		Keen.put_info(map, Level.DOOR_TARGET_CELL, target)
		Keen.put_info(map, Level.DOOR_TARGET_CELL + Vector2i.RIGHT, target)
		var world := Level.world(map, sounds)
		var keen := Fixtures.keen(world)
		Level.walk_to(world, 5)
		for frame in 10:
			Level.press_up(world)
			if keen.action.name.begins_with("enter_door"):
				break
		var top := keen.box.tile_top
		var left := keen.box.tile_left
		var bottom := keen.box.tile_bottom
		var bolts := world.objects.filter(
			func(object: GalaxyObject) -> bool: return object is Keen5Flash
		)
		if target != Keen5Keen.KORATH_TARGET:
			assert_true(bolts.is_empty(), "a door with a target: no lightning")
			continue
		assert_equal(bolts.size(), 2, "two bolts")
		assert_true(sounds.has(&"teleport"), "its sound")
		if bolts.size() != 2:
			continue
		var across := Vector2i(left * TILE - 0x80, bottom * TILE - 0x500)
		var down := Vector2i(left * TILE, top * TILE - 0x80)
		assert_equal(bolts[0].position, across, "across, 5 tiles over his feet")
		assert_equal(bolts[1].position, down, "down over him")
		assert_equal(bolts[0].sprite, Keen5Sprites.MACHINERY[&"TELEPORTSPARK1"], "a spark")
		assert_equal(bolts[1].sprite, Keen5Sprites.MACHINERY[&"TELEPORTZAP1"], "a zap")


func _carried(world: GalaxyWorld) -> Keen5Inventory:
	return Fixtures.keen(world).inventory as Keen5Inventory


## The world of [param map] as map [param number] of the episode.
func _world_on_map(map: GalaxyMap, number: int, sounds: Array[StringName] = []) -> GalaxyWorld:
	return Fixtures.world_of(map, GalaxyDifficulty.DEFAULT, sounds, number)


## A piece in the middle of [param qed]'s box, a mine's when [param mine].
func _piece(world: GalaxyWorld, qed: Keen5Qed, mine: bool) -> Keen5Piece:
	var at := Vector2i(qed.box.middle, qed.box.top + 0x100)
	var piece := Keen5Piece.throw(
		world, at, Vector2i.ZERO, Keen5Mine.ROWS, Keen5Sprites.all(), &"piece"
	)
	piece.reports_touches = mine
	return piece


func _run_tics(world: GalaxyWorld, tics: int) -> void:
	for frame in tics / FRAME_TICS:
		if world.state != GalaxyWorld.LevelState.PLAYING:
			return
		Fixtures.wait(world, 1)
