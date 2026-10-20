class_name Keen3Ninja
extends Keen3Enemy
## The Vorticon ninja of Keen 3 (info value 5), as Chocolate Keen has it:
##   STANDING  stands where it is (it does not fall) and always faces Keen.
##             When Keen is at most [constant SIGHT_HEIGHT] above or below
##             it, a chance of 3 every tick to jump at him: up with a random
##             speed up to [constant MAX_JUMP_SPEED], sideways at
##             [constant LEAP_SPEED] toward him
##   JUMPING   flies; stands again as soon as it lands
## Touching it kills Keen. It takes [constant HEALTH] shots from Keen; the
## enemies' shots do not hurt it.

enum Mode { STANDING, JUMPING }

const SPRITE_STAND_LEFT := 77
const SPRITE_STAND_RIGHT := 79
const STAND_FRAMES := 2
const SPRITE_JUMP_LEFT := 81
const SPRITE_JUMP_RIGHT := 82
const SPRITE_DYING := 83
## The collision box: NINJAL1's box (4, 4, 27, 31) in EGAHEAD.CK3.
const BODY_BOX := Rect2(4, 4, 24, 28)

## The original gives it 3 but counts a hit before it looks, so four shots
## are needed (Choco).
const HEALTH := 4
## Keen's sprite at most 5 tiles above or below its own (Choco).
const SIGHT_HEIGHT := 5 * Keen2Enemy.TILE
const JUMP_CHANCE := 3  # (Choco)
## A jump of at most 350, sideways 250 (Choco).
const MAX_JUMP_SPEED := 195 * Keen2Enemy.SUBPIXEL
const LEAP_SPEED := 76 * Keen2Enemy.SUBPIXEL

var mode := Mode.STANDING


## A ninja at [param start], first facing [param direction].
static func spawned(start: Vector2, direction: int) -> Keen3Ninja:
	var ninja := Keen3Ninja.new()
	ninja.position = start
	ninja.body_box = BODY_BOX
	ninja.health = HEALTH
	ninja.facing = direction
	ninja.first_dying_sprite = SPRITE_DYING
	return ninja


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


func _living_sprite() -> int:
	if mode == Mode.JUMPING:
		return SPRITE_JUMP_RIGHT if facing > 0 else SPRITE_JUMP_LEFT
	var first := SPRITE_STAND_RIGHT if facing > 0 else SPRITE_STAND_LEFT
	return first + frame_after(_age, SLOW_FRAME_TICKS, STAND_FRAMES)


func _think(session: LevelSession) -> void:
	if mode == Mode.JUMPING:
		_fall(session)
		_walk(session, LEAP_SPEED)
		if on_ground:
			mode = Mode.STANDING
		return
	var keen := session.nearest_keen(hitbox().get_center())
	facing = toward(position.x, keen.position.x)
	if absf(keen.position.y - position.y) > SIGHT_HEIGHT:
		return
	if chance(session, JUMP_CHANCE):
		_jump(_random_up_to(session, MAX_JUMP_SPEED))
		mode = Mode.JUMPING
