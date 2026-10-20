class_name Keen4Lick
extends GalaxyCreature
## The Lick of Keen 4 (Omni `ck4_obj2.c`, facts and numbers only;
## docs/keen4/research.md §7): it hops after Keen under gravity high, a
## long hop (32 sideways, −32) when he is more than 3 tiles away, otherwise
## a short one (16, −16), resting 10 tics after landing and 10 before the
## next hop. When Keen is close in front (within a tile up or down, from
## 32 units behind to 384 ahead, 512 to the left) it breathes fire for
## 8 × 4 tics: only the flame kills, and only Keen in front of it. A shot
## stuns it for good (it hops −8).

## (Omni CK4_ACT_Lick*.)
const ROWS: PackedStringArray = [
	"hop_1 LICK_HOP_L_1 LICK_HOP_R_1 step -- 10 0 0 hop shot - hop_2",
	"hop_2 LICK_HOP_L_2 LICK_HOP_R_2 think -- 0 0 0 fall shot land hop_3",
	"hop_3 LICK_HOP_L_3 LICK_HOP_R_3 think -- 0 0 0 fall shot land -",
	"hop_4 LICK_HOP_L_4 LICK_HOP_R_4 step -- 10 0 0 - shot - hop_1",
	"flame_1 LICK_FLAME_L_1 LICK_FLAME_R_1 step p- 4 0 0 - flame - flame_2",
	"flame_2 LICK_FLAME_L_2 LICK_FLAME_R_2 step p- 4 0 0 - flame - flame_3",
	"flame_3 LICK_FLAME_L_3 LICK_FLAME_R_3 step p- 4 0 0 - flame - flame_4",
	"flame_4 LICK_FLAME_L_2 LICK_FLAME_R_2 step p- 4 0 0 - flame - flame_5",
	"flame_5 LICK_FLAME_L_1 LICK_FLAME_R_1 step p- 4 0 0 - flame - flame_6",
	"flame_6 LICK_FLAME_L_2 LICK_FLAME_R_2 step p- 4 0 0 - flame - flame_7",
	"flame_7 LICK_FLAME_L_3 LICK_FLAME_R_3 step p- 4 0 0 - flame - flame_8",
	"flame_8 LICK_FLAME_L_2 LICK_FLAME_R_2 step p- 4 0 0 - flame - hop_3",
	"stunned_1 LICK_STUN LICK_STUN think -- 0 0 0 fall - stunned stunned_2",
	"stunned_2 LICK_STUN LICK_STUN think -- 0 0 0 fall - stunned -",
]
const PRIORITY := 2
## It waits random / 64 frames before its first think (Omni).
const START_WAIT_DIVISOR := 64
## Within this up or down, and ahead (right / left), it breathes fire
## (Omni).
const FLAME_HEIGHT := 0x100
const FLAME_RIGHT := Vector2i(-0x20, 0x180)
const FLAME_LEFT := Vector2i(-0x200, 0x20)
## Farther than this it hops long (Omni).
const LONG_HOP_DISTANCE := 0x300
const LONG_HOP := Vector2i(32, -32)
const SHORT_HOP := Vector2i(16, -16)
## A stunned Lick hops this much less high than others (Omni).
const STUN_DROP := 16
const STARS := Vector2i(0, -0x80)


## A Lick at [param cell] (info 14, 47, 48).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Lick:
	var lick := Keen4Lick.new()
	lick.priority = PRIORITY
	lick.direction = Vector2i(random_side(world), 1)
	lick.think_delay = world.random() / START_WAIT_DIVISOR
	lick.stars_offset = STARS
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	lick.enter(world, at, ROWS, sprites, &"hop_3")
	return lick


## Think before a hop: fire when Keen is close in front, otherwise hop
## after him (Omni CK4_LickMove).
func _think_hop() -> void:
	var keen := world.player()
	direction.x = -1 if position.x > keen.position.x else 1
	var dx := keen.position.x - position.x
	var dy := keen.position.y - position.y
	var reach := FLAME_RIGHT if direction.x == 1 else FLAME_LEFT
	if absi(dy) <= FLAME_HEIGHT and dx > reach.x and dx < reach.y:
		world.play_sound(&"lick_flame")
		_become(&"flame_1")
		return
	var hop := LONG_HOP if absi(dx) > LONG_HOP_DISTANCE else SHORT_HOP
	velocity = Vector2i(direction.x * hop.x, hop.y)


## Contact while hopping: a shot stuns it (Omni CK4_LickCheckShot).
func _contact_shot(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		stun(shot, &"stunned_1")
		velocity.y += STUN_DROP


## Contact while breathing fire: Keen in front of it dies (Omni
## CK4_LickCol).
func _contact_flame(other: GalaxyObject) -> void:
	if is_player(other):
		var in_front := (
			(direction.x == 1 and other.position.x > position.x)
			or (direction.x == -1 and other.position.x < position.x)
		)
		if in_front:
			kill_player()
			return
	_contact_shot(other)


## React in the air: landing (Omni CK4_LickDraw).
func _react_land() -> void:
	if top_hit != 0:
		_become(&"hop_4")
