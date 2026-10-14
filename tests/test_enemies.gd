extends "res://tests/test_case.gd"
## Tests for the enemies: how they move, what Keen's shots do to them and
## what they do to Keen. In small hand-made levels (no game data needed).

const Fixtures := preload("res://tests/fixtures.gd")
const SETTLE_TICKS := 120

## Keen starts on the left, standing on the floor in row 14.
const FIELD: PackedStringArray = [
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
	"..............................",
	"..............................",
	"##############################",
]
const KEEN_CELL := Vector2i(2, 12)
const FLOOR_ROW := 14


func test_enemies_start_from_the_info_layer() -> void:
	var level := Fixtures.create_level(FIELD)
	var infos := {
		Vector2i(10, 2): LevelSession.INFO_YORP,
		Vector2i(12, 2): LevelSession.INFO_GARG,
		Vector2i(14, 2): LevelSession.INFO_VORTICON,
		Vector2i(16, 2): LevelSession.INFO_BUTLER,
		Vector2i(18, 2): LevelSession.INFO_TANK,
		Vector2i(20, 2): 7,
		Vector2i(22, 2): LevelSession.INFO_CHAIN,
	}
	for cell: Vector2i in infos:
		level.infos[cell.y * level.width + cell.x] = infos[cell]
	var session := LevelSession.create(
		level, Fixtures.create_properties(), Inventory.new(), _keen_start()
	)
	var kinds: Array[Script] = []
	for enemy in session.enemies():
		kinds.append(enemy.get_script())
	assert_equal(
		kinds,
		[Yorp, Garg, Vorticon, ButlerRobot, TankRobot, IceCannon, StoneChain] as Array[Script],
		"one of each, in order"
	)
	assert_equal(session.enemies()[0].position, Vector2(10, 2) * EgaGraphics.TILE_SIZE, "at cell")


func test_enemies_wait_until_keen_is_near() -> void:
	var session := _session(FIELD)
	var garg := _add(session, Garg.create(_on_floor(Garg.BODY_BOX, 29)))
	var start := garg.position
	_run(session, KeenInput.create(0), 30)
	assert_equal(garg.position, start, "still asleep")
	_run(session, KeenInput.create(1), 180)
	assert_true(garg.is_active, "woke up when Keen came near")


func test_enemies_wake_up_when_they_come_into_view() -> void:
	var session := _session(FIELD)
	var garg := _add(session, Garg.create(_on_floor(Garg.BODY_BOX, 25)))
	session.view_rect = Rect2(_column_left(0), _row_top(0), 320, 200)
	_run(session, KeenInput.create(0), 5)
	assert_true(not garg.is_active, "out of view")
	session.view_rect.size.x = 426
	_run(session, KeenInput.create(0), 1)
	assert_true(garg.is_active, "in view on a wider screen")


func test_enemies_start_on_the_floor() -> void:
	var level := Fixtures.create_level(FIELD)
	var cell := Vector2i(10, FLOOR_ROW - 2) + _border()
	level.infos[cell.y * level.width + cell.x] = LevelSession.INFO_YORP
	var session := LevelSession.create(
		level, Fixtures.create_properties(), Inventory.new(), _keen_start()
	)
	var yorp := session.enemies()[0]
	assert_equal(yorp.hitbox().end.y, _row_top(FLOOR_ROW), "on the floor, not above it")
	assert_true(not yorp.is_active, "still asleep")


func test_one_shot_kills_a_yorp() -> void:
	var session := _session(FIELD)
	session.inventory.charges = 1
	var yorp := _add(session, Yorp.create(_on_floor(Yorp.BODY_BOX, 8)))
	yorp.is_active = true
	_run(session, KeenInput.create(0, false, false, true), 1)
	_run(session, KeenInput.create(0), 60)
	assert_true(yorp.is_dead, "dead")
	assert_equal(yorp.sprite_index(), Yorp.SPRITE_DEAD, "corpse")


