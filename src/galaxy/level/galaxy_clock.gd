class_name GalaxyClock
extends RefCounted
## The Galaxy engine's clock: real time counted in tics of 1/70 s, handed
## out as logic frames of [member tics_per_frame] tics (2 on any machine
## that is fast enough, as the original runs: 35 frames per second; 3 in
## demos). Gravity and acceleration later act on odd tics, so a frame knows
## the absolute tic numbers it covers ([member tic]).
##
## When the game falls behind (a slow frame, a window being dragged) the
## original slows down instead of skipping: a frame never covers more than
## [constant MAX_TICS] tics. Here the time that piles up beyond that is
## dropped, so the game slows down the same way. See
## docs/keen4/research.md §2 and docs/keen4/architecture.md, "Time".

const TICS_PER_SECOND := 70
## Tics per logic frame on a fast machine (Omni MINTICS).
const NORMAL_TICS := 2
## Tics per logic frame in demos (Omni).
const DEMO_TICS := 3
## The most tics one frame may cover (Omni MAXTICS); more time is dropped.
const MAX_TICS := 5

## Tics per logic frame.
var tics_per_frame := NORMAL_TICS
## The absolute tic at the end of the last logic frame.
var tic := 0
## Tics collected towards the next frame (may be fractional).
var _pending := 0.0


## Collects [param seconds] of real time; returns how many logic frames are
## due now. Call [method run_frame] once for each.
func advance(seconds: float) -> int:
	_pending = minf(_pending + seconds * TICS_PER_SECOND, float(MAX_TICS))
	return floori(_pending / tics_per_frame)


## Takes one logic frame out of the collected time; returns the tics it
## covers ([member tic] is then the last of them).
func run_frame() -> int:
	_pending = maxf(_pending - tics_per_frame, 0.0)
	tic += tics_per_frame
	return tics_per_frame


## How far the time is towards the next logic frame, from 0 to 1: how much
## of the way to draw between the last two frames (smooth motion).
func blend() -> float:
	return clampf(_pending / tics_per_frame, 0.0, 1.0)


## Starts counting again (a new level).
func reset() -> void:
	tic = 0
	_pending = 0.0
