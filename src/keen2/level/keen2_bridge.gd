class_name Keen2Bridge
extends RefCounted
## A bridge that a switch lays out or takes in, one tile at a time
## (docs/keen2/gameplay.md, "Bridges"). It starts at [member start] and runs
## to the right, unless the tile right of the start is solid on its left
## side; then it runs to the left. Laying stops at the first tile that
## blocks the way. Taking it in goes from the far end back to the start and
## puts back the one background tile that was remembered for the whole
## bridge.
##
## Every change goes through [method LevelSession.set_tile], so the level,
## the collision (Keen stands on a bridge tile as on any floor) and every
## picture (original, xBRZ, HD) change cell by cell.

## Commander Genius's bridge tile: a gray girder, solid on every side. No
## level holds it before a bridge is laid. estimate: the picture fits.
const BRIDGE_TILE := 270  # estimate
## Ticks between two tiles, laying and taking in alike.
const TICKS_PER_TILE := 4  # estimate
## The longest bridge, so that a level without a wall cannot run forever.
const MAX_LENGTH := 256

## The first cell of the bridge.
var start := Vector2i.ZERO
## 1 to the right, -1 to the left.
var direction := 1
## The tile that the bridge covers, put back when it is taken in.
var background := 0
## How many tiles lie now.
var length := 0
## Whether it is being laid (true) or taken in (false).
var extending := true
## Whether it still has tiles to lay or take in.
var moving := true
var _timer := 0


## A bridge at [param start_cell] in [param session]: one that lies there
## already is taken in, otherwise a new one is laid out.
static func at(session: LevelSession, start_cell: Vector2i) -> Keen2Bridge:
	var bridge := Keen2Bridge.new()
	bridge.start = start_cell
	if session.collision.tile_at(start_cell) == BRIDGE_TILE:
		bridge._measure(session)
	else:
		var right := start_cell + Vector2i.RIGHT
		var blocked := session.collision.is_solid(right, LevelCollision.Edge.LEFT)
		bridge.direction = -1 if blocked else 1
		bridge.background = session.collision.tile_at(start_cell)
	return bridge


## Turns round: a bridge being laid is taken in from where it is, and the
## other way round.
func reverse() -> void:
	extending = not extending
	moving = true
	_timer = 0


## Advances one tick.
func step(session: LevelSession) -> void:
	if not moving:
		return
	_timer += 1
	if _timer < TICKS_PER_TILE:
		return
	_timer = 0
	if extending:
		_lay(session)
	else:
		_take_in(session)


## The cell of tile number [param index] (0 is the start).
func cell(index: int) -> Vector2i:
	return start + Vector2i(direction * index, 0)


func _lay(session: LevelSession) -> void:
	var next := cell(length)
	if length >= MAX_LENGTH or _blocks(session, next):
		moving = false
		return
	session.set_tile(next, BRIDGE_TILE)
	length += 1


func _take_in(session: LevelSession) -> void:
	if length <= 0:
		moving = false
		return
	length -= 1
	session.set_tile(cell(length), background)
	moving = length > 0


## Whether [param next] stops the bridge: a tile solid on the side it comes
## from, or the edge of the playable area.
func _blocks(session: LevelSession, next: Vector2i) -> bool:
	if session.collision.tile_at(next) < 0:
		return true
	var side := LevelCollision.Edge.LEFT if direction > 0 else LevelCollision.Edge.RIGHT
	return session.collision.is_solid(next, side)


## A bridge that lies in the level already (from its file, or laid before
## this object existed) is measured, to be taken in. Its background is the
## tile next to the start on the other side, as in Commander Genius.
func _measure(session: LevelSession) -> void:
	var right := start + Vector2i.RIGHT
	direction = 1 if session.collision.tile_at(right) == BRIDGE_TILE else -1
	background = maxi(session.collision.tile_at(start - Vector2i(direction, 0)), 0)
	length = 0
	while length < MAX_LENGTH and session.collision.tile_at(cell(length)) == BRIDGE_TILE:
		length += 1
	extending = false
