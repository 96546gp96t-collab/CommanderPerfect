class_name Keen4Berkeloid
extends GalaxyCreature
## The Berkeloid of Keen 4 (Omni `ck4_obj2.c`, facts and numbers only;
## docs/keen4/research.md §7): it floats 8 a tic along the ground, turning
## at walls and ledges, and bobs up and down (8 units a tic, between 0 and
## a tile above its place; only its picture moves). Now and then (8 in 256
## at each step, or 64 in 256 when Keen is ahead within a tile up or down)
## it throws a fireball: 12 frames of 6 tics, the ball leaves at the sixth.
## The fireball flies 48 sideways from −8 under gravity mid; on the ground
## it burns for 102 tics. Touching the Berkeloid or a fireball kills Keen;
## the stunner does nothing (the shot stops).

## (Omni CK4_ACT_Berkeloid*, CK4_ACT_Fireball*.)
const ROWS: PackedStringArray = [
	"move_1 BERKELOID_L_1 BERKELOID_R_1 slide -s 6 8 0 move berkeloid float move_2",
	"move_2 BERKELOID_L_2 BERKELOID_R_2 slide -s 6 8 0 move berkeloid float move_3",
	"move_3 BERKELOID_L_3 BERKELOID_R_3 slide -s 6 8 0 move berkeloid float move_4",
	"move_4 BERKELOID_L_4 BERKELOID_R_4 slide -s 6 8 0 move berkeloid float move_1",
	"throw_1 BERKELOID_THROW_L_1 BERKELOID_THROW_R_1 step -- 6 0 0 redraw berkeloid bob throw_2",
	"throw_2 BERKELOID_THROW_L_1 BERKELOID_THROW_R_1 step -- 6 0 0 redraw berkeloid bob throw_3",
	"throw_3 BERKELOID_THROW_L_1 BERKELOID_THROW_R_1 step -- 6 0 0 redraw berkeloid bob throw_4",
	"throw_4 BERKELOID_THROW_L_1 BERKELOID_THROW_R_1 step -- 6 0 0 redraw berkeloid bob throw_5",
	"throw_5 BERKELOID_THROW_L_1 BERKELOID_THROW_R_1 step -- 6 0 0 redraw berkeloid bob throw_6",
	"throw_6 BERKELOID_THROW_L_1 BERKELOID_THROW_R_1 step -- 6 0 0 throw berkeloid bob throw_7",
	"throw_7 BERKELOID_THROW_L_2 BERKELOID_THROW_R_2 step -- 6 0 0 redraw berkeloid bob throw_8",
	"throw_8 BERKELOID_THROW_L_2 BERKELOID_THROW_R_2 step -- 6 0 0 redraw berkeloid bob throw_9",
	"throw_9 BERKELOID_THROW_L_2 BERKELOID_THROW_R_2 step -- 6 0 0 redraw berkeloid bob throw_10",
	"throw_10 BERKELOID_THROW_L_2 BERKELOID_THROW_R_2 step -- 6 0 0 redraw berkeloid bob throw_11",
	"throw_11 BERKELOID_THROW_L_2 BERKELOID_THROW_R_2 step -- 6 0 0 redraw berkeloid bob throw_12",
	"throw_12 BERKELOID_THROW_L_2 BERKELOID_THROW_R_2 step -- 6 0 0 thrown berkeloid bob move_1",
	"ball_1 FIRE_1 FIRE_1 step+ -- 6 0 0 fall_mid lethal ball ball_2",
	"ball_2 FIRE_2 FIRE_2 step+ -- 6 0 0 fall_mid lethal ball ball_1",
	"burn_1 FIRE_1 FIRE_1 step -- 6 0 0 - berkeloid - burn_2",
	"burn_2 FIRE_BURST_1 FIRE_BURST_1 step -- 12 0 0 - berkeloid - burn_3",
	"burn_3 FIRE_BURST_2 FIRE_BURST_2 step -- 12 0 0 - berkeloid - burn_4",
	"burn_4 FIRE_BURST_1 FIRE_BURST_1 step -- 12 0 0 - berkeloid - burn_5",
	"burn_5 FIRE_BURST_2 FIRE_BURST_2 step -- 12 0 0 - berkeloid - burn_6",
	"burn_6 FIRE_1 FIRE_1 step -- 12 0 0 - berkeloid - burn_7",
	"burn_7 FIRE_2 FIRE_2 step -- 12 0 0 - berkeloid - burn_8",
	"burn_8 FIRE_1 FIRE_1 step -- 12 0 0 - berkeloid - burn_9",
	"burn_9 FIRE_2 FIRE_2 step -- 12 0 0 - berkeloid - -",
]
## It floats this far above the info tile's corner (Omni).
const RISE := 0x200
const PRIORITY := 2
## Chances in 256 (Omni): turning to Keen, throwing, aiming at Keen.
const TURN_CHANCE := 0x20
const THROW_CHANCE := 8
const AIM_CHANCE := 0x40
## It aims when Keen is within this up or down (Omni).
const AIM_HEIGHT := 0x100
## Bobbing: units a tic, and its highest place (Omni).
const BOB_SPEED := 8
const BOB_TOP := -0x100
## After a throw it waits this many frames before thinking (Omni).
const THROW_WAIT := 4
## The fireball: where it starts and how it flies (Omni).
const BALL_DROP := 0x80
const BALL_RIGHT := 0x200
const BALL_LEFT := -0x100
const BALL_SPEED := Vector2i(48, -8)

