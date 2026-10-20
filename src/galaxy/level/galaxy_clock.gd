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
## A level's first frame covers this many tics (Omni CK_PlayLoop), so the
## frames after it start on odd tics: gravity and acceleration then act on
## the first tic of each frame (seen in the original: the jump, D4).
const LEVEL_START_TICS := 3

## Tics per logic frame.
var tics_per_frame := NORMAL_TICS
## The absolute tic at the end of the last logic frame.
var tic := 0
## Tics collected towards the next frame (may be fractional).
var _pending := 0.0
## Tics of the next frame when it differs from [member tics_per_frame].
var _next_frame_tics := 0


## Collects [param seconds] of real time; returns how many logic frames are
## due now. Call [method run_frame] once for each.
func advance(seconds: float) -> int:
	_pending = minf(_pending + seconds * TICS_PER_SECOND, float(MAX_TICS))
	var first := _frame_tics()
	if _pending < first:
		return 0
	return 1 + floori((_pending - first) / tics_per_frame)


## Takes one logic frame out of the collected time; returns the tics it
## covers ([member tic] is then the last of them).
func run_frame() -> int:
	var tics := _frame_tics()
	_next_frame_tics = 0
	_pending = maxf(_pending - tics, 0.0)
	tic += tics
	return tics


## How far the time is towards the next logic frame, from 0 to 1: how much
## of the way to draw between the last two frames (smooth motion).
func blend() -> float:
	return clampf(_pending / _frame_tics(), 0.0, 1.0)


## Starts counting again (a new map that is only shown).
func reset() -> void:
	tic = 0
	_pending = 0.0
	_next_frame_tics = 0


## Starts counting for a level that is played: its first frame covers
## [constant LEVEL_START_TICS] tics (Omni).
func start_level() -> void:
	reset()
	_next_frame_tics = LEVEL_START_TICS


## Goes on after a level was played to absolute tic [param at] at once
## (a loaded game): the next frame is an ordinary one.
func resume_at(at: int) -> void:
	reset()
	tic = at


func _frame_tics() -> int:
	return _next_frame_tics if _next_frame_tics > 0 else tics_per_frame
