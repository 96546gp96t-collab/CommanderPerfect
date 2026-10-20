class_name Keen4Dopefish
extends Keen4Schoolfish
## The Dopefish of Keen 4's Well of Wishes (info 15, 87 from Normal, 88 on
## Hard; Omni `ck4_obj3.c`, CK4_SpawnDopefish, CK4_DopefishMove,
## CK4_DopefishCol, CK4_DopefishEat, CK4_DopefishBurp,
## CK4_DopefishAfterBurp, facts and numbers only; docs/keen4/research.md
## §7):
##   - it swims after Keen as a school fish does ([Keen4Schoolfish]: 1 on
##     odd tics, at most 10 a tic), with a box of 1408 × 1024 units, three
##     tiles above its info tile;
##   - touching a school fish or Keen (not in god mode) it eats it: it
##     stops clipping, faces it and swims 32 a tic until its mouth (32
##     units beyond the prey's box, a tile above the prey's position) is
##     there; Keen, held in its mouth, is gone and the level is lost 180
##     tics later; a school fish is gone at once;
##   - then it rests 60 tics, burps (a big bubble rises) and rests twice
##     60 tics more, swims back to where it began to eat and swims on;
##   - the stunner does nothing to it.

## (Omni CK4_ACT_DopefishSwim0-1, Eat0, Burp0-3.)
const DOPEFISH_ROWS: PackedStringArray = [
	"swim_1 DOPEFISH_L_1 DOPEFISH_R_1 step+ -- 20 0 0 move dopefish fish swim_2",
	"swim_2 DOPEFISH_L_2 DOPEFISH_R_2 step+ -- 20 0 0 move dopefish fish swim_1",
	"eat DOPEFISH_BITE_L DOPEFISH_BITE_R think -- 0 0 0 eat - - -",
	"burp_1 DOPEFISH_L_1 DOPEFISH_R_1 step -- 60 0 0 - - - burp_2",
	"burp_2 DOPEFISH_BURP_1 DOPEFISH_BURP_1 step -- 60 0 0 burp - - burp_3",
	"burp_3 DOPEFISH_BURP_2 DOPEFISH_BURP_2 step -- 60 0 0 - - - burp_4",
	"burp_4 DOPEFISH_L_1 DOPEFISH_R_1 think -- 0 0 0 swim_back - - swim_1",
]
const DOPEFISH_PRIORITY := 2
## It floats this far above its info tile's corner (Omni).
const RISE := 0x300
const DOPEFISH_BOX := Vector2i(0x580, 0x400)
## Eating (Omni): its speed, and where its mouth must be from the prey.
const EAT_SPEED := 32
const MOUTH_ABOVE := 0x100
const MOUTH_AHEAD := 0x20

## What it eats (Keen or a school fish), and where it began.
var prey: GalaxyObject
var eat_start := Vector2i.ZERO


## The Dopefish at [param cell] (info 15, 87, 88), facing a random way.
static func spawn_dopefish(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Dopefish:
	var fish := Keen4Dopefish.new()
	fish.priority = DOPEFISH_PRIORITY
	fish.clip = Clip.SIMPLE
	fish.simple_box_size = DOPEFISH_BOX
	fish.direction = Vector2i(random_side(world), 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	fish.enter(world, at, DOPEFISH_ROWS, sprites, &"swim_1")
	return fish


## Contact: it catches a school fish, or Keen (Omni CK4_DopefishCol).
func _contact_dopefish(other: GalaxyObject) -> void:
	var fish := other as Keen4Schoolfish
	var keen := other as Keen4SwimmingKeen
	if fish != null and not (fish is Keen4Dopefish):
		fish.be_caught()
	elif keen == null or not keen.be_eaten():
		return
	prey = other
	eat_start = position
	direction.x = -1 if other.box.middle < box.middle else 1
	_become(&"eat")
	clip = Clip.NONE


## Think: it swims to its prey's mouth place; there it eats (Omni
## CK4_DopefishEat).
func _think_eat() -> void:
	var target := Vector2i.ZERO
	target.y = prey.position.y - MOUTH_ABOVE - position.y
	if direction.x == 1:
		target.x = prey.box.right + MOUTH_AHEAD - box.right
	else:
		target.x = prey.box.left - MOUTH_AHEAD - box.left
	if _swim_to(target):
		var keen := prey as Keen4SwimmingKeen
		if keen != null:
			keen.be_swallowed()
		else:
			world.remove(prey)
		prey = null
		_continue_as(&"burp_1")


## Think: a big bubble (Omni CK4_DopefishBurp).
func _think_burp() -> void:
	Keen4Bubble.burp(world, self, sprites)


## Think: back to where it began to eat, then it swims on (Omni
## CK4_DopefishAfterBurp).
func _think_swim_back() -> void:
	if _swim_to(eat_start - position):
		action = action.next
		clip = Clip.SIMPLE


## Moves towards [param distance] (units) at the eating speed; returns
## whether it gets there in this frame.
func _swim_to(distance: Vector2i) -> bool:
	var most := world.tics * EAT_SPEED
	step = Vector2i(clampi(distance.x, -most, most), clampi(distance.y, -most, most))
	return step == distance
