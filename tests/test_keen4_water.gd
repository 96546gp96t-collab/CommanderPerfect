extends "res://tests/test_case.gd"
## Checks Keen 4's Well of Wishes in a hand-made mini level (milestone D6):
## the swimming Keen (sinking, the stick, the kick, bubbles, walls), the
## Dopefish that eats him and the school fish, the school fish that follow
## him, the sprites that aim and shoot, the mines and the council member
## under water (Omni numbers; seen in the original: the sinking;
## docs/keen4/research.md §5, §7).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
## Open water, a wall at the far right.
const WATER: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
]
const SWIM_START := Vector2i(6, 3)
const KICK := Keen4SwimmingKeen.KICK


func test_he_sinks_slowly_with_nothing_held() -> void:
	var world := _water()
	var keen := world.player() as Keen4SwimmingKeen
	assert_equal(keen.clip, GalaxyObject.Clip.SIMPLE, "the simple box clip")
	assert_equal(keen.priority, 1, "priority 1")
	_swim(world, 8, KeenInput.new())
	var y := keen.position.y
	var speeds := {}
	for frame in 32:
		_swim(world, 1, KeenInput.new())
		speeds[keen.velocity.y] = true
	var per_tic := float(keen.position.y - y) / (32 * GalaxyClock.NORMAL_TICS)
	assert_true(per_tic >= 4.0 and per_tic <= 5.0, "4 and 5 by turns (%s a tic)" % per_tic)
	assert_true(speeds.has(4) and speeds.has(5), "the two speeds")


func test_the_stick_and_the_kick() -> void:
	var world := _water()
	var keen := world.player() as Keen4SwimmingKeen
	var right := Fixtures.press(1)
	_swim(world, 40, right)
	assert_true(keen.velocity.x >= 12 and keen.velocity.x <= 13, "holding right: about 12")
	assert_equal(keen.direction.x, 1, "facing right")
	var calm := _water()
	var swimmer := calm.player() as Keen4SwimmingKeen
	_swim(calm, 1, KeenInput.new())
	var frame_action := swimmer.action.name
	_swim(calm, 1, Fixtures.press(-1, -1, true))
	assert_true(swimmer.velocity.x <= -16, "a kick left: 18 (%d)" % swimmer.velocity.x)
	assert_true(swimmer.velocity.y <= -16, "and up (%d)" % swimmer.velocity.y)
	assert_true(swimmer.action.name != frame_action, "the kick shows the next picture")
	swimmer.velocity = Vector2i.ZERO
	_swim(calm, 1, Fixtures.press(-1, -1, true))
	assert_true(swimmer.velocity.x > -KICK, "holding jump kicks only once")


func test_letting_go_eases_off() -> void:
	var world := _water()
	var keen := world.player() as Keen4SwimmingKeen
	keen.position.y = 10 * TILE
	_swim(world, 80, Fixtures.press(0, -1))
	assert_true(keen.velocity.y <= -11, "swimming up at about 12 (%d)" % keen.velocity.y)
	var rising := keen.velocity.y
	_swim(world, 8, KeenInput.new())
	var eased := keen.velocity.y - rising
	assert_true(eased >= 2 and eased <= 4, "let go: 3 or 1 less every 8 tics (%d)" % eased)
	var sideways := _water()
	var swimmer := sideways.player() as Keen4SwimmingKeen
	_swim(sideways, 40, Fixtures.press(-1))
	_swim(sideways, 80, KeenInput.new())
	assert_true(swimmer.velocity.x >= 0 and swimmer.velocity.x <= 1, "sideways he comes to rest")


