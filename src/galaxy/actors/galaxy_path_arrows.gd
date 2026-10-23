class_name GalaxyPathArrows
extends RefCounted
## Moving along the path arrows of the info plane (Omni `ck_obj.c`
## CK_GoPlatThink, `ck5_obj1.c` CK5_VolteMove; facts and numbers only):
## Keen 5's Volteface and the GoPlats of Keen 5 and 6. An arrow is an info
## value 0x5B-0x62 (91-98 in Keen 5): up, right, down, left, up-right,
## down-right, down-left, up-left. The mover goes the way of its arrow a
## whole tile at a time; each time it reaches the next tile it reads the
## arrow there (at its position plus a look offset: Keen 5's purple
## GoPlats, placed 0x40 into their tile, look 0x40 further; the red ones
## and the Volteface not) and goes on that way with what is left of
## its move. A switch can turn an arrow round ([GalaxyKeen]), so the way
## changes the next time the mover reaches that tile.
##
## The original stops the game with an error when a mover reaches a tile
## without an arrow; ours reports it and stops there.

## The first arrow's info value (Omni 0x5B).
const FIRST_ARROW := 0x5B
## The ways of the arrows, in their order (Omni ck_infoplaneArrowsX/Y).
const HEADINGS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(-1, -1),
]
const TILE := GalaxyUnits.PER_TILE

## The arrow it follows now (0-7), and how far it is to the next tile, in
## units (Omni user1, user2).
var arrow := 0
var to_next := TILE
## It reached a tile without an arrow and stays where it is.
var stuck := false


## A mover starting at [param cell] of [param world] by arrow [param first]
## (0-7), which it writes into its own tile of the info plane (Omni).
static func start_at(world: GalaxyWorld, cell: Vector2i, first: int) -> GalaxyPathArrows:
	var path := GalaxyPathArrows.new()
	path.arrow = first
	world.set_info(cell, FIRST_ARROW + first)
	return path


## The arrow (0-7) the info value [param value] is, or -1.
static func arrow_of(value: int) -> int:
	var index := value - FIRST_ARROW
	return index if index >= 0 and index < HEADINGS.size() else -1


## Adds this frame's move of [param speed] units a tic to [param mover]'s
## step, when nothing moved it yet this frame; [param look] is added to its
## position (x and y) where it reads the arrow of the next tile.
func advance(mover: GalaxyObject, speed: int, look := 0) -> void:
	if mover.step != Vector2i.ZERO or stuck:
		return
	var distance := mover.world.tics * speed
	if to_next > distance:
		to_next -= distance
		mover.step += HEADINGS[arrow] * distance
		return
	mover.step += HEADINGS[arrow] * to_next
	var at := mover.position + mover.step + Vector2i(look, look)
	var cell := Vector2i(GalaxyUnits.to_tile(at.x), GalaxyUnits.to_tile(at.y))
	var next := arrow_of(mover.world.info_at(cell.x, cell.y))
	if next < 0:
		push_error("A path mover reached tile %s without an arrow." % cell)
		stuck = true
		return
	arrow = next
	distance -= to_next
	to_next = TILE - distance
	mover.step += HEADINGS[arrow] * distance
