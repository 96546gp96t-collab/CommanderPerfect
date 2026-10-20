class_name Keen4Mimrock
extends GalaxyCreature
## The Mimrock of Keen 4 (Omni `ck4_obj3.c`, facts and numbers only;
## docs/keen4/research.md §7): a rock that sits still (it looks every 20
## tics). When Keen is within 5 tiles up or down, more than 3 tiles away
## and faces away from it, it sneaks after him (64 units every 6 tics, six
## steps); still facing the way he faces and within 4 tiles, it leaps at
## him (20 sideways, −40, gravity mid) and bounces once (−20) where it
## lands. Only the leap kills Keen. Sneaking or leaping, a shot stuns it
## for good (it hops −16); sitting, it is just a rock.

## (Omni CK4_ACT_Mimrock*.)
const ROWS: PackedStringArray = [
	"sit MIMROCK_SIT MIMROCK_SIT step -s 20 0 0 wait - walk sit",
	"sneak_1 MIMROCK_SNEAK_L_1 MIMROCK_SNEAK_R_1 step -s 6 64 0 sneak mimrock walk sneak_2",
	"sneak_2 MIMROCK_SNEAK_L_2 MIMROCK_SNEAK_R_2 step -s 6 64 0 sneak mimrock walk sneak_3",
	"sneak_3 MIMROCK_SNEAK_L_3 MIMROCK_SNEAK_R_3 step -s 6 64 0 sneak mimrock walk sneak_4",
	"sneak_4 MIMROCK_SNEAK_L_4 MIMROCK_SNEAK_R_4 step -s 6 64 0 sneak mimrock walk sneak_5",
	"sneak_5 MIMROCK_SNEAK_L_1 MIMROCK_SNEAK_R_1 step -s 6 64 0 sneak mimrock walk sneak_6",
	"sneak_6 MIMROCK_SNEAK_L_2 MIMROCK_SNEAK_R_2 step -s 6 64 0 sneak mimrock walk sit",
	"leap_1 MIMROCK_BONK_L_1 MIMROCK_BONK_R_1 step+ -- 24 0 0 fall_mid leaping leap leap_2",
	"leap_2 MIMROCK_BONK_L_2 MIMROCK_BONK_R_2 step+ -- 10 0 0 fall_mid leaping leap leap_3",
	"leap_3 MIMROCK_BONK_L_3 MIMROCK_BONK_R_3 think -- 10 0 0 fall_mid leaping leap leap_2",
	"bounce MIMROCK_BONK_L_3 MIMROCK_BONK_R_3 think -- 10 0 0 fall mimrock bounce -",
	"stunned_1 MIMROCK_BONK_L_3 MIMROCK_BONK_L_3 think -- 12 0 0 fall - stunned stunned_2",
	"stunned_2 MIMROCK_STUN MIMROCK_STUN think -- 12 0 0 fall - stunned -",
]
const RISE := 0xD0
## In front of Keen (Omni PRIORITIES - 1).
const PRIORITY := 3
## Keen's feet within this of its own (Omni).
const SEE_HEIGHT := 0x500
## It sneaks when Keen is farther than this, leaps when closer than that.
const SNEAK_DISTANCE := 0x300
const LEAP_DISTANCE := 0x400
const LEAP := Vector2i(20, -40)
const BOUNCE := -20
const SHOT_HOP := -16


## A Mimrock at [param cell] (info 19).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Mimrock:
	var mimrock := Keen4Mimrock.new()
	mimrock.priority = PRIORITY
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	mimrock.enter(world, at, ROWS, sprites, &"sit")
	return mimrock


## Think while sitting: Keen looking away makes it sneak after him (Omni
## CK4_MimrockWait).
func _think_wait() -> void:
	var keen := world.player()
	if absi(box.bottom - keen.box.bottom) > SEE_HEIGHT:
		return
	if absi(position.x - keen.position.x) <= SNEAK_DISTANCE:
		return
	var away := -1 if keen.position.x < position.x else 1
	if keen.direction.x == away:
		direction.x = away
		_continue_as(&"sneak_1")


## Think while sneaking: close behind Keen it leaps; once he turns round it
## sits again (Omni CK4_MimrockCheckJump).
func _think_sneak() -> void:
	var keen := world.player()
	var near := absi(box.bottom - keen.box.bottom) <= SEE_HEIGHT
	if not near or direction.x != keen.direction.x:
		_continue_as(&"sit")
		return
	if absi(position.x - keen.position.x) < LEAP_DISTANCE:
		velocity = Vector2i(direction.x * LEAP.x, LEAP.y)
		step.y = velocity.y * world.tics
		_continue_as(&"leap_1")


## Contact while sneaking or bouncing: a shot stuns it (Omni
## CK4_MimrockCol).
func _contact_mimrock(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot == null:
		return
	shot.hit()
	_become(&"stunned_1")
	stunned = true
	velocity.y += SHOT_HOP


## Contact while leaping: Keen dies (Omni CK4_MimrockAirCol).
func _contact_leaping(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player()
	else:
		_contact_mimrock(other)


## React while leaping: landing it bounces (Omni CK4_MimrockJumpDraw).
func _react_leap() -> void:
	if top_hit != 0:
		world.play_sound(Keen4Sounds.MIMROCK_JUMP)
		velocity.y = BOUNCE
		_become(&"bounce")
	if left_hit != 0 or top_hit != 0:
		velocity.x = 0
	if top_hit != 0 or bottom_hit != 0:
		velocity.y = 0


## React after the bounce: landing it sits again (Omni
## CK4_MimrockBounceDraw).
func _react_bounce() -> void:
	if top_hit != 0:
		world.play_sound(Keen4Sounds.MIMROCK_JUMP)
		_become(&"sit")
	if left_hit != 0 or right_hit != 0:
		velocity.x = 0
	if top_hit != 0:
		velocity.y = 0