func test_bubbles_and_walls() -> void:
	var world := _water()
	var keen := world.player() as Keen4SwimmingKeen
	_swim(world, 40, KeenInput.new())
	var bubbles := Creatures.count(world, Keen4Bubble)
	assert_true(bubbles >= 1, "a bubble every 60 tics (%d)" % bubbles)
	var bubble := Creatures.first(world, Keen4Bubble) as Keen4Bubble
	var y := bubble.position.y
	_swim(world, 1, KeenInput.new())
	assert_true(bubble.position.y < y, "it rises")
	keen.position.x = 28 * TILE
	_swim(world, 40, Fixtures.press(1))
	assert_true(keen.box.right < (30 + 2) * TILE + 1, "the wall stops him")
	assert_true(keen.velocity.x <= 3, "and his speed sideways")


func test_the_dopefish_eats_keen() -> void:
	var world := _water(15, [Vector2i(16, 8)])
	var fish := Creatures.first(world, Keen4Dopefish) as Keen4Dopefish
	assert_true(fish != null, "info 15 places the Dopefish")
	assert_equal(fish.position.y, 10 * TILE - 0x300, "three tiles up (Omni)")
	assert_equal(fish.priority, 2, "priority 2")
	var keen := world.player() as Keen4SwimmingKeen
	for frame in 300:
		_swim(world, 1, KeenInput.new())
		if keen.eaten:
			break
	assert_true(keen.eaten, "it swims to him and catches him")
	assert_equal(fish.action.name, &"eat", "eating")
	for frame in 60:
		_swim(world, 1, KeenInput.new())
		if fish.action.name != &"eat":
			break
	assert_equal(fish.action.name, &"burp_1", "swallowed: it rests, then burps")
	assert_equal(keen.sprite, GalaxyObject.NO_SPRITE, "Keen is gone")
	_swim(world, 80, KeenInput.new())
	assert_true(Creatures.count(world, Keen4Bubble) >= 1, "a burp bubble")
	_swim(world, 20, KeenInput.new())
	assert_equal(world.state, GalaxyWorld.LevelState.DIED, "180 tics later the level is lost")


func test_god_mode_keeps_him_out_of_its_mouth() -> void:
	var world := _water(15, [Vector2i(16, 8)])
	var keen := world.player() as Keen4SwimmingKeen
	keen.god_mode = true
	_swim(world, 300, KeenInput.new())
	assert_true(not keen.eaten, "in god mode it does not eat him")


func test_the_dopefish_eats_school_fish() -> void:
	var world := _water(16, [Vector2i(14, 3)])
	Creatures.place_more(world, 15, Vector2i(16, 6))
	var school := Creatures.first(world, Keen4Schoolfish) as Keen4Schoolfish
	var dopefish := Creatures.first(world, Keen4Dopefish) as Keen4Dopefish
	assert_true(school != dopefish and school != null, "a school fish")
	var keen := world.player() as Keen4SwimmingKeen
	keen.god_mode = true
	school.position = dopefish.position + Vector2i(0x200, 0x200)
	_swim(world, 1, KeenInput.new())
	assert_true(school.is_caught() or school.removed, "caught")
	_swim(world, 40, KeenInput.new())
	assert_true(not world.objects.has(school), "and eaten")


func test_school_fish_follow_keen() -> void:
	var world := _water(16, [Vector2i(16, 8)])
	var fish := Creatures.first(world, Keen4Schoolfish) as Keen4Schoolfish
	assert_equal(fish.simple_box_size, Vector2i(0x100, 0x80), "its box (Omni)")
	var keen := world.player() as Keen4SwimmingKeen
	var distance := (fish.position - keen.position).length()
	_swim(world, 60, KeenInput.new())
	assert_true((fish.position - keen.position).length() < distance, "it comes closer")
	assert_true(absi(fish.velocity.x) <= 10 and absi(fish.velocity.y) <= 10, "at most 10")


