class_name Keen2Tantalus
extends RefCounted
## What happens to a Tantalus Ray machine after Keen shot its spark
## ([Keen2Spark]): a fixed series of tile changes around the spark's cell
## (mx, my), one step every [constant STEP_TICKS] ticks
## (docs/keen2/gameplay.md, "The Tantalus Ray machine"):
##   at once      the glass at (mx-2 .. mx+2, my) breaks, the dome above it
##                (mx-1 .. mx+1, my-1) goes, and the machine's switch at
##                (mx-3, my+4) breaks: it is no switch any more
##   3 steps      the purple parts at (mx, my+3), (mx, my+4), (mx, my+5) burn
##                out, each with a splash and [constant POINTS] points
##   4 steps      the glowing columns mx+3 .. mx+6 (rows my+3 .. my+5) go dark,
##                with splashes
##   last         the targeting display (mx-7 .. mx-5, my+2 .. my+4) stops
## The positions fit every machine in the levels (the spark's cell is (66,
## 14), (126, 14) or (46, 14), the switch always at (mx-3, my+4)). The new
## tile numbers come from Commander Genius; their pictures fit (broken
## glass, a broken lever, a burnt tube, a dark lamp, a gray display), but
## whether the original uses exactly these is still to be seen. All points
## of the machine are here, in one place.

## Tiles of the broken glass, from mx-2 to mx+2. estimate: Commander
## Genius's numbers.
const BROKEN_GLASS: PackedInt32Array = [492, 546, 547, 548, 492]  # estimate
const GLASS_LEFT := -2
const DOME_ROW := -1
const DOME_HALF_WIDTH := 1
## The dome leaves the gray background.
const EMPTY_TILE := LevelSession.BACKGROUND_TILE
const SWITCH_OFFSET := Vector2i(-3, 4)
const BROKEN_SWITCH := 506  # estimate
const PURPLE_OFFSET := Vector2i(0, 3)
const PURPLE_STEPS := 3
const BURNT_PURPLE := 505  # estimate
const GLOW_OFFSET := Vector2i(3, 3)
const GLOW_STEPS := 4
const GLOW_ROWS := 3
const DARK_GLOW := 549  # estimate
const DISPLAY_OFFSET := Vector2i(-7, 2)
const DISPLAY_SIZE := 3
const STILL_DISPLAY := 533  # estimate
const STEP_TICKS := 26  # estimate
## Points for each purple part. Commander Genius gives them three times
## (30,000 in all); the original may give 10,000 once.
const POINTS := 10000  # estimate
const TOTAL_POINTS := POINTS * PURPLE_STEPS  # estimate

## The spark's cell.
var center := Vector2i.ZERO
## Whether the last step is done.
var finished := false
var _timer := 0
var _step := 0


## The wreck of the machine whose spark was in [param spark_cell]. Call
## [method step] every tick, starting with the tick of the shot.
static func wreck(spark_cell: Vector2i) -> Keen2Tantalus:
	var tantalus := Keen2Tantalus.new()
	tantalus.center = spark_cell
	return tantalus


## Advances one tick.
func step(session: LevelSession) -> void:
	if finished:
		return
	if _timer > 0:
		_timer -= 1
		return
	_timer = STEP_TICKS - 1
	if _step == 0:
		_break(session)
	elif _step <= PURPLE_STEPS:
		_burn_purple(session, _step - 1)
	elif _step <= PURPLE_STEPS + GLOW_STEPS:
		_darken_glow(session, _step - 1 - PURPLE_STEPS)
	else:
		_stop_display(session)
		finished = true
	_step += 1


func _break(session: LevelSession) -> void:
	for index in BROKEN_GLASS.size():
		_change(session, Vector2i(GLASS_LEFT + index, 0), BROKEN_GLASS[index])
	for x in range(-DOME_HALF_WIDTH, DOME_HALF_WIDTH + 1):
		_change(session, Vector2i(x, DOME_ROW), EMPTY_TILE)
	_change(session, SWITCH_OFFSET, BROKEN_SWITCH)


func _burn_purple(session: LevelSession, index: int) -> void:
	var offset := PURPLE_OFFSET + Vector2i(0, index)
	_change(session, offset, BURNT_PURPLE)
	_splash(session, offset)
	var lives := session.inventory.lives
	session.inventory.add_points(POINTS)
	if session.inventory.lives > lives:
		session.play_sound(Sound.Id.EXTRA_LIFE)


func _darken_glow(session: LevelSession, index: int) -> void:
	for row in GLOW_ROWS:
		var offset := GLOW_OFFSET + Vector2i(index, row)
		_change(session, offset, DARK_GLOW)
		_splash(session, offset)


func _stop_display(session: LevelSession) -> void:
	for y in DISPLAY_SIZE:
		for x in DISPLAY_SIZE:
			_change(session, DISPLAY_OFFSET + Vector2i(x, y), STILL_DISPLAY)


## Changes the tile at [param offset] from the spark's cell, when that is
## in the level.
func _change(session: LevelSession, offset: Vector2i, tile: int) -> void:
	var cell := center + offset
	if session.level.playable_rect().has_point(cell):
		session.set_tile(cell, tile)


## A splash of a shot (ZAP or ZOT) on the cell at [param offset].
func _splash(session: LevelSession, offset: Vector2i) -> void:
	var start := Vector2(center + offset) * EgaGraphics.TILE_SIZE - RaygunShot.SPLASH_OFFSET
	var splash := Keen2Shot.fired(start, 1)
	splash.splash()
	session.add_actor(splash)
	session.play_sound_at(Sound.Id.SHOT_HIT, start)
