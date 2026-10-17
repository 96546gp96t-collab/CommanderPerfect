class_name Keen3Enemy
extends Keen2Enemy
## Base class of Keen 3's enemies. Their behaviour follows Chocolate Keen
## (a reconstruction of the original code), which differs from the
## Commander Genius rules that Keen 2's classes follow; that is why they are
## their own classes on top of [Keen2Enemy] (for its wall probes and jump
## speeds), not subclasses of Keen 2's grunt and youth.
##
## What they share (Choco):
##   waking     asleep until its cell comes near the view, asleep again
##              when it is far away ([Keen3ActiveArea]); a corpse is then
##              deleted. Asleep it neither moves nor touches anything.
##   chances    "chance k" is rolled once per original frame as a random
##              byte below 6k; per tick of ours that is [method chance]
##   falling    gravity 3 per clock tick, at most 200 (converted below)
##   dying      the first dying frame, the next one after [constant
##              DYING_FRAME_TICKS], and so on to the last, which stays as
##              the corpse; the corpse falls. No points for any of them.
##   shots      Keen's shots hit every living one; enemy shots only the
##              kinds that say so ([method hurt_by_enemy_shots])
## Each kind fills in [method _think] and [method _living_sprite].

## A chance of k comes up with this probability per tick, per k: the
## original rolls a byte below 6k once per frame of 6 clock ticks, and a
## frame is 0.405 of our ticks (docs/keen3/research.md, "Units").
const CHANCE_PER_K := 0.0095
## Gravity: 3 per clock tick, through the original's falling helper (Choco).
const KEEN3_GRAVITY := 4.05 * Keen2Enemy.SUBPIXEL
## The original's fastest fall, 200 (Choco).
const KEEN3_MAX_FALL := 111 * Keen2Enemy.SUBPIXEL
## Animation steps of 8, 16 and 32 clock ticks (Choco).
const FAST_FRAME_TICKS := 3.3
const WALK_FRAME_TICKS := 6.6
const SLOW_FRAME_TICKS := 13.2
## A dying enemy shows each dying frame this long: 40 clock ticks (Choco).
const DYING_FRAME_TICKS := 16.5
## A push moves Keen at most this far at once (Choco: 0xF00).
const MAX_PUSH := 15.0

## The first dying frame and how many there are; the last is the corpse.
var first_dying_sprite := -1
var dying_frames := 2
## Ticks awake, for the animations.
var _age := 0
## Ticks in the current mode.
var _mode_ticks := 0
var _dead_ticks := 0


## Whether a chance of [param k] (the original's "random byte < 6k per
## frame") comes up in this tick.
static func chance(session: LevelSession, k: int) -> bool:
	return session.rng.randf() < k * CHANCE_PER_K


## The animation frame (0 to [param count] - 1) after [param ticks], one
## frame every [param frame_ticks].
static func frame_after(ticks: float, frame_ticks: float, count: int) -> int:
	return floori(ticks / frame_ticks) % count


## The direction (1 right, -1 left) from [param from_x] to Keen's sprite at
## [param keen_x]; the original compares the left sides of the sprites.
static func toward(from_x: float, keen_x: float) -> int:
	return 1 if keen_x > from_x else -1


func step(session: LevelSession) -> void:
	var keen_3 := session as Keen3LevelSession
	if keen_3 == null:
		return
	if not is_active:
		if not keen_3.wakes_at(position):
			return
		is_active = true
		_wake(session)
	elif not keen_3.keeps_awake_at(position):
		is_active = false
		removed = is_dead
		return
	_age += 1
	_mode_ticks += 1
	if is_dead:
		_rot(session)
	else:
		_think(session)


func die() -> void:
	if not is_dead:
		_dead_ticks = 0
	super.die()


## Whether the enemies' shots (the mother's fireball, the wall guns' shots)
## kill this kind. Only the grunt and the Foob (Choco).
func hurt_by_enemy_shots() -> bool:
	return false


func sprite_index() -> int:
	if is_dead:
		var frame := mini(floori(_dead_ticks / DYING_FRAME_TICKS), dying_frames - 1)
		return first_dying_sprite + frame
	return _living_sprite()


## The sprite while it lives.
func _living_sprite() -> int:
	return -1


## Called when it wakes up; the Foob uses it.
func _wake(_session: LevelSession) -> void:
	pass


## A dying enemy and its corpse stand still and fall.
func _rot(session: LevelSession) -> void:
	_dead_ticks += 1
	velocity.x = 0.0
	_fall(session)


## Falls with Keen 3's gravity; lands on floors and bumps against ceilings.
func _fall(session: LevelSession) -> void:
	velocity.y = minf(velocity.y + KEEN3_GRAVITY, KEEN3_MAX_FALL)
	var moved := session.collision.sweep_y(hitbox(), velocity.y)
	position.y += moved
	on_ground = velocity.y > 0.0 and moved < velocity.y
	if moved != velocity.y:
		velocity.y = 0.0
	if session.collision.is_below_level(hitbox()):
		removed = true


## Whether no floor is under it at all.
func _floor_gone(session: LevelSession) -> bool:
	return session.collision.floor_under(hitbox()) == TileProperties.Floor.NONE


## Pushes [param keen] sideways out of this enemy, at most
## [constant MAX_PUSH] pixels, through the tiles (Choco: the mother and the
## Meep). The ankh does not stop it.
func _push_out(keen: KeenBody) -> void:
	var keen_box := keen.hitbox()
	var box := hitbox()
	var distance := box.end.x - keen_box.position.x
	if keen_box.get_center().x < box.get_center().x:
		distance = box.position.x - keen_box.end.x
	distance = clampf(distance, -MAX_PUSH, MAX_PUSH)
	keen.position.x += keen.collision.sweep_x(keen_box, distance)


## A speed from 0 to [param highest], as the original's random jumps.
static func _random_up_to(session: LevelSession, highest: float) -> float:
	return _random_speed(session, 0.0, highest)