func test_vorticon_takes_several_shots() -> void:
	var session := _session(FIELD)
	var vorticon := _add(session, Vorticon.create(_on_floor(Vorticon.BODY_BOX, 9)))
	for shot in Vorticon.HEALTH - 1:
		vorticon.hit_by_shot(session)
	assert_true(not vorticon.is_dead, "still alive")
	vorticon.hit_by_shot(session)
	assert_true(vorticon.is_dead, "dead after the last shot")


func test_garg_kills_keen() -> void:
	var session := _session(FIELD)
	var garg := _add(session, Garg.create(_on_floor(Garg.BODY_BOX, 4)))
	garg.is_active = true
	_run(session, KeenInput.create(1), 30)
	assert_true(session.keen.is_dead, "dead")


func test_garg_charges_at_keen() -> void:
	var session := _session(FIELD)
	var garg := _add(session, Garg.create(_on_floor(Garg.BODY_BOX, 20)))
	garg.is_active = true
	var look_ticks := Garg.LOOK_ROUNDS * Garg.LOOK_FRAMES * Garg.LOOK_FRAME_TICKS
	_run(session, KeenInput.create(0), look_ticks + 1)
	assert_equal(garg.mode, Garg.Mode.CHARGING, "charges")
	assert_equal(garg.facing, -1, "towards Keen")


func test_corpses_are_harmless() -> void:
	var session := _session(FIELD)
	var garg := _add(session, Garg.create(_on_floor(Garg.BODY_BOX, 4)))
	garg.die()
	_run(session, KeenInput.create(1), 60)
	assert_true(not session.keen.is_dead, "alive")


func test_shots_do_not_hurt_robots() -> void:
	var session := _session(FIELD)
	session.inventory.charges = 1
	var butler := _add(session, ButlerRobot.create(_on_floor(ButlerRobot.BODY_BOX, 8)))
	_run(session, KeenInput.create(0, false, false, true), 1)
	_run(session, KeenInput.create(0), 30)
	assert_true(not butler.is_dead, "unharmed")
	assert_true(session.actors.all(func(a: Actor) -> bool: return not a is RaygunShot), "shot gone")


func test_butler_pushes_keen() -> void:
	var session := _session(FIELD)
	var butler := _add(session, ButlerRobot.create(_on_floor(ButlerRobot.BODY_BOX, 5)))
	butler.is_active = true
	var start_x := session.keen.position.x
	_run(session, KeenInput.create(0), 120)
	assert_true(not session.keen.is_dead, "harmless")
	assert_true(session.keen.position.x < start_x, "pushed to the left")


func test_robots_turn_at_ledges() -> void:
	var rows := FIELD.duplicate()
	rows[FLOOR_ROW] = "#########....................."
	var session := _session(rows)
	var butler := _add(session, ButlerRobot.create(_on_floor(ButlerRobot.BODY_BOX, 6)))
	butler.is_active = true
	butler.facing = 1
	_run(session, KeenInput.create(0), 300)
	assert_true(butler.hitbox().end.y <= _row_top(FLOOR_ROW) + 0.01, "did not fall")
	assert_true(butler.hitbox().end.x <= _column_left(9) + 0.01, "stayed on the floor")


func test_tank_shot_kills_keen() -> void:
	var session := _session(FIELD)
	var tank := _add(session, TankRobot.create(_on_floor(TankRobot.BODY_BOX, 25)))
	tank.is_active = true
	tank.facing = -1
	var start_x := tank.position.x
	_run(session, KeenInput.create(0), TankRobot.MAX_WALK_TICKS + 2 * TankRobot.AIM_TICKS + 60)
	assert_true(tank.position.x < start_x, "walked towards Keen")
	assert_true(session.keen.is_dead, "shot")


