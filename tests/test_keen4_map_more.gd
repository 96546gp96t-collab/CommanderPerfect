extends "res://tests/test_case.gd"
## Checks Miragia's cycle on a hand-made map, and the pieces between the
## frames of milestone D7: the status window's drop ([GalaxyStatusDrop])
## and the queue of boxes and fades ([GalaxyScreenQueue]) (Omni numbers and
## what the original showed; docs/keen4/research.md §8, §10).

const MapFixtures := preload("res://tests/keen4_map_fixtures.gd")

const TILE := 256
const WIDTH := 34
const HEIGHT := 62
const MIRAGIA := Vector2i(10, 4)
const KEEN := Vector2i(24, 6)
const TEMPLATE_COLUMNS: PackedInt32Array = [2, 8, 14, 20, 26]


func test_miragia_comes_and_goes() -> void:
	var on_map := _miragia_map(KEEN)
	var miragia := on_map.miragia
	assert_true(miragia != null, "Miragia from info 33")
	var shown := PackedInt32Array()
	var times := PackedInt32Array()
	var tics := 0
	for frame in 600:
		MapFixtures.hold(on_map, 1)
		tics += MapFixtures.FRAME_TICS
		if shown.is_empty() or shown[-1] != miragia.column:
			shown.append(miragia.column)
			times.append(tics)
	assert_equal(
		shown.slice(0, 9), PackedInt32Array([2, 8, 14, 20, 26, 20, 14, 8, 2]), "the blocks in order"
	)
	var gaps := PackedInt32Array()
	for index in range(2, 10):
		gaps.append(times[index] - times[index - 1])
	assert_equal(
		gaps, PackedInt32Array([30, 30, 30, 300, 30, 30, 30, 300]), "30-tic steps, 300 whole (seen)"
	)
	var at := MIRAGIA + Vector2i(2, 2)
	var tile := on_map.map.tile(GalaxyMap.Layer.FOREGROUND, at.x, at.y)
	assert_equal(tile, _marker(miragia.column), "its block copied from row 60")


func test_miragia_stays_hidden_while_keen_is_there() -> void:
	var on_map := _miragia_map(MIRAGIA + Vector2i(1, 1))
	MapFixtures.hold(on_map, 200)
	assert_equal(on_map.miragia.column, Keen4Miragia.HIDDEN_COLUMN, "it does not appear")
	assert_true(on_map.miragia.holds(on_map.keen), "Keen is in its place")


func test_the_status_window_drops_and_rises() -> void:
	var drop := GalaxyStatusDrop.new()
	assert_equal(drop.bottom, 16, "its bottom starts 16 pixels down (Omni)")
	var tics := 0
	while drop.stage == GalaxyStatusDrop.Stage.DROPPING:
		drop.advance(2)
		tics += 2
	assert_equal(drop.bottom, 168, "down to 168")
	assert_equal(tics, 20, "8 pixels a tic: about 0.3 s (seen)")
	assert_equal(drop.shift(), 0, "where it is drawn")
	assert_true(drop.shows_strap() and drop.shows_arm(), "with its strap and arm")
	drop.advance(10)
	assert_equal(drop.stage, GalaxyStatusDrop.Stage.DOWN, "it waits for a key")
	drop.release()
	assert_equal(drop.bottom, 152, "it starts 16 higher")
	assert_true(not drop.shows_strap(), "the strap goes at once")
	while not drop.is_gone():
		drop.advance(2)
	assert_equal(drop.bottom, 0, "gone")


func test_the_queue_runs_boxes_timed_steps_and_what_follows() -> void:
	var queue := GalaxyScreenQueue.new()
	var log := PackedStringArray()
	var box := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	queue.add(box, 10)
	queue.add(null, 6, 0.5, func() -> void: log.append("started"))
	queue.add_box(box)
	queue.then = func() -> void: log.append("done")
	assert_equal(queue.current().tics, 10, "the first step")
	assert_true(queue.advance(12), "10 tics later the next")
	assert_equal(log, PackedStringArray(["started"]), "its start ran")
	assert_equal(queue.current().brightness, 0.5, "half bright")
	queue.advance(4)
	assert_equal(queue.current().tics, 0, "the box that waits")
	queue.advance(100)
	assert_true(not queue.is_empty(), "time does not end it")
	assert_true(queue.press(), "a key does")
	assert_equal(log, PackedStringArray(["started", "done"]), "then what follows")
	assert_true(queue.is_empty(), "empty")


## A map with Miragia (info 33) at [constant MIRAGIA], its five template
## blocks on row 60 (each tile marked with its column), and Keen at
## [param keen].
func _miragia_map(keen: Vector2i) -> Keen4MapSession:
	var rows := PackedStringArray()
	for y in HEIGHT:
		rows.append(".".repeat(WIDTH))
	rows[keen.y] = rows[keen.y].substr(0, keen.x) + "M" + rows[keen.y].substr(keen.x + 1)
	var level := MapFixtures.map(rows)
	MapFixtures.Fixtures.put_info(level, MIRAGIA, Keen4MapSession.MIRAGIA_INFO)
	for column in TEMPLATE_COLUMNS:
		for y in Keen4Miragia.SIZE.y:
			for x in Keen4Miragia.SIZE.x:
				var cell := Vector2i(column + x, Keen4Miragia.TEMPLATE_ROW + y)
				var at := cell
				level.planes[GalaxyMap.Layer.FOREGROUND][at.y * level.width + at.x] = _marker(
					column
				)
	return MapFixtures.session_of(level, Keen4Progress.new())


## The foreground tile that marks template column [param column] (empty
## tiles of the fixture, so they never block).
static func _marker(column: int) -> int:
	return 56 + TEMPLATE_COLUMNS.find(column)
