class_name Keen3MachineArm
extends RefCounted
## One arm of Mortimer's Mangling Machine (info value 16), made of tiles, as
## Chocolate Keen has it: a shaft (597) with a claw on each side, three
## tiles high (618, 620, 619 from the top). Its cell is the shaft's lowest
## tile, with the claws beside it and below it.
##
## It starts going down and moves one tile every [constant DOWN_TICKS]
## ticks; going up one tile every [constant UP_TICKS]. Going down it turns
## up when the tile [constant TURN_UP_DEPTH] below its cell is
## [constant TURN_UP_TILE] (the floor under the claws); going up it turns
## down when the tile above its cell is no shaft. Each move clears its cell
## and the cells beside and below it and draws the shaft and the claws
## anew. A turn takes the step without moving (seen in js-dos in C7: the
## arm rests ~0.37 s at both ends, a step down and a step up). The machine
## stops it after the sixth spark.

## From the top: the claw's tiles beside the shaft (Choco).
const CLAW_TILES: PackedInt32Array = [618, 620, 619]
const TURN_UP_TILE := 471
const TURN_UP_DEPTH := 3
## 15 and 40 clock ticks (Choco).
const DOWN_TICKS := 6.2
const UP_TICKS := 16.5

## The shaft's lowest tile.
var cell := Vector2i.ZERO
var going_down := true
var stopped := false
## Ticks until the next step; it acts on its first tick.
var _wait := 1.0


## An arm whose shaft ends in [param arm_cell].
static func at(arm_cell: Vector2i) -> Keen3MachineArm:
	var arm := Keen3MachineArm.new()
	arm.cell = arm_cell
	return arm


func step(session: LevelSession) -> void:
	if stopped:
		return
	_wait -= 1.0
	if _wait > Keen3Machine.TIME_TOLERANCE:
		return
	var tile_below := session.level.tile_at(cell + Vector2i(0, TURN_UP_DEPTH))
	if going_down and tile_below == TURN_UP_TILE:
		going_down = false
	elif not going_down and session.level.tile_at(cell + Vector2i.UP) != Keen3Machine.SHAFT_TILE:
		going_down = true
	else:
		_move(session, 1 if going_down else -1)
	_wait += DOWN_TICKS if going_down else UP_TICKS


## Moves the arm one tile down ([param rows] 1) or up (-1).
func _move(session: LevelSession, rows: int) -> void:
	var tiles: Dictionary[Vector2i, int] = {}
	for row in CLAW_TILES.size():
		for side in [-1, 0, 1]:
			tiles[cell + Vector2i(side, row)] = Keen3Machine.EMPTY_TILE
	cell.y += rows
	tiles[cell] = Keen3Machine.SHAFT_TILE
	if rows > 0:
		tiles[cell + Vector2i.UP] = Keen3Machine.SHAFT_TILE
	for row in CLAW_TILES.size():
		tiles[cell + Vector2i(-1, row)] = CLAW_TILES[row]
		tiles[cell + Vector2i(1, row)] = CLAW_TILES[row]
	Keen3MachineSweep.change_tiles(session, tiles)
