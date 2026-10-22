class_name Keen5GoPlat
extends GalaxyPlatform
## A GoPlat of Keen 5: a platform that follows the path arrows of the info
## plane (Omni `ck_obj.c` CK_SpawnGoPlat, CK_GoPlatThink; `ck5_obj1.c`
## CK5_PurpleGoPlatThink; facts and numbers only; docs/keen5/research.md
## §7), two kinds:
##   - **red** (info 36-39: starting up, right, down, left): at its tile's
##     corner; at each tile it reads the arrow at its own position;
##   - **purple** (info 80-83): 0x40 units right of and below its tile's
##     corner, and it reads the arrow 0x40 units right of and below its
##     position, so in the same tile as the red one. Its second picture is
##     never shown (its actions' timer is 0, as the purple axis
##     platform's).
## Both are always awake and never clipped, and move 12 units a tic a
## whole tile at a time, diagonals too ([GalaxyPathArrows]). Its start
## arrow is written into its own tile while the level is scanned
## ([Keen5Creatures], E4); a switch can turn an arrow round
## ([Keen5Keen]). Keen rides it ([GalaxyPlatform.touched_by_player]).

## (Omni CK_ACT_GoPlat0, CK5_ACT_purpleGoPlat, 2.)
const ROWS: PackedStringArray = [
	"go PLATFORM PLATFORM think -- 0 0 0 go - - -",
	"purple_1 PURPLEPLAT1 PURPLEPLAT1 step+ -- 0 0 0 go - - purple_2",
	"purple_2 PURPLEPLAT2 PURPLEPLAT2 step+ -- 0 0 0 go - - purple_1",
]
## The purple one's place from its tile's corner, and where it reads the
## arrows from its position, x and y (Omni).
const PURPLE_OFFSET := 0x40

var path: GalaxyPathArrows
## Where it reads the next tile's arrow, from its position (x and y).
var look := 0


## A GoPlat at [param cell] starting by arrow [param first] (0 up, 1 right,
## 2 down, 3 left), red or [param is_purple]. The arrow is already in its
## tile.
static func spawn(
	world: GalaxyWorld,
	cell: Vector2i,
	first: int,
	is_purple: bool,
	sprites: Dictionary[StringName, int]
) -> Keen5GoPlat:
	var platform := Keen5GoPlat.new()
	platform.activity = Activity.ALWAYS
	platform.priority = 0
	platform.clip = Clip.NONE
	platform.direction = Vector2i(0, 1)
	platform.path = GalaxyPathArrows.new()
	platform.path.arrow = first
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	if is_purple:
		platform.look = PURPLE_OFFSET
		at += Vector2i(PURPLE_OFFSET, PURPLE_OFFSET)
	platform.enter(world, at, ROWS, sprites, &"purple_1" if is_purple else &"go")
	return platform


## Think: on along the arrows (Omni CK_GoPlatThink).
func _think_go() -> void:
	path.advance(self, SPEED, look)
