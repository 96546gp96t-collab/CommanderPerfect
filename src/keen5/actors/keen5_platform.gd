class_name Keen5Platform
extends GalaxyPlatform
## An axis platform of Keen 5 (Omni `ck_obj.c` CK_SpawnAxisPlatform,
## CK_AxisPlatform; `ck5_misc.c` CK5_PurpleAxisPlatform; facts and numbers
## only; docs/keen5/research.md §7), two kinds:
##   - **red** (info 27-30: up, right, down, left): the Galaxy platform
##     ([GalaxyPlatform]: 12 units a tic, turning at the B-blocks, info
##     31), as Keen 4's without its jets;
##   - **purple** (info 84-87): placed 0x40 units right of and below its
##     tile; moving up or down it looks for the B-block one column right of
##     its box's left column (its stop rule still looks at the left one).
##     It has two pictures, but its action never runs out (timer 0), so it
##     always shows the first (Omni CK5_ACT_purpleAxisPlatform).
## Keen rides both ([GalaxyPlatform.touched_by_player]).

## (Omni CK_ACT_AxisPlatform, CK5_ACT_purpleAxisPlatform, 2.)
const ROWS: PackedStringArray = [
	"move PLATFORM PLATFORM think -- 0 0 0 axis - - -",
	"purple_1 PURPLEPLAT1 PURPLEPLAT1 step+ -- 0 0 0 purple_axis - - purple_2",
	"purple_2 PURPLEPLAT2 PURPLEPLAT2 step+ -- 0 0 0 purple_axis - - purple_1",
]
## A purple platform's place from its tile's corner, x and y (Omni).
const PURPLE_OFFSET := 0x40
## Moving up or down, the purple one looks this many columns right of its
## box's left column for a B-block (Omni).
const PURPLE_LOOK_COLUMN := 1

## Turning sideways it stops on the tile's edge (Keen 5 v1.4, seen in demo
## 2, E7; Keen 4's platforms bounce back off it).
const EDGE_BOUNCE := 1

## A purple platform (info 84-87).
var purple := false


func _init() -> void:
	bounce = EDGE_BOUNCE


## A red platform at [param cell] going [param heading] (0 up, 1 right,
## 2 down, 3 left; info 27-30).
static func spawn_red(
	world: GalaxyWorld, cell: Vector2i, heading: int, sprites: Dictionary[StringName, int]
) -> Keen5Platform:
	var platform := Keen5Platform.new()
	platform.place_moving(world, cell, heading, ROWS, sprites, &"move")
	return platform


## A purple platform at [param cell] going [param heading] (info 84-87).
static func spawn_purple(
	world: GalaxyWorld, cell: Vector2i, heading: int, sprites: Dictionary[StringName, int]
) -> Keen5Platform:
	var platform := Keen5Platform.new()
	platform.purple = true
	platform.activity = Activity.ALWAYS
	platform.priority = 0
	platform.direction = HEADINGS[heading]
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	at += Vector2i(PURPLE_OFFSET, PURPLE_OFFSET)
	platform.enter(world, at, ROWS, sprites, &"purple_1")
	return platform


## Think of the purple platform: the axis rule with its own column
## (Omni CK5_PurpleAxisPlatform).
func _think_purple_axis() -> void:
	_think_axis()


## The purple one looks one column further right when it moves up or down.
func _turn_point_entered(entered: int, now: int, columns: bool) -> bool:
	if not purple or columns:
		return super(entered, now, columns)
	if entered == now:
		return false
	return _is_turn_point(box.tile_left + PURPLE_LOOK_COLUMN, entered)
