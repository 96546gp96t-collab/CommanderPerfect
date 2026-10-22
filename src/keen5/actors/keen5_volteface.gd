class_name Keen5Volteface
extends Keen5Creature
## The Volteface of Keen 5 (Omni `ck5_obj1.c`, facts and numbers only;
## docs/keen5/research.md §7): always awake and never clipped, it follows
## the path arrows of the info plane ([GalaxyPathArrows]) at 32 units a tic,
## four pictures of 6 tics. Where it starts, the arrow beside it that
## points away from it gives its way (left of it pointing right, right of
## it pointing left, above it pointing down, below it pointing up, in that
## order), and it writes that arrow into its own tile. Touching it kills
## Keen. A shot stuns it for 300 tics, harmless meanwhile; then it moves on.
## It cannot be killed.

## (Omni CK5_ACT_Volte*.)
const ROWS: PackedStringArray = [
	"move_1 VOLTEFACE1 VOLTEFACE1 step+ -- 6 0 0 move volteface - move_2",
	"move_2 VOLTEFACE2 VOLTEFACE2 step+ -- 6 0 0 move volteface - move_3",
	"move_3 VOLTEFACE3 VOLTEFACE3 step+ -- 6 0 0 move volteface - move_4",
	"move_4 VOLTEFACE4 VOLTEFACE4 step+ -- 6 0 0 move volteface - move_1",
	"stunned VOLTEFACESTUN VOLTEFACESTUN step -- 300 0 0 - - - move_1",
]
const PRIORITY := 2
## Units a tic (Omni CK5_VolteSpeed).
const SPEED := 32
## Where it looks for its first arrow, and which arrow (0 up, 1 right,
## 2 down, 3 left) must lie there: the way it then goes (Omni).
const FIRST_LOOKS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)
]
const FIRST_ARROWS: PackedInt32Array = [1, 3, 2, 0]

var path: GalaxyPathArrows


## A Volteface at [param cell] (info 71, 72, 73).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Volteface:
	var volte := Keen5Volteface.new()
	volte.priority = PRIORITY
	volte.activity = Activity.ALWAYS
	volte.clip = Clip.NONE
	volte.place(world, cell, Vector2i.ZERO, ROWS, sprites, &"move_1")
	var first := _first_arrow(world, cell)
	if first < 0:
		push_error("A Volteface at %s has no arrow beside it." % cell)
		first = 0
	volte.path = GalaxyPathArrows.start_at(world, cell, first)
	return volte


## The way of the first arrow beside [param cell] that points away from it,
## or -1 (Omni CK5_SpawnVolte).
static func _first_arrow(world: GalaxyWorld, cell: Vector2i) -> int:
	for index in FIRST_LOOKS.size():
		var look := cell + FIRST_LOOKS[index]
		var arrow := GalaxyPathArrows.arrow_of(world.info_at(look.x, look.y))
		if arrow == FIRST_ARROWS[index]:
			return arrow
	return -1


## Think: along the arrows (Omni CK5_VolteMove).
func _think_move() -> void:
	path.advance(self, SPEED)


## Contact: Keen dies; a shot stuns it a while (Omni CK5_VolteCol).
func _contact_volteface(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
		return
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
		_become(&"stunned")
