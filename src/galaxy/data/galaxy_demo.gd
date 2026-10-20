class_name GalaxyDemo
extends RefCounted
## A recorded demo of a Galaxy episode (EGAGRAPH's demo chunks): a 16-bit
## map number, a 16-bit length in bytes, then the input as pairs of bytes:
## how many logic frames it is held, and what is held (Omni `id_in.c`:
## IN_ReadControls; facts only):
##   - bits 0-1: up/down + 1 (0 up, 1 neither, 2 down);
##   - bits 2-3: left/right + 1;
##   - bit 4: jump, bit 5: pogo (there is no fire bit: demos fire with
##     both buttons, [GalaxyTwoButtonFiring]).
## The demo is played one pair after the other, one logic frame per frame
## counted; it ends after the frame that uses up the last pair.

const HEADER_SIZE := 4
const PAIR_SIZE := 2
const AXIS_MASK := 3
const X_SHIFT := 2
const JUMP_BIT := 0x10
const POGO_BIT := 0x20

## The map the demo is played on.
var map_number := 0
## Per pair: how many frames, and the input byte.
var counts := PackedInt32Array()
var inputs := PackedByteArray()
## Where each pair starts, in frames (for [method input_at]).
var _starts := PackedInt32Array()
var _frames := 0


## The demo in [param chunk]; null when it is too short for its header or
## its length.
static func parse(chunk: PackedByteArray) -> GalaxyDemo:
	if chunk.size() < HEADER_SIZE:
		push_error("A demo of %d bytes has no header." % chunk.size())
		return null
	var length := chunk.decode_u16(2)
	if chunk.size() < HEADER_SIZE + length:
		push_error("A demo says it holds %d bytes but has %d." % [length, chunk.size()])
		return null
	var demo := GalaxyDemo.new()
	demo.map_number = chunk.decode_u16(0)
	for pair in length / PAIR_SIZE:
		var at := HEADER_SIZE + pair * PAIR_SIZE
		demo._starts.append(demo._frames)
		demo.counts.append(chunk[at])
		demo.inputs.append(chunk[at + 1])
		demo._frames += chunk[at]
	return demo


## How many logic frames the demo plays.
func frame_count() -> int:
	return _frames


## The input byte held in frame [param frame] (counted from 0); -1 after
## the end.
func input_at(frame: int) -> int:
	if frame < 0 or frame >= _frames:
		return -1
	var low := 0
	var high := _starts.size() - 1
	while low < high:
		var middle := (low + high + 1) / 2
		if _starts[middle] <= frame:
			low = middle
		else:
			high = middle - 1
	return inputs[low]


## What is held in frame [param frame], as the buttons themselves: jump and
## pogo as recorded, no fire (two-button firing makes it).
func controls_at(frame: int) -> KeenInput:
	var byte := input_at(frame)
	if byte < 0:
		return KeenInput.new()
	var input := KeenInput.create(((byte >> X_SHIFT) & AXIS_MASK) - 1)
	input.vertical = (byte & AXIS_MASK) - 1
	input.jump = byte & JUMP_BIT != 0
	input.pogo = byte & POGO_BIT != 0
	return input
