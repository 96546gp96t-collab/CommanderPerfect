class_name OnlineInput
extends RefCounted
## The buttons of the player who joins, on their way to the host.
##
## They are sent only when they change, as a few bits, reliably and in
## order. The host takes at most one change per tick from the queue, so a
## quick tap that pressed and released a button between two of his ticks
## still lasts one tick, as it would have at the joiner's own keyboard.

## Changes waiting longer than this many ticks are not a player but a flood.
const MAX_QUEUED := 64
const JUMP := 1
const POGO := 2
const FIRE := 4
const LEFT := 8
const RIGHT := 16
const UP := 32
const DOWN := 64
const ALL_BITS := 127

var _queue := PackedInt32Array()
var _current := 0


## [param input] as bits.
static func to_bits(input: KeenInput) -> int:
	var bits := 0
	bits |= JUMP if input.jump else 0
	bits |= POGO if input.pogo else 0
	bits |= FIRE if input.fire else 0
	bits |= LEFT if input.direction < 0 else (RIGHT if input.direction > 0 else 0)
	bits |= UP if input.vertical < 0 else (DOWN if input.vertical > 0 else 0)
	return bits


static func from_bits(bits: int) -> KeenInput:
	var input := (
		KeenInput
		. create(
			(1 if bits & RIGHT else 0) - (1 if bits & LEFT else 0),
			bits & JUMP != 0,
			bits & POGO != 0,
			bits & FIRE != 0,
		)
	)
	input.vertical = (1 if bits & DOWN else 0) - (1 if bits & UP else 0)
	return input


## (Host) a change arrived.
func receive(bits: int) -> void:
	if _queue.size() < MAX_QUEUED:
		_queue.append(bits & ALL_BITS)


## (Host) the buttons for the next tick.
func next() -> KeenInput:
	if not _queue.is_empty():
		_current = _queue[0]
		_queue.remove_at(0)
	return from_bits(_current)


## Lets go of everything, for example when the player leaves.
func clear() -> void:
	_queue.clear()
	_current = 0
