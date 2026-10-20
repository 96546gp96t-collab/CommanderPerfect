class_name Keen3Youth
extends Keen3Enemy
## The Vorticon youth of Keen 3 (info value 2), as Chocolate Keen has it: it
## runs toward Keen as it starts, very fast; every tick a chance of 3 to hop
## (up to [constant MAX_HOP_SPEED]). It turns round at a wall and falls off
## ledges; in the air it shows its fourth running frame.
##
## Running into Keen does not kill him: it stuns him, and he slides on with
## the youth's speed ([method Keen3Body.stun_with]); the ankh prevents it.
## Only Keen's shots kill it (one is enough), not the enemies' shots.

const SPRITE_RUN_LEFT := 47
const SPRITE_RUN_RIGHT := 51
const RUN_FRAMES := 4
## In the air: YOUTHLEFT4 and YOUTHRIGHT4 (Choco).
const AIR_FRAME := 3
const SPRITE_DYING := 55
## The collision box of the left-running frames (1, 6, 14, 23) in
## EGAHEAD.CK3. The right-running frames carry Keen 1's Yorp box, as in Keen
## 2; one box for both ways keeps a youth that turns at a wall out of it.
## estimate: the original uses the other box when it runs right.
const BODY_BOX := Rect2(1, 6, 14, 18)  # estimate

const HEALTH := 1  # (Choco)
## 250 (Choco).
const RUN_SPEED := 76 * Keen2Enemy.SUBPIXEL
const HOP_CHANCE := 3  # (Choco)
## A hop of at most 400 (Choco).
const MAX_HOP_SPEED := 222 * Keen2Enemy.SUBPIXEL


## A youth at [param start] that sets off toward [param direction] (1
## right, -1 left).
static func spawned(start: Vector2, direction: int) -> Keen3Youth:
	var youth := Keen3Youth.new()
	youth.position = start
	youth.body_box = BODY_BOX
	youth.health = HEALTH
	youth.facing = direction
	youth.first_dying_sprite = SPRITE_DYING
	return youth


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


## Stuns [param keen]; he takes the youth's speed.
func touch_keen(_session: LevelSession, keen: KeenBody) -> void:
	var body := keen as Keen3Body
	if body != null:
		body.stun_with(Vector2(facing * RUN_SPEED, velocity.y))


func _living_sprite() -> int:
	var first := SPRITE_RUN_RIGHT if facing > 0 else SPRITE_RUN_LEFT
	if not on_ground:
		return first + AIR_FRAME
	return first + frame_after(_age, WALK_FRAME_TICKS, RUN_FRAMES)


func _think(session: LevelSession) -> void:
	if on_ground and chance(session, HOP_CHANCE):
		_jump(_random_up_to(session, MAX_HOP_SPEED))
	_fall(session)
	if not _walk(session, RUN_SPEED):
		facing = -facing
