class_name Keen3MachineSweep
extends RefCounted
## A sweep of Mortimer's Mangling Machine (Chocolate Keen): row by row from
## the top, every tile of its columns that is not the background becomes
## the background, with a splash on each and SHOTHIT. One clears the arms
## after the sixth spark, one the body after the heart ([Keen3Machine]).

var columns := PackedInt32Array()
## The next row to clear, and the last one.
var row := 0
var last_row := 0
## Ticks between two rows.
var period := 1.0
var _time := 0.0


## A sweep of [param sweep_columns] from row [param rows].x to [param
## rows].y, a row every [param ticks]. The first row goes after one period.
static func across(
	sweep_columns: PackedInt32Array, rows: Vector2i, ticks: float
) -> Keen3MachineSweep:
	var sweep := Keen3MachineSweep.new()
	sweep.columns = sweep_columns
	sweep.row = rows.x
	sweep.last_row = rows.y
	sweep.period = ticks
	return sweep


## Changes the tiles of [param session]'s level to [param tiles] (cell to
## tile), only where they differ.
static func change_tiles(session: LevelSession, tiles: Dictionary[Vector2i, int]) -> void:
	for cell in tiles:
		if session.level.tile_at(cell) != tiles[cell]:
			session.set_tile(cell, tiles[cell])


## A splash as a shot leaves it, on the cell [param cell].
static func splash_at(cell: Vector2i) -> Keen3Shot:
	var start := Vector2(cell * EgaGraphics.TILE_SIZE) - RaygunShot.SPLASH_OFFSET
	var splash := Keen3Shot.fired(start, 1, false)
	splash.splash()
	return splash


func is_finished() -> bool:
	return row > last_row


func step(session: LevelSession) -> void:
	if is_finished():
		return
	_time += 1.0
	if _time < period - Keen3Machine.TIME_TOLERANCE:
		return
	_time -= period
	_clear_row(session)
	row += 1


func _clear_row(session: LevelSession) -> void:
	var cleared := false
	for column in columns:
		var cell := Vector2i(column, row)
		if session.level.tile_at(cell) == Keen3Machine.EMPTY_TILE:
			continue
		session.set_tile(cell, Keen3Machine.EMPTY_TILE)
		session.add_actor(splash_at(cell))
		cleared = true
	if cleared:
		session.play_sound(Sound.Id.SHOT_HIT)
