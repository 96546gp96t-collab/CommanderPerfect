class_name Keen4Mushroom
extends GalaxyCreature
## The Mad Mushroom of Keen 4 (Omni `ck4_obj1.c`, facts and numbers only;
## docs/keen4/research.md §7): it hops in place under gravity mid, always
## facing Keen: two hops of −40, then a leap of −68, and again. Touching it
## kills Keen; the stunner does nothing (the shot stops).

## (Omni CK4_ACT_Mushroom*.)
const ROWS: PackedStringArray = [
	"hop_1 MUSHROOM_L_1 MUSHROOM_R_1 step+ -- 8 0 0 hop mushroom hop hop_2",
	"hop_2 MUSHROOM_L_2 MUSHROOM_R_2 step+ -- 8 0 0 hop mushroom hop hop_1",
]
const RISE := 0xF1
const PRIORITY := 0
## Every third bounce is the high leap (Omni).
const HOPS_PER_LEAP := 3
const HOP_SPEED := -40
const LEAP_SPEED := -68

## Bounces since the last leap (Omni user1).
var hops := 0


## A mushroom at [param cell] (info 21).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Mushroom:
	var mushroom := Keen4Mushroom.new()
	mushroom.priority = PRIORITY
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	mushroom.enter(world, at, ROWS, sprites, &"hop_1")
	return mushroom


## Think: it faces Keen and falls (Omni CK4_MushroomMove).
func _think_hop() -> void:
	direction.x = side_of_player()
	GalaxyPhysics.gravity_mid(self)


## Contact: a shot stops; Keen dies (Omni CK4_MushroomCol).
func _contact_mushroom(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
	elif is_player(other):
		kill_player()


## React: a ceiling stops it; the floor bounces it (Omni CK4_MushroomDraw).
func _react_hop() -> void:
	if bottom_hit != 0:
		velocity.y = 0
	if top_hit == 0:
		return
	hops += 1
	if hops == HOPS_PER_LEAP:
		hops = 0
		velocity.y = LEAP_SPEED
		world.play_sound(&"mushroom_leap")
	else:
		world.play_sound(&"mushroom_hop")
		velocity.y = HOP_SPEED
