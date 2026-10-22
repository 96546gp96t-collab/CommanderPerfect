extends "res://tests/test_case.gd"
## Checks Keen 5's creatures with the player's real files (milestone E4):
## every info value in levels 1-13 places something (a creature, a
## platform or the fuse counter, E5) or is knowingly left for a later
## milestone, every creature value places the right class on
## each difficulty (a census of all 13 levels), every sprite the creatures
## use is in the files, every Volteface finds its arrows, and every level
## runs a while with its creatures (Keen in god mode, running and jumping).
## Skipped without the files.

const LEVELS: PackedInt32Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
## Info values that are no creature (Omni, research.md §6): Keen 1 / 2 and
## the scroll block 25; the items 57-70 (with the stunner 69).
const NOT_CREATURES: PackedInt32Array = [1, 2, 25]
const FIRST_ITEM := 57
const LAST_ITEM := 70
## Values from this on are targets under doors and switches.
const FIRST_TARGET := 0x100
const DIFFICULTIES: Array[GalaxyDifficulty.Level] = [
	GalaxyDifficulty.Level.EASY, GalaxyDifficulty.Level.NORMAL, GalaxyDifficulty.Level.HARD
]
## The class each kind is placed as.
const CLASSES := {
	Keen5Creatures.Kind.SPARKY: "Keen5Sparky",
	Keen5Creatures.Kind.MINE: "Keen5Mine",
	Keen5Creatures.Kind.SLICESTAR_UP: "Keen5Slicestar",
	Keen5Creatures.Kind.SLICESTAR_RIGHT: "Keen5Slicestar",
	Keen5Creatures.Kind.SLICESTAR_DIAGONAL: "Keen5Slicestar",
	Keen5Creatures.Kind.ROBO_RED: "Keen5RoboRed",
	Keen5Creatures.Kind.SPIROGRIP: "Keen5Spirogrip",
	Keen5Creatures.Kind.AMPTON: "Keen5Ampton",
	Keen5Creatures.Kind.TURRET_UP: "Keen5Turret",
	Keen5Creatures.Kind.TURRET_RIGHT: "Keen5Turret",
	Keen5Creatures.Kind.TURRET_DOWN: "Keen5Turret",
	Keen5Creatures.Kind.TURRET_LEFT: "Keen5Turret",
	Keen5Creatures.Kind.VOLTEFACE: "Keen5Volteface",
	Keen5Creatures.Kind.SHELLEY: "Keen5Shelley",
	Keen5Creatures.Kind.SPINDRED: "Keen5Spindred",
	Keen5Creatures.Kind.MASTER: "Keen5Master",
	Keen5Creatures.Kind.SHIKADI: "Keen5Shikadi",
	Keen5Creatures.Kind.SHOCKSHUND: "Keen5Shockshund",
	Keen5Creatures.Kind.SPHEREFUL: "Keen5Sphereful",
	Keen5Creatures.Kind.KORATH: "Keen5Korath",
}
## Map 13 has the 25 Koraths (files).
const KORATH_LEVEL := 13
const KORATHS := 25
const RUN_FRAMES := 600
const FRAME_TICS := 2

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()


func test_every_info_value_is_known() -> void:
	var unknown: Array[String] = []
	var placed := 0
	for number in LEVELS:
		var map := _data.maps.load_map(number)
		for value in map.planes[GalaxyMap.Layer.INFO]:
			if value == 0 or value >= FIRST_TARGET or value in NOT_CREATURES:
				continue
			if value >= FIRST_ITEM and value <= LAST_ITEM:
				continue
			if not Keen5Creatures.entry_of(value).is_empty():
				placed += 1
			elif Keen5Platforms.is_platform(value) or value == Keen5Fuses.COUNTER_INFO:
				continue
			elif not value in Keen5Creatures.LATER and not value in Keen5Creatures.READ_ONLY:
				unknown.append("%d in level %d" % [value, number])
	assert_equal(unknown, [] as Array[String], "every value is placed or planned")
	assert_true(placed > 300, "hundreds of creatures in levels 1-13 (%d)" % placed)


