class_name Keen2Flight
extends RefCounted
## A ship flying over map 81 in Keen 2's ending, by a fixed script: it waits,
## then flies a number of ticks at a steady speed, then the next leg. Two
## flights: Keen's small ship from the mothership down to the Earth, and the
## Vorticon mothership flying off. The legs come from Commander Genius
## (docs/keen2/research.md section 9): estimates.

## Keen's small ship, flying right (and down), and the mothership.
const SMALL_SHIP_SPRITE := 132
const MOTHERSHIP_SPRITE := 72
## Commander Genius's speeds are in 1/32 pixel per tick.
const SUBPIXEL := KeenPhysics.SUBPIXEL
## Ticks before the first leg.
const WAIT_TICKS := 10  # estimate
## Keen's ship: 672 ticks down to the right, then 150 ticks straight down.
const HOME_LEGS: Array[Array] = [
	[672, Vector2(32, 12.8) * SUBPIXEL],
	[150, Vector2(0, 8) * SUBPIXEL],
]  # estimate
## The mothership: 80 ticks up to the left.
const MOTHERSHIP_LEGS: Array[Array] = [[80, Vector2(-32, -12.8) * SUBPIXEL]]  # estimate
## The mothership's start (a tile) and the view's top left meanwhile.
const MOTHERSHIP_CELL := Vector2i(8, 26)  # estimate
const MOTHERSHIP_VIEW := Vector2(0, 300)  # estimate

## Top left of the sprite, in map pixels.
var position := Vector2.ZERO
var sprite := SMALL_SHIP_SPRITE
var _legs: Array[Array] = []
var _leg := 0
var _ticks := 0
var _wait := WAIT_TICKS


## Keen's ship from [param start] (top left, in map pixels) to the Earth.
static func home(start: Vector2) -> Keen2Flight:
	return _create(start, SMALL_SHIP_SPRITE, HOME_LEGS)


## The mothership flying off from [constant MOTHERSHIP_CELL].
static func mothership() -> Keen2Flight:
	var start := Vector2(MOTHERSHIP_CELL * EgaGraphics.TILE_SIZE)
	return _create(start, MOTHERSHIP_SPRITE, MOTHERSHIP_LEGS)


static func _create(start: Vector2, sprite_index: int, legs: Array[Array]) -> Keen2Flight:
	var flight := Keen2Flight.new()
	flight.position = start
	flight.sprite = sprite_index
	flight._legs = legs
	return flight


## Moves on by one tick.
func step() -> void:
	if _wait > 0:
		_wait -= 1
		return
	if is_finished():
		return
	position += _legs[_leg][1]
	_ticks += 1
	if _ticks >= _legs[_leg][0]:
		_ticks = 0
		_leg += 1


func is_finished() -> bool:
	return _leg >= _legs.size()
