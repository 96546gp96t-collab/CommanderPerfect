class_name ShipFlight
extends RefCounted
## Keen's ship flying through space on map 81 during the ending, following a
## fixed script of commands, one tick at a time.
##
## The scripts and speeds are those of Commander Genius, used as
## documentation; they still have to be compared with the original. Speeds
## are multiples of [constant SPEED] (16/32 pixel per tick).

enum Command { MOVE, WAIT, SHOW_MARK, HIDE_MARK, STOP_SCROLLING, SCROLL, FADE_OUT }

const SPEED := 16 * KeenPhysics.SUBPIXEL
const UP := Vector2(0, -SPEED)
const DOWN := Vector2(0, SPEED / 2.0)
const LEFT := Vector2(-SPEED, 0)
const RIGHT := Vector2(SPEED, 0)
const DOWN_RIGHT := Vector2(SPEED * 2.0, SPEED * 0.8)
const SPRITE_RIGHT := 115
const SPRITE_LEFT := 116
const SPRITE_EXCLAMATION := 117
const SPRITE_QUESTION := 118
## Where the "?" or "!" floats, relative to the ship (an estimate).
const MARK_OFFSET := Vector2(16, -16)
## Ticks the screen takes to fade to black.
const FADE_TICKS := 25

## From Mars to Earth: the ship takes off, flies to Earth, stops ("?"),
## looks around to the left, then dives into Earth ("!").
const TO_EARTH_START := Vector2i(6, 5)
const TO_EARTH: Array[Array] = [
	[Command.MOVE, 60, UP],
	[Command.WAIT, 12],
	[Command.MOVE, 673, DOWN_RIGHT],
	[Command.WAIT, 25],
	[Command.MOVE, 120, DOWN],
	[Command.WAIT, 18],
	[Command.SHOW_MARK, SPRITE_QUESTION],
	[Command.STOP_SCROLLING],
	[Command.WAIT, 88],
	[Command.HIDE_MARK],
	[Command.WAIT, 12],
	[Command.MOVE, 175, LEFT],
	[Command.WAIT, 38],
	[Command.SHOW_MARK, SPRITE_EXCLAMATION],
	[Command.WAIT, 125],
	[Command.HIDE_MARK],
	[Command.WAIT, 12],
	[Command.MOVE, 175, RIGHT],
	[Command.WAIT, 6],
	[Command.SCROLL],
	[Command.MOVE, 116, DOWN],
	[Command.FADE_OUT],
	[Command.MOVE, FADE_TICKS, DOWN],
]
## From Earth to the Vorticon mothership.
const TO_MOTHERSHIP_START := Vector2i(48, 23)
const TO_MOTHERSHIP: Array[Array] = [
	[Command.MOVE, 58, UP],
	[Command.STOP_SCROLLING],
	[Command.WAIT, 13],
	[Command.MOVE, 208, LEFT],
	[Command.FADE_OUT],
	[Command.MOVE, FADE_TICKS, DOWN],
]

## Top left of the ship sprite, in map pixels.
var position := Vector2.ZERO
var sprite := SPRITE_RIGHT
## The "?" or "!" sprite next to the ship, or -1.
var mark := -1
## Whether the view follows the ship.
var scrolling := true
## How dark the screen is: 0 normal, 1 black.
var fade := 0.0
var _script: Array[Array] = []
var _index := 0
var _ticks_left := 0
var _fade_ticks := -1


## A flight of [param script], starting with the ship in [param start_cell].
static func create(script: Array[Array], start_cell: Vector2i) -> ShipFlight:
	var flight := ShipFlight.new()
	flight._script = script
	flight.position = Vector2(start_cell * EgaGraphics.TILE_SIZE)
	flight._begin_command()
	return flight


static func to_earth() -> ShipFlight:
	return create(TO_EARTH, TO_EARTH_START)


static func to_mothership() -> ShipFlight:
	return create(TO_MOTHERSHIP, TO_MOTHERSHIP_START)


func is_finished() -> bool:
	return _index >= _script.size()


## Where the mark floats, in map pixels.
func mark_position() -> Vector2:
	return position + MARK_OFFSET


func step() -> void:
	if _fade_ticks >= 0:
		_fade_ticks += 1
		fade = minf(1.0, float(_fade_ticks) / FADE_TICKS)
	if is_finished():
		return
	var command: Array = _script[_index]
	if command[0] == Command.MOVE:
		var velocity: Vector2 = command[2]
		position += velocity
		if velocity.x != 0.0:
			sprite = SPRITE_LEFT if velocity.x < 0.0 else SPRITE_RIGHT
	_ticks_left -= 1
	if _ticks_left <= 0:
		_index += 1
		_begin_command()


## Carries out the commands that take no time, up to the next one that does.
func _begin_command() -> void:
	while not is_finished():
		var command: Array = _script[_index]
		match command[0]:
			Command.MOVE, Command.WAIT:
				_ticks_left = command[1]
				return
			Command.SHOW_MARK:
				mark = command[1]
			Command.HIDE_MARK:
				mark = -1
			Command.STOP_SCROLLING:
				scrolling = false
			Command.SCROLL:
				scrolling = true
			Command.FADE_OUT:
				_fade_ticks = 0
		_index += 1
