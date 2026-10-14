class_name Interpolation
extends RefCounted
## The position of something that moves once per tick, drawn at any moment
## in between: the game runs at a fixed 60 ticks per second, while the
## screen may show 120 or more frames per second (or not exactly one frame
## per tick). Drawing everything part of the way from the previous tick to
## the last one makes motion smooth, at the cost of showing it one tick
## late.
##
## Without smooth motion everything is drawn on the last tick, on whole
## pixels, as in the original.

## A move longer than this (in pixels) is a jump, not motion: it is not
## drawn in between.
const JUMP_DISTANCE := 24.0

var previous := Vector2.ZERO
var current := Vector2.ZERO
## The position given by the last call to [method at], not rounded.
var last_at := Vector2.ZERO
var _fresh := true


## The position after a new tick.
func move_to(at: Vector2) -> void:
	previous = current if not _fresh and current.distance_to(at) <= JUMP_DISTANCE else at
	current = at
	_fresh = false


## Starts again from the current position.
func snap() -> void:
	previous = current


## Where to draw: [param blend] (0-1) of the way from the previous tick to
## the last one; without [param smooth] the last one, on a whole pixel.
func at(blend: float, smooth: bool) -> Vector2:
	if not smooth:
		last_at = current
		return current.floor()
	last_at = previous.lerp(current, clampf(blend, 0.0, 1.0))
	return last_at
