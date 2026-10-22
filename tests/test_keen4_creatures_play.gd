extends "res://tests/test_case.gd"
## Checks Keen 4's creatures with the player's real files (milestone D5):
## every info value in levels 1-16 places something or is knowingly left
## for D7 (D6 placed the rest: test_keen4_d6_play.gd), the difficulty
## decides which creatures level 1 has, every sprite name the creatures use
## is a real sprite, and every level runs a while with its creatures (Keen
## in god mode). Skipped without the files.

const FIRST_LEVEL := 1
const LAST_LEVEL := 16
## Info values that are not creatures (Omni, research.md §6): Keen 1 / 2,
## the scroll blocks 25 / 26, the stunner for few charges 34, the items
## 57-68; since D6 also the platforms' turn point 31 (the platforms read it).
const NOT_CREATURES: PackedInt32Array = [1, 2, 25, 26, 31, 34]
const FIRST_ITEM := 57
const LAST_ITEM := 68
## Values from this on are targets under doors and switches.
const FIRST_TARGET := 0x100
## Level 1 (files, v1.0): two Bounders (12), two slugs (22) and one more
## from Normal (43), two Licks only on Hard (48).
const LEVEL_1_COUNTS := {
	GalaxyDifficulty.Level.EASY: [2, 2, 0],
	GalaxyDifficulty.Level.NORMAL: [2, 3, 0],
	GalaxyDifficulty.Level.HARD: [2, 3, 2],
}
const RUN_FRAMES := 300

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_every_info_value_is_known() -> void:
	var unknown: Array[String] = []
	var placed := 0
	for number in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var map := _data.maps.load_map(number)
		for value in map.planes[GalaxyMap.Layer.INFO]:
			if value == 0 or value >= FIRST_TARGET or value in NOT_CREATURES:
				continue
			if value >= FIRST_ITEM and value <= LAST_ITEM:
				continue
			if Keen4Creatures.PLACED.has(value):
				placed += 1
			elif not value in Keen4Creatures.LATER:
				unknown.append("%d in level %d" % [value, number])
	assert_equal(unknown, [] as Array[String], "every value is placed or planned")
	assert_true(placed > 300, "hundreds of creatures in levels 1-16 (%d)" % placed)


func test_level_1_by_difficulty() -> void:
	for level in LEVEL_1_COUNTS:
		var session := _level(1, level)
		var counts := [
			_count(session, Keen4Bounder), _count(session, Keen4Slug), _count(session, Keen4Lick)
		]
		assert_equal(counts, LEVEL_1_COUNTS[level], "level 1's creatures on %d" % level)


func test_every_creature_sprite_is_real() -> void:
	var count := _data.graphics.sprite_infos.size()
	for name in Keen4CreatureSprites.SPRITES:
		var sprite := Keen4CreatureSprites.SPRITES[name]
		assert_true(sprite >= 0 and sprite < count, "%s is a sprite" % name)
	var sprites := Keen4Sprites.all()
	for table in [
		Keen4Slug.ROWS,
		Keen4Mushroom.ROWS,
		Keen4Egg.ROWS,
		Keen4Bird.ROWS,
		Keen4Arachnut.ROWS,
		Keen4Skypest.ROWS,
		Keen4Wormmouth.ROWS,
		Keen4Cloud.ROWS,
		Keen4Berkeloid.ROWS,
		Keen4Lick.ROWS,
		Keen4Mimrock.ROWS,
		Keen4Bounder.ROWS,
		Keen4Smirky.ROWS,
		Keen4Inchworm.ROWS,
		Keen4DartGun.ROWS,
		Keen4DartGun.DART_ROWS
	]:
		var actions := GalaxyAction.table_from(table, sprites)
		assert_equal(actions.size(), table.size(), "every row reads (%s)" % table[0])


func test_creatures_stand_on_the_ground_in_level_1() -> void:
	var session := _level(1, GalaxyDifficulty.DEFAULT)
	session.keen.god_mode = true
	_run(session, 4)
	for object in session.world.objects:
		if object is Keen4Slug and GalaxyWorld.is_awake(object):
			assert_true(object.top_hit != 0, "a slug on the ground")


func test_every_level_runs_with_its_creatures() -> void:
	for number in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var session := _level(number, GalaxyDifficulty.DEFAULT)
		session.keen.god_mode = true
		_run(session, RUN_FRAMES)
		assert_true(not session.is_lost(), "level %d: Keen lives in god mode" % number)
		var creatures := session.world.objects.filter(
			func(object: GalaxyObject) -> bool: return object is GalaxyCreature
		)
		assert_true(not creatures.is_empty(), "level %d has creatures" % number)


func _level(number: int, level: GalaxyDifficulty.Level) -> Keen4LevelSession:
	var map := _data.maps.load_map(number)
	return Keen4LevelSession.start(_data, map, Keen4Inventory.new_game(), 0, level)


func _count(session: Keen4LevelSession, type: Script) -> int:
	return (
		session
		. world
		. objects
		. filter(func(object: GalaxyObject) -> bool: return is_instance_of(object, type))
		. size()
	)


func _run(session: Keen4LevelSession, frames: int) -> void:
	for frame in frames:
		var first := session.world.tic == 0
		var tics := GalaxyClock.LEVEL_START_TICS if first else GalaxyClock.NORMAL_TICS
		session.run_frame(KeenInput.new(), tics, session.world.tic + tics)
