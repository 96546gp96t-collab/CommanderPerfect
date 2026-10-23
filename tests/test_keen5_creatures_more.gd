extends "res://tests/test_case.gd"
## Checks the rest of Keen 5's creatures in hand-made mini levels
## (milestone E4; [Keen5Mine], [Keen5RoboRed], [Keen5Spirogrip],
## [Keen5Spindred], [Keen5Master], [Keen5Shikadi], [Keen5Shockshund],
## [Keen5Sphereful], [Keen5Turret]; Omni `ck5_obj3.c`, `ck_obj.c`;
## docs/keen5/research.md §7): speeds, timers, hit points and flashes,
## what kills Keen, the shots and what stops them, the mine's pieces, the
## Sphereful's diamonds, and the turrets' lasers that live only near the
## screen. No game files are needed.

const Fixtures := preload("res://tests/keen5_creature_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
## Info values (Omni).
const MINE := 7
const ROBO_RED := 13
const SPIROGRIP := 16
const SPINDRED := 77
const MASTER := 88
const SHIKADI := 99
const SHOCKSHUND := 102
const SPHEREFUL := 105
const TURRET_RIGHT := 46
const TURRET_UP_HARD := 53
## A room 14 tiles high (Robo Red is 5 tall) with Keen far right.
const ROOM: PackedStringArray = [
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
	"............................K.",
	"##############################",
]
## A corridor four tiles high: no 5 × 5 tiles anywhere are free.
const CORRIDOR: PackedStringArray = [
	"##############################",
	"##############################",
	"##############################",
	"##############################",
	"##############################",
	"##############################",
	"##############################",
	"..............................",
	"..............................",
	"..............................",
	"............................K.",
	"##############################",
]


func test_a_mine_floats_10_a_tic_towards_keen() -> void:
	var world := Fixtures.world(ROOM, MINE, [Vector2i(4, 6)] as Array[Vector2i])
	var mine := Fixtures.first(world, Keen5Mine) as Keen5Mine
	assert_equal(mine.clip, GalaxyObject.Clip.NONE, "unclipped")
	Fixtures.wait(world, 1)
	assert_equal(mine.overlays.size(), 1, "its eye is drawn with it")
	var floating := Fixtures.run_until(
		world, func() -> bool: return mine.action.name == &"float", 100
	)
	assert_true(floating < 100, "the eye in place, it floats")
	var at := mine.position
	Fixtures.wait(world, 1)
	assert_equal((mine.position - at).length(), 20.0, "10 units a tic")
	var start_gap := absi(Fixtures.keen(world).position.x - at.x)
	Fixtures.wait(world, 200)
	var gap := absi(Fixtures.keen(world).position.x - mine.position.x)
	assert_true(gap < start_gap, "it comes nearer to Keen")


func test_a_mine_explodes_near_keen_into_six_pieces() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, MINE, [Vector2i(22, 8)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var mine := Fixtures.first(world, Keen5Mine) as Keen5Mine
	var keen := Fixtures.keen(world)
	keen.god_mode = true
	var pulsing := Fixtures.run_until(
		world, func() -> bool: return mine.action.name.begins_with("pulse"), 200
	)
	assert_true(pulsing < 200, "Keen near: it pulses")
	assert_true(sounds.has(&"mine_explode"), "with its sound")
	assert_true(mine.overlays.is_empty(), "the eye is gone")
	Fixtures.wait(world, 21)
	assert_equal(Fixtures.count(world, Keen5Piece), 6, "six pieces")
	assert_true(mine.action.name.begins_with("blast"), "then its blast")
	assert_equal(mine.action.contact, &"_contact_deadly", "the blast kills")


func test_a_mine_itself_is_harmless_and_absorbs_shots() -> void:
	var world := Fixtures.world(ROOM, MINE, [Vector2i(4, 6)] as Array[Vector2i])
	var mine := Fixtures.first(world, Keen5Mine) as Keen5Mine
	var keen := Fixtures.keen(world)
	mine._contact_mine(keen)
	assert_true(not keen.is_dying(), "touching the mine does nothing")
	var keep := []
	var shot := Fixtures.shoot(world, mine, keep)
	Fixtures.wait(world, 2)
	assert_true(shot.spent, "a shot stops at it")
	assert_true(not mine.action.name.begins_with("pulse"), "and it stays")


func test_a_mine_piece_reports_what_it_touches() -> void:
	var world := Fixtures.world(ROOM, 0, [] as Array[Vector2i])
	var piece := Keen5Piece.throw(
		world,
		Vector2i(5 * TILE, 5 * TILE),
		Vector2i.ZERO,
		Keen5Mine.ROWS,
		Keen5Sprites.all(),
		&"piece"
	)
	var target := Toucher.new()
	piece._contact_piece(target)
	assert_equal(target.touched, 0, "a Shelley's piece tells nothing")
	piece.reports_touches = true
	piece._contact_piece(target)
	assert_equal(target.touched, 1, "a mine's piece tells what it touches (the QED in E5)")


func test_robo_red_fires_ten_shots_when_shot() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, ROBO_RED, [Vector2i(6, 10)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var robo := Fixtures.first(world, Keen5RoboRed) as Keen5RoboRed
	assert_equal(robo.box.bottom, 13 * TILE - 1, "it stands on the floor")
	var keep := []
	var stunner := Fixtures.shoot(world, robo, keep)
	Fixtures.wait(world, 2)
	assert_true(stunner.spent, "the shot is absorbed")
	assert_true(not robo.stunned, "it cannot be stunned")
	assert_equal(robo.action.name, &"aim", "it answers")
	assert_equal(robo.direction.x, 1, "facing Keen")
	var shots := 0
	var speeds: Array[Vector2i] = []
	for frame in 150:
		var before := Fixtures.count(world, Keen5Shot)
		Fixtures.wait(world, 1)
		if Fixtures.count(world, Keen5Shot) > before:
			shots += 1
			var shot := _newest(world, Keen5Shot) as Keen5Shot
			speeds.append(shot.velocity)
		if robo.action.name == &"walk":
			break
	assert_equal(shots, 10, "ten shots, then it walks on")
	assert_equal(speeds[0], Vector2i(60, -8), "60 sideways, 8 up ...")
	assert_equal(speeds[1], Vector2i(60, 8), "... then 8 down")
	assert_true(sounds.has(&"enemy_shoot"), "each with its sound")


func test_robo_reds_shot_kills_keen() -> void:
	var world := Fixtures.world(ROOM, 0, [] as Array[Vector2i])
	var keen := Fixtures.keen(world)
	var shot := Keen5Shot.launch(
		world,
		keen.position + Vector2i(-300, 64),
		Vector2i(60, 0),
		Keen5RoboRed.SHOT_ROWS,
		Keen5Sprites.all(),
		&"fly_1"
	)
	Fixtures.wait(world, 4)
	assert_true(keen.is_dying(), "the shot kills Keen")
	assert_true(shot.action.name.begins_with("hit"), "and shows where")


func test_a_spirogrip_clings_150_tics_then_spins_and_flies() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, SPIROGRIP, [Vector2i(10, 10)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var grip := Fixtures.first(world, Keen5Spirogrip) as Keen5Spirogrip
	assert_equal(grip.action.name, &"cling_down", "clinging")
	var let_go := Fixtures.run_until(
		world, func() -> bool: return grip.action.name == &"let_go_down", 100
	)
	assert_equal(let_go, 75, "150 tics")
	var y := grip.position.y
	Fixtures.wait(world, 1)
	assert_equal(grip.position.y - y, -32, "lets go 16 a tic")
	var flying := Fixtures.run_until(
		world, func() -> bool: return grip.action.name.begins_with("fly"), 2000
	)
	assert_true(flying < 2000, "it flies off")
	assert_true(sounds.has(&"spiro_fly"), "with its sound")
	var clings := Fixtures.run_until(
		world, func() -> bool: return grip.action.name.begins_with("cling"), 200
	)
	assert_true(clings < 200, "it clings to the next wall")
	assert_true(sounds.has(&"spiro_slam"), "with a slam")


func test_a_spirogrip_absorbs_shots() -> void:
	var world := Fixtures.world(ROOM, SPIROGRIP, [Vector2i(10, 10)] as Array[Vector2i])
	var grip := Fixtures.first(world, Keen5Spirogrip) as Keen5Spirogrip
	var keep := []
	var shot := Fixtures.shoot(world, grip, keep)
	Fixtures.wait(world, 2)
	assert_true(shot.spent, "the shot stops")
	assert_true(not grip.stunned, "it is not stunned")


func test_a_spindred_bounces_and_turns_every_third_time() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, SPINDRED, [Vector2i(10, 6)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var spindred := Fixtures.first(world, Keen5Spindred) as Keen5Spindred
	var fastest := 0
	for frame in 400:
		Fixtures.wait(world, 1)
		fastest = maxi(fastest, absi(spindred.velocity.y))
	assert_true(fastest <= 70, "at most 70 a tic")
	assert_true(sounds.has(&"spindred_slam"), "it slams the floor")
	assert_true(sounds.has(&"spindred_fly_up"), "the third time it flies up")
	assert_true(sounds.has(&"spindred_fly_down"), "and back down")


func test_a_shikadi_master_throws_when_shot_and_the_ball_becomes_sparks() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, MASTER, [Vector2i(6, 10)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var master := Fixtures.first(world, Keen5Master) as Keen5Master
	Fixtures.keen(world).god_mode = true
	var keep := []
	var stunner := Fixtures.shoot(world, master, keep)
	Fixtures.wait(world, 2)
	assert_true(stunner.spent and not master.stunned, "absorbed, not stunned")
	assert_equal(master.action.name, &"cast_1", "it throws at once")
	assert_equal(master.direction.x, 1, "facing right (Keen's x is not its own)")
	var thrown := Fixtures.run_until(
		world, func() -> bool: return Fixtures.count(world, Keen5MasterBall) > 0, 30
	)
	assert_true(thrown < 30, "a ball")
	var ball := Fixtures.first(world, Keen5MasterBall) as Keen5MasterBall
	assert_equal(ball.velocity.x, 48, "48 sideways (and from 16 up, gravity mid)")
	var sparks := Fixtures.run_until(
		world, func() -> bool: return ball.action.name.begins_with("sparks"), 100
	)
	assert_true(sparks < 100, "on the floor it turns into sparks")
	assert_equal(Fixtures.count(world, Keen5MasterBall), 2, "two of them")


func test_a_shikadi_master_teleports_near_keen() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, MASTER, [Vector2i(3, 10)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var master := Fixtures.first(world, Keen5Master) as Keen5Master
	Fixtures.keen(world).god_mode = true
	master.teleports_next = true
	var start := master.position
	var gone := Fixtures.run_until(
		world, func() -> bool: return sounds.has(&"master_teleport"), 300
	)
	assert_true(gone < 300, "it teleports")
	assert_true(master.position != start, "elsewhere")
	var keen := Fixtures.keen(world)
	var tile := Vector2i(
		GalaxyUnits.to_tile(master.position.x), GalaxyUnits.to_tile(master.position.y)
	)
	assert_true(absi(tile.x - keen.box.tile_middle) <= 16, "near Keen's column")
	var stands := Fixtures.run_until(
		world, func() -> bool: return master.action.name == &"appear", 200
	)
	assert_true(stands < 200, "it lands and stands")


func test_a_shikadi_master_acts_only_below_64() -> void:
	var world := Fixtures.world(ROOM, MASTER, [Vector2i(3, 10)] as Array[Vector2i])
	var master := Fixtures.first(world, Keen5Master) as Keen5Master
	Fixtures.keen(world).god_mode = true
	world.random_table = PackedByteArray([Keen5Master.ACT_CHANCE])
	var acted := Fixtures.run_until(
		world, func() -> bool: return master.action.name == &"cast_1", 300
	)
	assert_equal(acted, 300, "64 or more: it stands on (seen in E12)")
	world.random_table = PackedByteArray([Keen5Master.ACT_CHANCE - 1])
	acted = Fixtures.run_until(world, func() -> bool: return master.action.name == &"cast_1", 40)
	assert_true(acted < 40, "below 64: it throws after the round")


func test_a_shikadi_master_without_room_stays_where_it_stood() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		CORRIDOR, MASTER, [Vector2i(3, 10)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var master := Fixtures.first(world, Keen5Master) as Keen5Master
	Fixtures.keen(world).god_mode = true
	master.teleports_next = true
	world.random_table = PackedByteArray([Keen5Master.ACT_CHANCE - 1])
	var start := master.position
	var gone := Fixtures.run_until(
		world, func() -> bool: return sounds.has(&"master_teleport"), 300
	)
	assert_true(gone < 300, "it tries to teleport")
	Fixtures.wait(world, 1)
	assert_equal(master.position, start, "every spot holds a wall: it stays (seen in E12)")
	assert_equal(master.action.name, &"stand_1", "and stands at once")


func test_a_shikadi_takes_four_shots_flashing_white() -> void:
	var world := Fixtures.world(ROOM, SHIKADI, [Vector2i(6, 10)] as Array[Vector2i])
	var shikadi := Fixtures.first(world, Keen5Shikadi) as Keen5Shikadi
	var keep := []
	for hit in 3:
		Fixtures.shoot(world, shikadi, keep)
		Fixtures.run_until(world, func() -> bool: return shikadi.flash_white, 4)
		assert_true(shikadi.flash_white, "shot %d: it flashes white" % (hit + 1))
		# Two drawings: it is drawn when it moves or changes its picture.
		Fixtures.wait(world, 10)
		assert_true(not shikadi.flash_white, "for two drawings")
		assert_true(not shikadi.stunned, "not stunned yet")
	Fixtures.shoot(world, shikadi, keep)
	Fixtures.wait(world, 3)
	assert_true(shikadi.stunned, "the fourth shot stuns it")
	assert_true(not shikadi.flash_white, "drawn plainly")


func test_a_shikadi_zaps_the_pole_keen_is_on() -> void:
	var rows := ROOM.duplicate()
	for row in range(3, 11):
		rows[row] = rows[row].substr(0, 20) + "|" + rows[row].substr(21)
	rows[10] = "....................P........."
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		rows, SHIKADI, [Vector2i(14, 10)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var keen := Fixtures.keen(world)
	keen.god_mode = true
	Keen.run(world, 1, func(_frame: int) -> KeenInput: return Keen.press(0, -1))
	assert_true(keen.action.name.begins_with("pole"), "Keen on the pole")
	Keen.run(world, 20, func(_frame: int) -> KeenInput: return Keen.press(0, -1))
	var zapped := Fixtures.run_until(
		world, func() -> bool: return Fixtures.count(world, Keen5PoleSpark) > 0, 400
	)
	assert_true(zapped < 400, "it zaps the pole")
	assert_true(sounds.has(&"pole_zap"), "with its sound")
	var spark := Fixtures.first(world, Keen5PoleSpark) as Keen5PoleSpark
	assert_equal(spark.direction.y, -1, "the spark runs up towards Keen")
	var y := spark.position.y
	Fixtures.wait(world, 1)
	assert_equal(spark.position.y - y, -48, "48 units a frame")


func test_a_shockshund_takes_two_shots_and_barks_a_shot_the_stunner_stops() -> void:
	var world := Fixtures.world(ROOM, SHOCKSHUND, [Vector2i(6, 10)] as Array[Vector2i])
	var dog := Fixtures.first(world, Keen5Shockshund) as Keen5Shockshund
	var keep := []
	Fixtures.shoot(world, dog, keep)
	Fixtures.run_until(world, func() -> bool: return dog.flash_white, 4)
	assert_true(dog.flash_white and not dog.stunned, "the first shot flashes it")
	Fixtures.wait(world, 4)
	Fixtures.shoot(world, dog, keep)
	Fixtures.wait(world, 3)
	assert_true(dog.stunned, "the second stuns it")
	world = Fixtures.world(ROOM, SHOCKSHUND, [Vector2i(6, 10)] as Array[Vector2i])
	Fixtures.keen(world).god_mode = true
	var barked := Fixtures.run_until(
		world, func() -> bool: return Fixtures.count(world, Keen5Shot) > 0, 600
	)
	assert_true(barked < 600, "it barks a shot")
	var shot := Fixtures.first(world, Keen5Shot) as Keen5Shot
	assert_equal(absi(shot.velocity.x), 60, "60 sideways")
	assert_true(shot.meets_stunner, "a stunner shot stops it")
	# Away from the dog, standing still, so the stunner shot meets it.
	shot.velocity = Vector2i.ZERO
	shot.position.y -= 4 * TILE
	shot.reset_box()
	var stunner := Fixtures.shoot(world, shot, keep)
	Fixtures.wait(world, 3)
	assert_true(stunner.spent and shot.action.name.begins_with("hit"), "both stop")


func test_a_shockshund_sits_now_and_then() -> void:
	var world := Fixtures.world(ROOM, SHOCKSHUND, [Vector2i(6, 10)] as Array[Vector2i])
	var dog := Fixtures.first(world, Keen5Shockshund) as Keen5Shockshund
	Fixtures.keen(world).god_mode = true
	var sits := Fixtures.run_until(world, func() -> bool: return dog.action.name == &"sit_1", 3000)
	assert_true(sits < 3000, "it sits")
	var runs := Fixtures.run_until(world, func() -> bool: return dog.action.name == &"run_1", 200)
	assert_equal(runs, 128, "16 rounds of 16 tics")


func test_a_sphereful_drifts_towards_keen_with_four_diamonds() -> void:
	var world := Fixtures.world(ROOM, SPHEREFUL, [Vector2i(6, 4)] as Array[Vector2i])
	var sphereful := Fixtures.first(world, Keen5Sphereful) as Keen5Sphereful
	Fixtures.keen(world).god_mode = true
	assert_equal(sphereful.clip, GalaxyObject.Clip.SIMPLE, "box-clipped")
	var start_x := sphereful.position.x
	Fixtures.wait(world, 300)
	assert_true(sphereful.position.x > start_x, "it drifts towards Keen")
	assert_true(absi(sphereful.velocity.x) <= 8 and absi(sphereful.velocity.y) <= 12, "slowly")
	assert_equal(sphereful.overlays.size(), 4, "four diamonds")
	var priorities: Dictionary[int, bool] = {}
	for frame in 64:
		Fixtures.wait(world, 1)
		for diamond in sphereful.overlays:
			priorities[diamond.priority] = true
	assert_equal(priorities.size(), 2, "in front and behind, by turns")


func test_a_turret_fires_every_120_tics_and_its_laser_lives_only_near_the_screen() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		ROOM, TURRET_RIGHT, [Vector2i(16, 5)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var turret := Fixtures.first(world, Keen5Turret) as Keen5Turret
	assert_true(turret.hidden, "never seen")
	var fired := Fixtures.run_until(
		world, func() -> bool: return Fixtures.count(world, Keen5Shot) > 0, 100
	)
	assert_equal(fired, 60, "after 120 tics (the first frame is 3)")
	assert_true(sounds.has(&"enemy_shoot"), "with its sound")
	var laser := Fixtures.first(world, Keen5Shot) as Keen5Shot
	assert_equal(laser.velocity, Vector2i(64, 0), "64 a tic, right")
	assert_equal(laser.activity, GalaxyObject.Activity.ON_SCREEN_ONLY, "only near the screen")
	var keep := []
	var stunner := Fixtures.shoot(world, laser, keep)
	Fixtures.wait(world, 1)
	assert_true(not stunner.spent, "a stunner shot passes it")
	var hit := Fixtures.run_until(world, func() -> bool: return laser.action.name == &"hit_1", 60)
	assert_true(hit < 60, "it stops at the wall")
	assert_true(sounds.has(&"enemy_shot_hit"), "with its sound")


func test_turrets_by_difficulty() -> void:
	for level in [GalaxyDifficulty.Level.NORMAL, GalaxyDifficulty.Level.HARD]:
		var world := Fixtures.world(
			ROOM, TURRET_UP_HARD, [Vector2i(2, 9)] as Array[Vector2i], level
		)
		var expected := 1 if level == GalaxyDifficulty.Level.HARD else 0
		assert_equal(Fixtures.count(world, Keen5Turret), expected, "info 53 on Hard only")


## The object of [param type] placed last.
func _newest(world: GalaxyWorld, type: Script) -> GalaxyObject:
	var found: GalaxyObject = null
	for object in world.objects:
		if is_instance_of(object, type) and not object.removed:
			found = object
	return found


## Something a mine's piece may touch (E5's QED will be one).
class Toucher:
	extends GalaxyObject
	var touched := 0

	func hit_by_piece(_piece: GalaxyObject) -> void:
		touched += 1
