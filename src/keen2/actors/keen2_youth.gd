class_name Keen2Youth
extends Keen2Enemy
## The Vorticon youth of Keen 2 (info value 2): small and very fast. It
## runs, starting in a random direction, turns around at walls and hops now
## and then, small or big at random. It runs off ledges.
##
## Running into Keen does not kill him: it stuns him ([method
## Keen2Body.stun]). One shot kills it; it fries for a moment (frame 56) and
## slides on, slower and slower, as a corpse (frame 57).

const SPRITE_RUN_LEFT := 48
const SPRITE_RUN_RIGHT := 52
const RUN_FRAMES := 4
const SPRITE_FRYING := 56
const SPRITE_DEAD := 57
## The collision box inside the sprite: the box of the left-running frames
## in EGAHEAD.CK2's sprite table. The right-running frames carry Keen 1's
## Yorp box (4, 4, 8, 20), most likely left over; one box for both ways
## also keeps a youth that turns at a wall out of it. estimate: whether the
## original uses the other box when it runs right.
const BODY_BOX := Rect2(1, 6, 14, 18)  # estimate

const HEALTH := 1  # estimate
const RUN_SPEED := 77 * Keen2Enemy.SUBPIXEL  # estimate
const RUN_FRAME_TICKS := 7  # estimate
## Chance per tick of a hop on the ground, and of a hop when it turns at a
## wall (n + 1 in 1000).
const HOP_CHANCE := 100  # estimate
const WALL_HOP_CHANCE := 200  # estimate
const SMALL_HOP_SPEED := 80 * Keen2Enemy.SUBPIXEL  # estimate
const BIG_HOP_SPEED := 200 * Keen2Enemy.SUBPIXEL  # estimate
## Shot: frying frame first, then the corpse slides on and slows down.
const FRY_TICKS := 21  # estimate
const DEATH_SLIDE_SPEED := 20 * Keen2Enemy.SUBPIXEL  # estimate
const DEATH_SLIDE_SLOWDOWN := 1 * Keen2Enemy.SUBPIXEL  # estimate
const DEATH_SLIDE_SLOWDOWN_TICKS := 11  # estimate

var _slide_speed := 0.0


## A youth at [param start] that sets off towards [param direction] (1
## right, -1 left).
static func create(start: Vector2, direction: int) -> Keen2Youth:
	var youth := Keen2Youth.new()
	youth.position = start
	youth.body_box = BODY_BOX
	youth.health = HEALTH
	youth.facing = direction
	return youth


func sprite_index() -> int:
	if is_dead:
		return SPRITE_DEAD if _timer >= FRY_TICKS else SPRITE_FRYING
	var run_sprite := SPRITE_RUN_RIGHT if facing > 0 else SPRITE_RUN_LEFT
	return run_sprite + (_timer / RUN_FRAME_TICKS) % RUN_FRAMES


func die() -> void:
	if is_dead:
		return
	super.die()
	_timer = 0
	_slide_speed = DEATH_SLIDE_SPEED


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


## Stuns [param keen] instead of killing him; he faces the way the youth
## runs. A stunned Keen is left alone until he is up again.
func touch_keen(_session: LevelSession, keen: KeenBody) -> void:
	var body := keen as Keen2Body
	if body != null and not body.is_stunned():
		body.stun(facing)


func _think(session: LevelSession) -> void:
	_fall(session)
	_timer += 1
	if is_dead:
		_slide(session)
		return
	if on_ground and roll(session, HOP_CHANCE):
		_hop(session)
	if not _walk(session, RUN_SPEED):
		facing = -facing
		if on_ground and roll(session, WALL_HOP_CHANCE):
			_hop(session)


## A small or a big hop, at random.
func _hop(session: LevelSession) -> void:
	_jump(BIG_HOP_SPEED if session.rng.randi_range(0, 1) == 0 else SMALL_HOP_SPEED)


func _slide(session: LevelSession) -> void:
	if _slide_speed <= 0.0:
		return
	if not _walk(session, _slide_speed):
		_slide_speed = 0.0
	elif _timer % DEATH_SLIDE_SLOWDOWN_TICKS == 0:
		_slide_speed = maxf(0.0, _slide_speed - DEATH_SLIDE_SLOWDOWN)