func test_landing_on_a_yorp_stuns_it() -> void:
	var session := _session(FIELD)
	var yorp := _add(session, Yorp.create(_on_floor(Yorp.BODY_BOX, 2)))
	yorp.is_active = true
	session.keen.position.y -= EgaGraphics.TILE_SIZE * 3
	_run(session, KeenInput.create(0), 25)
	assert_equal(yorp.mode, Yorp.Mode.STUNNED, "stunned")
	assert_true(not session.keen.is_dead, "Keen is fine")


func test_walking_into_a_yorp_pushes_keen_back() -> void:
	var session := _session(FIELD)
	var yorp := _add(session, Yorp.create(_on_floor(Yorp.BODY_BOX, 4)))
	yorp.is_active = true
	_run(session, KeenInput.create(1), 60)
	assert_true(not session.keen.is_dead, "harmless")
	assert_true(session.keen.hitbox().end.x <= yorp.hitbox().position.x + 4.0, "kept back")


func test_ice_chunk_freezes_keen() -> void:
	var session := _session(FIELD)
	var cannon_cell := Vector2i(KEEN_CELL.x + 5, KEEN_CELL.y + 1) + _border()
	_add(session, IceCannon.create(Vector2(cannon_cell * EgaGraphics.TILE_SIZE), Vector2i(-1, 0)))
	var frozen := false
	for tick in IceCannon.FIRE_INTERVAL_TICKS + 60:
		session.step(KeenInput.create(0))
		frozen = frozen or session.keen.is_frozen()
	assert_true(frozen, "frozen")
	assert_true(not session.keen.is_dead, "but alive")
	assert_true(
		session.actors.any(func(actor: Actor) -> bool: return actor is IceBit), "chunk shattered"
	)


func test_frozen_keen_ignores_the_buttons() -> void:
	var session := _session(FIELD)
	session.keen.freeze(0.0)
	var x := session.keen.position.x
	_run(session, KeenInput.create(1, true), 30)
	assert_equal(session.keen.position.x, x, "does not walk")
	assert_true(session.keen.sprite_index() >= KeenPhysics.SPRITE_FROZEN, "ice block")
	_run(session, KeenInput.create(1), KeenPhysics.FROZEN_TICKS)
	assert_true(session.keen.position.x > x, "walks after thawing")


func test_breaking_the_chain_drops_the_stone() -> void:
	var rows := FIELD.duplicate()
	rows[3] = "..........#########..........."
	rows[4] = "..........#########..........."
	var session := _session(rows)
	var chain_cell := Vector2i(14, 2) + _border()
	var chain := _add(session, StoneChain.create(Vector2(chain_cell * EgaGraphics.TILE_SIZE)))
	var garg := _add(session, Garg.create(Vector2(_column_left(14), _row_top(5))))
	garg.position.y -= Garg.BODY_BOX.position.y
	chain.hit_by_shot(session)
	_run(session, KeenInput.create(0), StoneChain.DROP_TICKS * StoneChain.DROP_ROWS + 1)
	assert_true(garg.is_dead, "crushed")
	assert_true(chain.removed, "done")
	var stone_top := Vector2i(14, 3 + StoneChain.DROP_ROWS) + _border()
	assert_equal(session.level.tile_at(stone_top), Fixtures.WALL, "stone moved down")
	assert_equal(session.level.tile_at(Vector2i(14, 3) + _border()), Fixtures.AIR, "gap above")


func _session(rows: PackedStringArray) -> LevelSession:
	var session := LevelSession.create(
		Fixtures.create_level(rows), Fixtures.create_properties(), Inventory.new(), _keen_start()
	)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


func _add(session: LevelSession, enemy: Enemy) -> Enemy:
	session.add_actor(enemy)
	return enemy


## Top left of a sprite whose [param box] stands on the floor in [param column].
func _on_floor(box: Rect2, column: int) -> Vector2:
	return Vector2(_column_left(column), _row_top(FLOOR_ROW) - box.end.y)


func _keen_start() -> Vector2:
	return Vector2((KEEN_CELL + _border()) * EgaGraphics.TILE_SIZE)


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _row_top(row: int) -> float:
	return (row + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
