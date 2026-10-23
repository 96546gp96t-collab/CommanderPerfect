class_name GalaxyShrapnel
extends GalaxyCreature
## A piece that flies off an explosion and bounces until it is spent (Omni
## `ck_misc.c:CK_ShrapnelTileCol`, facts and numbers only; Keen 5's Shelley
## and mine pieces, Keen 6 later): it falls with gravity high and its own
## sideways speed ([method GalaxyObject._think_fall]); a wall sends it back
## at half its speed, a ceiling down at half its speed; a floor or slope
## bounces it off at the angle the slope gives, with half the energy it
## had. Once its energy is below [constant SPENT] it goes on with its next
## action, or, without one, is drawn once more and gone the next frame.
## The episode gives the rows: think [code]fall[/code], react
## [code]shrapnel[/code], and its own contact.

## How it moves on after a bounce (Omni bouncearray): a row per slope value
## of the floor (0-7: nothing, flat, gentle and steep slopes), a column per
## angle it came in at (0 flat … 3 steep, mirrored to 4-7 moving right):
## one of 16 ways ([method _leave_by]).
const LEAVE_BY: PackedInt32Array = [
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	7,
	6,
	5,
	4,
	3,
	2,
	1,
	0,
	5,
	4,
	3,
	2,
	1,
	0,
	15,
	14,
	5,
	4,
	3,
	2,
	1,
	0,
	15,
	14,
	3,
	2,
	1,
	0,
	15,
	14,
	13,
	12,
	9,
	8,
	7,
	6,
	5,
	4,
	3,
	2,
	9,
	8,
	7,
	6,
	5,
	4,
	3,
	2,
	11,
	10,
	9,
	8,
	7,
	6,
	5,
	4,
]
## The angles per slope in [constant LEAVE_BY] (one row each).
const ANGLES := 8
## The energy of a speed by its angle: × 256 straight, × 286 at about
## 27 degrees (2 : 1), × 362 at 45 degrees (Omni).
const STRAIGHT := 256
const SHALLOW := 286
const DIAGONAL := 362
## Below this energy (after halving) it is spent (Omni).
const SPENT := 0x1000
## The angles it comes in at: flat, shallow, steep-ish, steep; mirrored
## around this when it moves right.
const MIRROR := 7
const FLAT_IN := 0
const SHALLOW_IN := 1
const STEEP_SHALLOW_IN := 2
const STEEP_IN := 3


## React: walls and ceilings turn it back at half speed, a floor bounces it
## off by its slope and halves its energy; spent, it ends (Omni
## CK_ShrapnelTileCol).
func _react_shrapnel() -> void:
	if left_hit != 0 or right_hit != 0:
		velocity.x = -velocity.x / 2
	if bottom_hit != 0:
		velocity.y = -velocity.y / 2
		return
	var slope := top_hit & SLOPE_MASK
	if slope == 0:
		return
	velocity.y = maxi(velocity.y, 0)
	var speed_x := absi(velocity.x)
	var angle := FLAT_IN
	var energy := 0
	if speed_x > velocity.y:
		if speed_x > velocity.y * 2:
			energy = speed_x * SHALLOW
		else:
			angle = SHALLOW_IN
			energy = speed_x * DIAGONAL
	elif velocity.y > speed_x * 2:
		angle = STEEP_IN
		energy = velocity.y * STRAIGHT
	else:
		angle = STEEP_SHALLOW_IN
		energy = velocity.y * SHALLOW
	if velocity.x > 0:
		angle = MIRROR - angle
	energy /= 2
	_leave_by(LEAVE_BY[slope * ANGLES + angle], energy)
	if energy < SPENT:
		if action.next != null:
			set_action(action.next)
		else:
			# Without a next action the original starts none: the piece is
			# still drawn where it is now and is gone the next frame (seen in
			# Keen 5's high-score demo, E7). The world removes an object
			# without an action when it would run.
			action = null


## Its new speed after a bounce: one of 16 ways ([constant LEAVE_BY]) with
## [param energy] (Omni).
func _leave_by(way: int, energy: int) -> void:
	match way:
		0:
			velocity.x = energy / SHALLOW
			velocity.y = -velocity.x / 2
		1:
			velocity.x = energy / DIAGONAL
			velocity.y = -velocity.x
		2:
			velocity.y = -(energy / SHALLOW)
			velocity.x = -velocity.y / 2
		3, 4, 11, 12:
			velocity.x = 0
			velocity.y = -(energy / STRAIGHT)
		5:
			velocity.y = -(energy / SHALLOW)
			velocity.x = velocity.y / 2
		6:
			velocity.y = -(energy / DIAGONAL)
			velocity.x = velocity.y
		7:
			velocity.x = -(energy / SHALLOW)
			velocity.y = velocity.x / 2
		8:
			velocity.x = -(energy / SHALLOW)
			velocity.y = -velocity.x / 2
		9:
			velocity.x = -(energy / DIAGONAL)
			velocity.y = -velocity.x
		10:
			velocity.y = energy / SHALLOW
			velocity.x = -velocity.y / 2
		13:
			velocity.y = energy / SHALLOW
			velocity.x = velocity.y / 2
		14:
			velocity.x = energy / DIAGONAL
			velocity.y = energy / DIAGONAL
		15:
			velocity.x = energy / STRAIGHT
			velocity.y = velocity.x / 2
