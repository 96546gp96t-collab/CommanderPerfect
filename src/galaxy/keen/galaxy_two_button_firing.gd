class_name GalaxyTwoButtonFiring
extends RefCounted
## "Two-button firing": the original's way to fire with only the jump and
## pogo buttons, which its demos always use (Omni `ck_play.c`:
## CK_HandleInput; facts only):
##   - both buttons held: fire, and neither jump nor pogo;
##   - jump alone: jump;
##   - pogo alone counts only after it has been held more than
##     [constant POGO_DELAY_TICS] tics (so pressing both at once does not
##     pogo first); until then the pogo stays as it was the frame before;
##     let go of within that time, it pogoes for that one frame.
## [method convert] turns the buttons held in one logic frame into what
## Keen sees.

## Tics the pogo button must be held before it counts (Omni).
const POGO_DELAY_TICS := 8

var _pogo_tics := 0
var _pogo := false


## What Keen sees of [param held] (directions, jump and pogo as held) in a
## logic frame of [param tics] tics.
func convert(held: KeenInput, tics: int) -> KeenInput:
	var seen := KeenInput.create(held.direction)
	seen.vertical = held.vertical
	if held.jump and held.pogo:
		seen.fire = true
		_pogo = false
		return seen
	seen.jump = held.jump
	if held.pogo:
		if _pogo_tics <= POGO_DELAY_TICS:
			_pogo_tics += tics
		else:
			_pogo = true
	else:
		_pogo = _pogo_tics != 0
		_pogo_tics = 0
	seen.pogo = _pogo
	return seen
