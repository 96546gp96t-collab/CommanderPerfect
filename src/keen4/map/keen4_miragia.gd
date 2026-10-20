class_name Keen4Miragia
extends GalaxyObject
## Miragia on Keen 4's world map (info 33; Omni `ck4_obj1.c`:
## CK4_SpawnMiragia, CK4_Miragia0-7; seen in the original, D7): a block of
## 6 × 4 tiles that comes and goes by copying one of five template blocks
## from row 60 of the map over its place (all three planes, so its
## entrance comes and goes with it):
##   - hidden (template column 2) for 300 tics, then three steps of 30 tics
##     (columns 8, 14, 20) to the whole city (column 26) for 300 tics, and
##     three steps back (20, 14, 8) and hidden again after 30 more;
##   - when the 300 hidden tics end with Keen standing in its place (his
##     box within its rows, touching its columns) it stays hidden for
##     another round.
## It has no picture and is always awake.

## The template blocks (Omni): row 60, columns 2 (nothing), 8, 14, 20, 26
## (the whole city).
const TEMPLATE_ROW := 60
const HIDDEN_COLUMN := 2
const SIZE := Vector2i(6, 4)
## (Omni CK4_ACT_Miragia0-7.) Each step's think puts the block of the
## column named after it.
const ROWS: PackedStringArray = [
	"hidden x x step -- 300 0 0 appear - - rise_1",
	"rise_1 x x step -- 30 0 0 show - - rise_2",
	"rise_2 x x step -- 30 0 0 show - - rise_3",
	"rise_3 x x step -- 30 0 0 show - - whole",
	"whole x x step -- 300 0 0 show - - fade_1",
	"fade_1 x x step -- 30 0 0 show - - fade_2",
	"fade_2 x x step -- 30 0 0 show - - fade_3",
	"fade_3 x x step -- 30 0 0 show - - hidden",
]
## The block each action's think puts (Omni CK4_Miragia1-7; the hidden
## action's think puts column 8 unless Keen is there).
const COLUMNS: Dictionary[StringName, int] = {
	&"hidden": 8,
	&"rise_1": 14,
	&"rise_2": 20,
	&"rise_3": 26,
	&"whole": 20,
	&"fade_1": 14,
	&"fade_2": 8,
	&"fade_3": HIDDEN_COLUMN,
}

## Its place: the info tile.
var cell := Vector2i.ZERO
## The template column it showed last.
var column := HIDDEN_COLUMN
var _actions: Dictionary[StringName, GalaxyAction] = {}


## Miragia at [param at] (the info tile) in [param world].
static func place(world: GalaxyWorld, at: Vector2i) -> Keen4Miragia:
	var miragia := Keen4Miragia.new()
	miragia.cell = at
	miragia._actions = GalaxyAction.table_from(ROWS, {})
	miragia.clip = Clip.NONE
	miragia.activity = Activity.ALWAYS
	miragia.hidden = true
	world.add(miragia)
	miragia.action = miragia._actions[&"hidden"]
	return miragia


## Whether Keen ([param keen]) stands in its place (Omni CK4_Miragia0).
func holds(keen: GalaxyObject) -> bool:
	var box := keen.box
	return (
		box.tile_right >= cell.x
		and box.tile_left <= cell.x + SIZE.x - 1
		and box.tile_top >= cell.y
		and box.tile_bottom <= cell.y + SIZE.y
	)


## Think at the end of the hidden tics: it appears, unless Keen is there
## (Omni CK4_Miragia0).
func _think_appear() -> void:
	var keen := world.player()
	if keen != null and holds(keen):
		action = _actions[&"fade_3"]
		return
	_show_column(COLUMNS[&"hidden"])


## Think at the end of a step: the next block (Omni CK4_Miragia1-7).
func _think_show() -> void:
	_show_column(COLUMNS[action.name])


func _show_column(template: int) -> void:
	column = template
	world.copy_block(Vector2i(template, TEMPLATE_ROW), cell, SIZE)