func test_a_sprite_aims_and_shoots() -> void:
	var world := _water(17, [Vector2i(16, 3)])
	var sprite := Creatures.first(world, Keen4WaterSprite) as Keen4WaterSprite
	var keen := world.player() as Keen4SwimmingKeen
	keen.god_mode = true
	keen.position.y = sprite.position.y
	keen.reset_box()
	var seen := {}
	var shot: GalaxyEnemyShot = null
	for frame in 80:
		_swim(world, 1, KeenInput.new())
		keen.position.y = sprite.position.y
		keen.velocity = Vector2i.ZERO
		seen[sprite.action.name] = true
		if shot == null:
			shot = Creatures.first(world, GalaxyEnemyShot) as GalaxyEnemyShot
	assert_true(seen.has(&"aim") and seen.has(&"shoot_1"), "it aims, then shoots")
	assert_true(shot != null, "a shot")
	if shot != null:
		assert_equal(shot.direction.x, -1, "towards Keen")


func test_a_sprite_bobs_without_keen_level() -> void:
	var world := _water(23, [Vector2i(16, 10)])
	var sprite := Creatures.first(world, Keen4WaterSprite) as Keen4WaterSprite
	assert_true(sprite != null, "info 23 places a sprite from Normal on")
	var top := sprite.position.y
	var bottom := sprite.position.y
	for frame in 60:
		_swim(world, 1, KeenInput.new())
		top = mini(top, sprite.position.y)
		bottom = maxi(bottom, sprite.position.y)
	assert_true(bottom - top > 32, "it bobs")
	assert_equal(sprite.action.name, &"patrol", "Keen is not level with it")


func test_a_mine_kills_the_swimmer() -> void:
	var world := _water(71, [Vector2i(6, 1)])
	var mine := Creatures.first(world, Keen4Mine) as Keen4Mine
	assert_equal(mine.direction, Vector2i.DOWN, "info 71 goes down")
	var keen := world.player() as Keen4SwimmingKeen
	keen.position = mine.position
	keen.reset_box()
	_swim(world, 1, KeenInput.new())
	assert_true(keen.is_dying(), "the mine kills him")
	var suits := [Keen4Sprites.KEEN[&"SUIT_DIE_1"], Keen4Sprites.KEEN[&"SUIT_DIE_2"]]
	assert_true(keen.sprite in suits, "dying in his suit")


func test_rescuing_under_water() -> void:
	var world := _water(4, [Vector2i(8, 3)])
	var member := Creatures.first(world, Keen4Council) as Keen4Council
	var keen := world.player() as Keen4SwimmingKeen
	keen.position = member.position
	keen.reset_box()
	_swim(world, 1, KeenInput.new())
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "touching him rescues him")
	assert_equal(world.ending, Keen4Council.RESCUED, "a rescue")


## A world of open water with the swimming Keen and [param info] at
## [param cells].
func _water(info := 0, cells: Array[Vector2i] = []) -> GalaxyWorld:
	var map := Fixtures.level(WATER)
	var world := GalaxyWorld.create(map, Fixtures.tile_info(), Fixtures.sprite_infos())
	world.camera = Fixtures.camera_for(map)
	world.random_table = Creatures.random_table()
	world.map_number = Keen4Messages.UNDER_WATER_LEVEL
	var keen := Keen4SwimmingKeen.spawn(world, SWIM_START + Vector2i(2, 2), Keen4Sprites.all())
	keen.inventory = Keen4Inventory.new_game()
	Creatures.give_boxes(world)
	for cell in cells:
		Fixtures.put_info(map, cell, info)
	Keen4Creatures.place_all(world, GalaxyDifficulty.Level.HARD, Keen4Sprites.all())
	return world


## Runs [param frames] frames (2 tics each) with [param held].
static func _swim(world: GalaxyWorld, frames: int, held: KeenInput) -> void:
	var keen := world.player() as GalaxyKeenBody
	for frame in frames:
		world.tics = GalaxyClock.NORMAL_TICS
		keen.begin_frame(held)
		world.run_frame(GalaxyClock.NORMAL_TICS, world.tic + GalaxyClock.NORMAL_TICS)
