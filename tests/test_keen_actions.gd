extends "res://tests/test_case.gd"
## Tests for what Keen does besides moving: firing the raygun, the pogo stick
## he has to find first, and dying. In small hand-made levels (no game data
## needed).

const Fixtures := preload("res://tests/fixtures.gd")
const SETTLE_TICKS := 120
const OPEN_FIELD: PackedStringArray = [
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
const START_CELL := Vector2i(2, 12)


func test_dying_keen_flies_off_the_screen() -> void:
	var keen := _settled_keen()
	var start_y := keen.position.y
	keen.kill()
	_run(keen, KeenInput.create(1, true), KeenPhysics.DIE_WAIT_TICKS)
	assert_equal(keen.position.y, start_y, "lies still, whatever the input")
	assert_true(
		(
			keen.sprite_index() >= KeenPhysics.SPRITE_DEAD
			and keen.sprite_index() < KeenPhysics.SPRITE_DEAD + KeenPhysics.DEAD_FRAMES
		),
		"dying sprite"
	)
	var rise_ticks := ceili(KeenPhysics.DIE_RISE_DISTANCE / KeenPhysics.DIE_RISE_SPEED)
	_run(keen, KeenInput.create(0), rise_ticks)
	assert_true(keen.death_finished, "flew off")
	assert_true(keen.position.y < start_y - KeenPhysics.DIE_RISE_DISTANCE + 1.0, "went up")


func test_keen_cannot_use_the_pogo_stick_before_finding_it() -> void:
	var keen := _settled_keen()
	keen.step(KeenInput.create(0, false, true))
	assert_true(not keen.on_pogo, "no pogo stick")


func test_firing_holds_keen_still_on_the_ground() -> void:
	var keen := _settled_keen()
	keen.step(KeenInput.create(1, false, false, true))
	assert_true(keen.fired, "fired")
	assert_equal(keen.sprite_index(), KeenPhysics.SPRITE_SHOOT_RIGHT, "raygun out")
	var x := keen.position.x
	_run(keen, KeenInput.create(1, false, false, true), KeenPhysics.SHOOT_FRAME_TICKS - 2)
	assert_equal(keen.position.x, x, "does not walk while shooting")
	_run(keen, KeenInput.create(1), 10)
	assert_true(keen.position.x > x, "walks again afterwards")


func test_fire_button_fires_once_per_press() -> void:
	var keen := _settled_keen()
	var shots := 0
	for tick in KeenPhysics.SHOOT_FRAME_TICKS * 2:
		keen.step(KeenInput.create(0, false, false, true))
		shots += 1 if keen.fired else 0
	assert_equal(shots, 1, "holding the button")
	shots = 0
	for tick in KeenPhysics.SHOOT_FRAME_TICKS * 2:
		keen.step(KeenInput.create(0, false, false, tick % 2 == 0))
		shots += 1 if keen.fired else 0
	assert_true(shots > 1, "tapping fires again")
	assert_true(
		(
			shots
			<= (
				(
					2
					* KeenPhysics.SHOOT_FRAME_TICKS
					/ (KeenPhysics.SHOOT_FRAME_TICKS - KeenPhysics.SHOOT_REPEAT_TICKS)
				)
				+ 1
			)
		),
		"but not every tick"
	)


func test_god_mode_keeps_keen_alive() -> void:
	var keen := _settled_keen()
	keen.invincible = true
	keen.kill()
	assert_true(not keen.is_dead, "alive")


## Keen standing still on the floor of [constant OPEN_FIELD].
func _settled_keen() -> KeenBody:
	var border := Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)
	var keen := (
		KeenBody
		. create(
			Fixtures.create_collision(OPEN_FIELD),
			Vector2((START_CELL + border) * EgaGraphics.TILE_SIZE),
		)
	)
	_run(keen, KeenInput.create(0), SETTLE_TICKS)
	return keen


func _run(keen: KeenBody, input: KeenInput, ticks: int) -> void:
	for i in ticks:
		keen.step(input)