## Its picture's height above its place, and how it changes a tic (Omni
## user1, user2).
var bob := 0
var bob_speed := BOB_SPEED
## A fireball (it shares the class for its rows).
var is_fireball := false


## A Berkeloid at [param cell] (info 5, 49, 50).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Berkeloid:
	var berkeloid := Keen4Berkeloid.new()
	berkeloid.priority = PRIORITY
	berkeloid.direction = Vector2i(random_side(world), 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	berkeloid.enter(world, at, ROWS, sprites, &"move_1")
	return berkeloid


## Think while floating: it turns to Keen, throws now and then, and
## throws when he is ahead (Omni CK4_BerkeloidMove).
func _think_move() -> void:
	var keen := nearest_player()
	if world.random() < TURN_CHANCE:
		direction.x = -1 if keen.position.x < position.x else 1
	if world.random() < THROW_CHANCE:
		_continue_as(&"throw_1")
	elif world.random() < AIM_CHANCE:
		var dx := keen.position.x - position.x
		var dy := keen.position.y - position.y
		if absi(dy) <= AIM_HEIGHT and signi(dx) == direction.x:
			_continue_as(&"throw_1")
			# Only the aimed throw has its sound (Omni).
			world.play_sound(&"berkeloid_throw")


## Think: the fireball leaves its hand (Omni CK4_BerkeloidThrow).
func _think_throw() -> void:
	var ball := Keen4Berkeloid.new()
	ball.is_fireball = true
	ball.activity = Activity.ON_SCREEN_ONLY
	ball.priority = 0
	ball.direction = Vector2i(direction.x, 0)
	ball.velocity = Vector2i(BALL_SPEED.x * direction.x, BALL_SPEED.y)
	var offset := BALL_RIGHT if direction.x == 1 else BALL_LEFT
	ball.enter(world, position + Vector2i(offset, BALL_DROP), ROWS, sprites, &"ball_1")
	needs_react = true


func _think_thrown() -> void:
	think_delay = THROW_WAIT
	needs_react = true


## Contact (the Berkeloid and a burning fireball): a shot stops, Keen dies
## (Omni CK4_BerkeloidCol).
func _contact_berkeloid(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
	elif is_player(other):
		kill_player(other)


## React of a fireball in the air: walls stop it, the ground sets it
## burning (Omni CK4_FireballDraw).
func _react_ball() -> void:
	if right_hit != 0 or left_hit != 0:
		velocity.x = 0
	if top_hit != 0:
		world.play_sound(&"fireball_land")
		_become(&"burn_1")


## React while floating: it turns at walls and ledges, and bobs (Omni
## CK4_BerkeloidDraw).
func _react_float() -> void:
	if _wall_ahead():
		_turn_back(1)
	elif top_hit == 0:
		_turn_back(2)
	_react_bob()


## React: only its picture bobs up and down (Omni CK4_BerkeloidHover).
func _react_bob() -> void:
	bob += bob_speed * world.tics
	if bob > 0:
		bob = 0
		bob_speed = -BOB_SPEED
	elif bob < BOB_TOP:
		bob = BOB_TOP
		bob_speed = BOB_SPEED
	draw_offset.y = bob
