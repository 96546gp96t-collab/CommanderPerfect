class_name GalaxyCreature
extends GalaxyObject
## The base of the creatures of a Galaxy level and the things they leave
## (slime, fireballs, darts, shell bits): what the original's object code
## shares between them (Omni `ck_obj.c`, `ck_misc.c`, facts and numbers
## only; docs/keen4/research.md §7):
##   - each creature keeps its own action table, made from rows
##     ([GalaxyAction.table_from]) with the episode's sprites;
##   - the **stun** (Omni CK_StunCreature): the shot stops, the creature
##     switches to its stunned action and hops (its vertical speed −24, at
##     most −48 upwards); from then on it counts as stunned ([member
##     stunned]: what checks for the living creature no longer sees it);
##   - the **stars** over a stunned creature (Omni CK_BasicDrawFunc4): three
##     frames of 10 tics, in front of everything, at an offset per kind
##     ([member stars_offset]); the stunned action ends when it lands;
##   - walking and turning at walls and ledges (Omni CK_BasicDrawFunc2 and
##     3): it steps back, turns, and waits a random 0-7 frames before it
##     thinks again;
##   - falling with gravity high or mid, gliding, and killing the player
##     on contact ([method GalaxyObject._contact_lethal]).
## Sprite names the stars use: STARS_1..3.

## The stun hop (Omni).
const STUN_HOP := -24
const STUN_HOP_LIMIT := -48
## The stars: three frames, each 10 tics, drawn in front (Omni).
const STAR_FRAMES := 3
const STAR_TICS := 10
const STAR_PRIORITY := 3
const STAR_SPRITES: Array[StringName] = [&"STARS_1", &"STARS_2", &"STARS_3"]
## Half the random range: a coin toss (Omni US_RndT() < 0x80).
const HALF_RANDOM := 0x80
## After turning it waits random / 32 frames before thinking (Omni).
const TURN_WAIT_DIVISOR := 32
## A floor side above this is no plain floor or slope (deadly, a platform).
const SLOPE_MASK := 7

## Its actions by name (the table holds the actions; they only hold each
## other weakly).
var actions: Dictionary[StringName, GalaxyAction] = {}
## The episode's sprites by name.
var sprites: Dictionary[StringName, int] = {}
## Hit by the stunner (Omni type StunnedCreature).
var stunned := false
## Where its stars are drawn, from its position, in units.
var stars_offset := Vector2i.ZERO
var _star_tics := 0
var _star_frame := 0


## Puts it in [param world] at [param at] (units) with the actions of
## [param rows] and [param episode_sprites], running action [param first]
## (Omni CK_SetAction). Its facing must be set before.
func enter(
	world: GalaxyWorld,
	at: Vector2i,
	rows: PackedStringArray,
	episode_sprites: Dictionary[StringName, int],
	first: StringName
) -> void:
	sprites = episode_sprites
	actions = GalaxyAction.table_from(rows, episode_sprites)
	position = at
	world.add(self)
	start(actions[first])


## The stunner shot [param shot] stuns it: the shot stops, it switches to
## action [param stunned_action] and hops (Omni CK_StunCreature).
func stun(shot: GalaxyStunnerShot, stunned_action: StringName) -> void:
	shot.hit()
	_star_tics = 0
	_star_frame = 0
	_become(stunned_action)
	stunned = true
	velocity.y = maxi(velocity.y + STUN_HOP, STUN_HOP_LIMIT)


## [param other] as a stunner shot that still flies, or null.
static func live_shot(other: GalaxyObject) -> GalaxyStunnerShot:
	var shot := other as GalaxyStunnerShot
	return shot if shot != null and not shot.spent else null


## Whether [param other] is the player.
func is_player(other: GalaxyObject) -> bool:
	return other == world.player()


## Kills the player (Omni CK_KillKeen).
func kill_player() -> void:
	_contact_lethal(world.player())


## 1 when the player is to its right, otherwise -1.
func side_of_player() -> int:
	return 1 if position.x < world.player().position.x else -1


## Right (1) or left (-1), by a coin toss of [param world]'s random table.
static func random_side(world: GalaxyWorld) -> int:
	return 1 if world.random() < HALF_RANDOM else -1


## Switches to action [param name] at once (Omni CK_SetAction2).
func _become(name: StringName) -> void:
	set_action(actions[name])


## Continues with action [param name] (Omni: currentAction = ...).
func _continue_as(name: StringName) -> void:
	action = actions[name]


## Steps back [param steps] times its last move, turns around and waits a
## little before thinking again (Omni CK_BasicDrawFunc2).
func _turn_back(steps: int) -> void:
	position.x -= moved.x * steps
	direction.x = -direction.x
	think_delay = world.random() / TURN_WAIT_DIVISOR
	set_action(action)


## Whether a wall stops it in the way it faces.
func _wall_ahead() -> bool:
	return (direction.x == 1 and left_hit != 0) or (direction.x == -1 and right_hit != 0)


## React: walking, it turns at walls and ledges (Omni CK_BasicDrawFunc2).
func _react_walk() -> void:
	if _wall_ahead() or top_hit == 0:
		_turn_back(1)


## React: as [method _react_walk], but it also turns before deadly floors
## and platforms, stepping back twice as far (Omni CK_BasicDrawFunc3).
func _react_crawl() -> void:
	if _wall_ahead():
		_turn_back(1)
	elif top_hit == 0 or top_hit & ~SLOPE_MASK != 0:
		_turn_back(2)


## React while stunned: walls and ceilings stop it, landing ends the action
## (to the next, when there is one); the stars turn (Omni
## CK_BasicDrawFunc4).
func _react_stunned() -> void:
	if left_hit != 0 or right_hit != 0:
		velocity.x = 0
	if bottom_hit != 0:
		velocity.y = 0
	if top_hit != 0:
		velocity = Vector2i.ZERO
		if action.next != null:
			set_action(action.next)
	_star_tics += world.tics
	if _star_tics > STAR_TICS:
		_star_tics -= STAR_TICS
		_star_frame = (_star_frame + 1) % STAR_FRAMES
	if overlays.is_empty():
		overlays.append(Overlay.new())
	var stars := overlays[0]
	stars.sprite = sprites.get(STAR_SPRITES[_star_frame], NO_SPRITE)
	stars.offset = stars_offset
	stars.priority = STAR_PRIORITY


## Think: gravity mid and its own horizontal velocity (Omni CK_Fall2).
func _think_fall_mid() -> void:
	GalaxyPhysics.gravity_mid(self)
	step.x = velocity.x * world.tics


## Think: it moves by its velocity (Omni CK_Glide).
func _think_glide() -> void:
	step = velocity * world.tics


## Think: it is drawn again (Omni CK_SetDraw).
func _think_redraw() -> void:
	needs_react = true
