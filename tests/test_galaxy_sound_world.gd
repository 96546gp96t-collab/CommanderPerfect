extends "res://tests/test_case.gd"
## Checks that Keen's moves in hand-made mini levels
## (tests/galaxy_keen_fixtures.gd) ask the world for the original's sounds
## (Omni `ck_keen.c`, `ck_misc.c`; facts only): walking, jumping and
## landing, the pogo, hitting a ceiling, shooting with and without
## charges, picking up a drop, points and an extra life, dying; and that
## every name asked for is one of Keen 4's sounds.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const OPEN_SKY: PackedStringArray = [
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"....K.........",
	"##############",
]
const LOW_CEILING: PackedStringArray = [
	"..............",
	"..............",
	"..............",
	"^^^^^^^^^^^^^^",
	"..............",
	"..............",
	"....K.........",
	"##############",
]
const THINGS_TO_TAKE: PackedStringArray = [
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"....K.*$+.X...",
	"##############",
]

var _heard: Array[StringName] = []


func _world(rows: PackedStringArray) -> GalaxyWorld:
	var world := Fixtures.world(rows)
	world.sound_player = func(sound: StringName, _interrupt: bool) -> void: _heard.append(sound)
	_heard.clear()
	return world


func _all_known(description: String) -> void:
	for sound in _heard:
		assert_true(
			Keen4Sounds.NUMBERS.has(sound), "%s: %s is a Keen 4 sound" % [description, sound]
		)


func test_walking_steps() -> void:
	var world := _world(OPEN_SKY)
	Fixtures.run(world, 30, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_true(_heard.has(&"keen_walk_1"), "a step (%s)" % [_heard])
	assert_true(_heard.has(&"keen_walk_2"), "and the other step")
	_all_known("walking")


func test_a_jump_and_its_landing() -> void:
	var world := _world(OPEN_SKY)
	Fixtures.run(world, 60, func(frame: int) -> KeenInput: return Fixtures.press(0, 0, frame < 2))
	assert_true(_heard.has(&"keen_jump"), "the jump (%s)" % [_heard])
	assert_true(_heard.has(&"keen_land"), "the landing")
	assert_true(_heard.find(&"keen_jump") < _heard.find(&"keen_land"), "in that order")
	_all_known("jumping")


func test_the_pogo_bounces() -> void:
	var world := _world(OPEN_SKY)
	Fixtures.run(
		world, 60, func(frame: int) -> KeenInput: return Fixtures.press(0, 0, false, frame == 0)
	)
	assert_true(_heard.count(&"keen_pogo") >= 2, "a sound at every bounce (%s)" % [_heard])
	_all_known("pogo")


func test_hitting_the_ceiling() -> void:
	var world := _world(LOW_CEILING)
	Fixtures.run(world, 40, func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, true))
	assert_true(_heard.has(&"keen_hit_ceiling"), "the head hits the ceiling (%s)" % [_heard])


func test_shooting_with_and_without_charges() -> void:
	var world := _world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	var fire := func(frame: int) -> KeenInput: return KeenInput.create(0, false, false, frame == 0)
	Fixtures.run(world, 20, fire)
	assert_true(_heard.has(&"keen_shoot"), "a charge fires (%s)" % [_heard])
	keen.inventory.shots = 0
	_heard.clear()
	Fixtures.run(world, 20, fire)
	assert_true(_heard.has(&"keen_out_of_ammo"), "no charge: the click (%s)" % [_heard])
	assert_true(not _heard.has(&"keen_shoot"), "and no shot")
	_all_known("shooting")


func test_taking_things_and_dying() -> void:
	var world := _world(THINGS_TO_TAKE)
	var keen := world.player() as GalaxyKeen
	keen.inventory.score = keen.inventory.next_life_at - 50
	Fixtures.run(world, 80, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_true(_heard.has(&"got_drop"), "the drop (%s)" % [_heard])
	assert_true(_heard.has(&"got_item"), "the points")
	assert_true(_heard.has(&"got_extra_life"), "the extra life")
	assert_true(_heard.has(&"keen_die"), "the deadly tile")
	_all_known("taking")
