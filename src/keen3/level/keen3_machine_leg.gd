class_name Keen3MachineLeg
extends RefCounted
## One leg of Mortimer's Mangling Machine (info value 17 the left, 18 the
## right), made of tiles, as Chocolate Keen has it: a shaft (597) ending in
## a foot four tiles wide (621, 623, 623, 622 from left to right). Its cell
## is the shaft's lowest tile; the left foot reaches three tiles left of
## it, the right foot three tiles right (as level 16 draws them).
##
## It steps one tile every [constant STEP_TICKS] ticks; the left leg starts
## going up, the right one down. Going up it turns down when the tile above
## its cell is no shaft. Going down onto [constant FLOOR_TILE] (the tile
## below its cell) the foot slams: FOOTSLAM, a wait of
## [constant SLAM_TICKS], then up again. A turn, also the one after the
## slam's wait, takes a step without moving (seen in js-dos in C7: a foot
## stays down ~1.9 s, two steps and the wait). The machine stops it when
## the heart is shot.

## The foot's tiles from left to right (Choco; level 16 draws both so).
const FOOT_TILES: PackedInt32Array = [621, 623, 623, 622]
const FLOOR_TILE := 430
## 35 clock ticks (Choco).
const STEP_TICKS := 14.4
## 200 clock ticks (Choco).
const SLAM_TICKS := 82.0

## The shaft's lowest tile, part of the foot.
var cell := Vector2i.ZERO
var is_left := true
var going_down := false
var stopped := false
## Ticks until the next step; it acts on its first tick.
var _wait := 1.0


## A leg whose shaft ends in [param leg_cell]; [param left] for info 17.
static func at(leg_cell: Vector2i, left: bool) -> Keen3MachineLeg:
	var leg := Keen3MachineLeg.new()
	leg.cell = leg_cell
	leg.is_left = left
	leg.going_down = not left
	return leg


func step(session: Keen3LevelSession) -> void:
	if stopped:
		return
	_wait -= 1.0
	if _wait > Keen3Machine.TIME_TOLERANCE:
		return
	if going_down and session.level.tile_at(cell + Vector2i.DOWN) == FLOOR_TILE:
		going_down = false
		session.play_keen3_sound(Keen3Sounds.FOOTSLAM)
		# The wait, then the turn's own step.
		_wait += SLAM_TICKS + STEP_TICKS
		return
	if not going_down and session.level.tile_at(cell + Vector2i.UP) != Keen3Machine.SHAFT_TILE:
		going_down = true
	else:
		_move(session, 1 if going_down else -1)
	_wait += STEP_TICKS


## The four cells of the foot, from left to right.
func foot_cells() -> Array[Vector2i]:
	var first := cell.x - (FOOT_TILES.size() - 1) if is_left else cell.x
	var cells: Array[Vector2i] = []
	for index in FOOT_TILES.size():
		cells.append(Vector2i(first + index, cell.y))
	return cells


## Moves the leg one tile down ([param rows] 1) or up (-1).
func _move(session: LevelSession, rows: int) -> void:
	var tiles: Dictionary[Vector2i, int] = {}
	for foot_cell in foot_cells():
		tiles[foot_cell] = Keen3Machine.EMPTY_TILE
	cell.y += rows
	if rows > 0:
		tiles[cell + Vector2i.UP] = Keen3Machine.SHAFT_TILE
	var cells := foot_cells()
	for index in cells.size():
		tiles[cells[index]] = FOOT_TILES[index]
	Keen3MachineSweep.change_tiles(session, tiles)
