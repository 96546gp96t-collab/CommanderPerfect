class_name Keen2Scrub
extends Keen2Carrier
## The Scrub of Keen 2 (info value 4): a red crawler that follows floors,
## walls and ceilings. It is harmless; Keen can ride on it
## ([Keen2Carrier]). One shot kills it: it pops up and drops dead.
##
## It always holds on to a surface while it crawls ([enum Crawl]: the way it
## goes; seen in that direction, the surface is on its left-hand side):
##   LEFT on a floor, UP a wall on its left, RIGHT along a ceiling, DOWN a
##   wall on its right.
## Running into something (an inside corner) turns it to the next one:
## LEFT, UP, RIGHT, DOWN, LEFT. When its surface ends (an outside corner) it
## goes round the edge to the one before, if that edge is solid; otherwise
## it lets go and falls, and on landing it crawls left again. Commander
## Genius's corner rules are messy (docs/keen2/research.md section 5); these
## are our own, to be compared with the original.

enum Crawl { LEFT, UP, RIGHT, DOWN }

## The way each [enum Crawl] goes, and where its surface is.
const MOVES: Array[Vector2] = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
const SURFACES: Array[Vector2] = [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
## Two frames per [enum Crawl], in that order from 102.
const SPRITE_FIRST := 102
const FRAMES := 2
const SPRITE_SHOT := 110
const SPRITE_DEAD := 111
## The collision box inside the sprite. estimate: to be read from the sprite
## table of EGAHEAD.CK2.
const BODY_BOX := Rect2(0, 0, 16, 16)  # estimate

const SPEED := 25 * Keen2Enemy.SUBPIXEL  # estimate
const FRAME_TICKS := 12  # estimate
## Shot: it pops up this fast, then falls.
const POP_SPEED := 10 * Keen2Enemy.SUBPIXEL  # estimate

var crawl := Crawl.LEFT
var is_falling := true
## Pixels still to go round an outside corner, without a surface.
var _rounding := 0.0


static func create(start: Vector2) -> Keen2Scrub:
	var scrub := Keen2Scrub.new()
	scrub.position = start
	scrub.body_box = BODY_BOX
	return scrub


func sprite_index() -> int:
	if is_dead:
		return SPRITE_DEAD if on_ground else SPRITE_SHOT
	if is_falling:
		return SPRITE_FIRST
	return SPRITE_FIRST + crawl * FRAMES + (_timer / FRAME_TICKS) % FRAMES


func die() -> void:
	if is_dead:
		return
	super.die()
	is_falling = true
	velocity.y = -POP_SPEED
	on_ground = false


func death_sound() -> Sound.Id:
	return Sound.Id.SHOT_HIT


func _think(session: LevelSession) -> void:
	_timer += 1
	if is_falling:
		_fall(session)
		if on_ground and not is_dead:
			is_falling = false
			crawl = Crawl.LEFT
		return
	_crawl(session)


func _crawl(session: LevelSession) -> void:
	var wanted := MOVES[crawl] * SPEED
	var moved := Vector2(
		session.collision.sweep_x(hitbox(), wanted.x), session.collision.sweep_y(hitbox(), wanted.y)
	)
	position += moved
	if not moved.is_equal_approx(wanted):
		# An inside corner: crawl on along what stopped it.
		crawl = ((crawl + 1) % Crawl.size()) as Crawl
		_rounding = 0.0
	elif _rounding > 0.0:
		_rounding -= SPEED
	elif not _touches(session, SURFACES[crawl]):
		_go_round_the_edge(session)


## The surface ended: go round its edge, or fall when that edge is not
## solid (a floor that is only solid on top, for example).
func _go_round_the_edge(session: LevelSession) -> void:
	_snap_to_edge()
	var inside := _trailing_corner() + (SURFACES[crawl] - MOVES[crawl]) / 2.0
	var cell := Vector2i((inside / TILE).floor())
	if not session.collision.is_solid(cell, _edge_facing(MOVES[crawl])):
		is_falling = true
		velocity = Vector2.ZERO
		on_ground = false
		return
	crawl = ((crawl + Crawl.size() - 1) % Crawl.size()) as Crawl
	var size := body_box.size
	_rounding = absf(MOVES[crawl].dot(size))


## Whether a solid tile edge touches the box on the side [param side].
func _touches(session: LevelSession, side: Vector2) -> bool:
	var box := hitbox()
	if side.x != 0.0:
		return is_zero_approx(session.collision.sweep_x(box, side.x * PROBE))
	return is_zero_approx(session.collision.sweep_y(box, side.y * PROBE))


## Moves back to the tile edge that the box's back has just passed, so that
## it goes round the corner tight against it.
func _snap_to_edge() -> void:
	var move := MOVES[crawl]
	var corner := _trailing_corner()
	var tolerance := LevelCollision.EDGE_TOLERANCE
	if move.x < 0.0:
		position.x += ceilf(corner.x / TILE - tolerance) * TILE - corner.x
	elif move.x > 0.0:
		position.x += floorf(corner.x / TILE + tolerance) * TILE - corner.x
	elif move.y < 0.0:
		position.y += ceilf(corner.y / TILE - tolerance) * TILE - corner.y
	else:
		position.y += floorf(corner.y / TILE + tolerance) * TILE - corner.y


## The back corner of the box on the side of its surface.
func _trailing_corner() -> Vector2:
	var box := hitbox()
	var move := MOVES[crawl]
	var surface := SURFACES[crawl]
	var x := box.end.x if move.x < 0.0 or surface.x > 0.0 else box.position.x
	var y := box.end.y if move.y < 0.0 or surface.y > 0.0 else box.position.y
	return Vector2(x, y)


## The edge of a tile that faces [param direction].
static func _edge_facing(direction: Vector2) -> LevelCollision.Edge:
	if direction.x < 0.0:
		return LevelCollision.Edge.LEFT
	if direction.x > 0.0:
		return LevelCollision.Edge.RIGHT
	return LevelCollision.Edge.TOP if direction.y < 0.0 else LevelCollision.Edge.BOTTOM
