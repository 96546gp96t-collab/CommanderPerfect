class_name Keen4Bounder
extends GalaxyCreature
## The Bounder of Keen 4 (Omni `ck4_obj2.c`, `ck_keen.c`, facts and
## numbers only; docs/keen4/research.md §7): a ball that bounces (−50 from
## every landing, gravity high). It bounces in place three times; after
## that every other bounce goes left (100 in 256), right (100 in 256) or
## straight up, 24 sideways; a wall turns it.
##   - It never hurts Keen: it pushes him out of its way, and he can land on
##     it and ride it. While he rides, it goes where he stands: left of its
##     box (more than 64 units) left, right of it right, otherwise up.
##   - Touching Keen on a pole or a ledge knocks him off.
##   - A shot stuns it for good (it hops −32, stars over it); a stunned
##     Bounder is a platform Keen can stand on.

## (Omni CK4_ACT_Bounder*.)
const ROWS: PackedStringArray = [
	"bounce_1 BOUNDER_FACE_1 BOUNDER_FACE_1 step+ -- 20 0 0 fall bounder bounce bounce_2",
	"bounce_2 BOUNDER_FACE_2 BOUNDER_FACE_2 step+ -- 20 0 0 fall bounder bounce bounce_1",
	"move_1 BOUNDER_L_1 BOUNDER_R_1 step+ -- 20 0 0 fall bounder bounce move_2",
	"move_2 BOUNDER_L_2 BOUNDER_R_2 step+ -- 20 0 0 fall bounder bounce move_1",
	"stunned_1 BOUNDER_FACE_1 BOUNDER_FACE_1 think -- 0 0 0 fall - stunned stunned_2",
	"stunned_2 BOUNDER_STUN BOUNDER_STUN think -- 0 0 0 fall - stunned -",
]
const RISE := 0x80
const PRIORITY := 0
const BOUNCE_SPEED := -50
const SIDEWAYS_SPEED := 24
## Bounces in place before it may go sideways (Omni).
const STRAIGHT_BOUNCES := 2
## Below these random numbers (of 256) it goes left, right (Omni).
const LEFT_CHANCE := 100
const RIGHT_CHANCE := 200
## Keen beyond its box by more than this steers it (Omni).
const STEER_MARGIN := 0x40
const SHOT_HOP := -32
const STARS := Vector2i(0x40, -0x80)

## Bounces since Keen last rode it (Omni user2), and whether the last
## bounce went straight up, so this one may turn (Omni user1).
var bounces := 0
var may_turn := false


## A Bounder at [param cell] (info 12).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Bounder:
	var bounder := Keen4Bounder.new()
	bounder.priority = PRIORITY
	bounder.direction = Vector2i(0, 1)
	bounder.stars_offset = STARS
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	bounder.enter(world, at, ROWS, sprites, &"bounce_1")
	return bounder


## Keen touches it: a living Bounder pushes him (off a pole or ledge too),
## a stunned one carries him (Omni CK_KeenColFunc, CK_KeenSpecialColFunc).
func touched_by_player(player: GalaxyObject, holding: bool) -> void:
	var keen := player as GalaxyKeenBody
	if keen == null:
		return
	if stunned:
		if not holding and keen.platform == null:
			keen.land_on(self)
	elif holding:
		keen.knock_off(self)
	else:
		keen.push_out(self)


## Contact: a shot stuns it (Omni CK4_BounderCheckShot).
func _contact_bounder(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot == null:
		return
	shot.hit()
	_become(&"stunned_1")
	stunned = true
	velocity.y += SHOT_HOP


## React: it bounces from the floor, steered by Keen or at random; walls
## turn it (Omni CK4_BounderDraw).
func _react_bounce() -> void:
	if bottom_hit != 0:
		velocity.y = 0
	if top_hit != 0:
		_bounce()
	if left_hit != 0 or right_hit != 0:
		direction.x = -direction.x
		velocity.x = -velocity.x


func _bounce() -> void:
	if world.on_screen(self):
		world.play_sound(&"mushroom_leap")
	bounces += 1
	velocity.y = BOUNCE_SPEED
	var keen := world.player() as GalaxyKeenBody
	if keen != null and keen.platform == self:
		bounces = 0
		if keen.box.left < box.left - STEER_MARGIN:
			direction.x = -1
		elif keen.box.right > box.right + STEER_MARGIN:
			direction.x = 1
		else:
			direction.x = 0
		velocity.x = direction.x * SIDEWAYS_SPEED
	elif bounces > STRAIGHT_BOUNCES and may_turn:
		may_turn = false
		var chance := world.random()
		if chance < LEFT_CHANCE:
			direction.x = -1
		elif chance < RIGHT_CHANCE:
			direction.x = 1
		else:
			direction.x = 0
		velocity.x = direction.x * SIDEWAYS_SPEED
	else:
		may_turn = true
		velocity.x = 0
		direction.x = 0
	_become(&"move_1" if direction.x != 0 else &"bounce_1")