func test_every_creature_value_places_its_class_on_each_difficulty() -> void:
	for number in LEVELS:
		var map := _data.maps.load_map(number)
		for level in DIFFICULTIES:
			var expected := {}
			for value in map.planes[GalaxyMap.Layer.INFO]:
				var entry := Keen5Creatures.entry_of(value)
				if entry.is_empty() or not GalaxyDifficulty.includes(level, entry[1]):
					continue
				var name: String = CLASSES[entry[0]]
				expected[name] = expected.get(name, 0) + 1
			var counted := {}
			for object in _level(number, level).world.objects:
				var name: String = object.get_script().get_global_name()
				if CLASSES.values().has(name):
					counted[name] = counted.get(name, 0) + 1
			assert_equal(counted, expected, "level %d on difficulty %d" % [number, level])


func test_the_koraths_live_on_map_13() -> void:
	var session := _level(KORATH_LEVEL, GalaxyDifficulty.DEFAULT)
	var koraths := session.world.objects.filter(
		func(object: GalaxyObject) -> bool: return object is Keen5Korath
	)
	assert_equal(koraths.size(), KORATHS, "25 Koraths")


func test_every_creature_sprite_is_real() -> void:
	var count := _data.graphics.sprite_infos.size()
	for name in Keen5CreatureSprites.SPRITES:
		var sprite := Keen5CreatureSprites.SPRITES[name]
		assert_true(sprite >= 0 and sprite < count, "%s is a sprite" % name)
		assert_true(_data.graphics.sprite(sprite) != null, "%s is drawn" % name)
	var sprites := Keen5Sprites.all()
	for table in [
		Keen5Sparky.ROWS,
		Keen5Ampton.ROWS,
		Keen5Slicestar.ROWS,
		Keen5Shelley.ROWS,
		Keen5Volteface.ROWS,
		Keen5Mine.ROWS,
		Keen5RoboRed.ROWS,
		Keen5RoboRed.SHOT_ROWS,
		Keen5Spirogrip.ROWS,
		Keen5Spindred.ROWS,
		Keen5Master.ROWS,
		Keen5MasterBall.ROWS,
		Keen5Shikadi.ROWS,
		Keen5PoleSpark.ROWS,
		Keen5Shockshund.ROWS,
		Keen5Shockshund.SHOT_ROWS,
		Keen5Sphereful.ROWS,
		Keen5Korath.ROWS,
		Keen5Turret.ROWS,
		Keen5Turret.LASER_ROWS,
	]:
		var actions := GalaxyAction.table_from(table, sprites)
		assert_equal(actions.size(), table.size(), "every row reads (%s)" % table[0])


func test_every_volteface_finds_its_arrows() -> void:
	for number in LEVELS:
		var session := _level(number, GalaxyDifficulty.Level.HARD)
		for object in session.world.objects:
			var volte := object as Keen5Volteface
			if volte == null:
				continue
			for frame in RUN_FRAMES:
				volte.step = Vector2i.ZERO
				volte.path.advance(volte, Keen5Volteface.SPEED)
				volte.position += volte.step
			assert_true(not volte.path.stuck, "level %d: it keeps to its path" % number)


func test_every_level_runs_with_its_creatures() -> void:
	for number in LEVELS:
		var session := _level(number, GalaxyDifficulty.Level.HARD)
		session.keen.god_mode = true
		for frame in RUN_FRAMES:
			var input := KeenInput.create(
				1 if (frame / 60) % 2 == 0 else -1, frame % 25 == 0, false
			)
			session.run_frame(input, FRAME_TICS, (frame + 1) * FRAME_TICS)
			if not session.is_playing():
				break
		assert_true(not session.is_lost(), "level %d: Keen lives in god mode" % number)
		var creatures := session.world.objects.filter(
			func(object: GalaxyObject) -> bool: return object is Keen5Creature
		)
		assert_true(not creatures.is_empty(), "level %d has creatures" % number)
		assert_equal(session.world.sleep_margin, 6, "objects sleep 6 tiles out")


func _level(number: int, level: GalaxyDifficulty.Level) -> Keen5LevelSession:
	var map := _data.maps.load_map(number)
	return Keen5LevelSession.start_level(
		_data, _rules, map, Keen5Inventory.new_game(), 0, level, number
	)
