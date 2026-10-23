class_name Keen5SecurityDoor
extends GalaxyObject
## The security door opening after Keen used his keycard on it (Omni
## `ck_obj.c:CK_SecurityDoorOpen`, `ck_keen.c:CK_KeenPressUp`;
## docs/keen5/research.md §4): an object without a sprite that, three
## times 15 tics apart, puts in every one of the 4 × 4 foreground tiles of
## the door the tile 4 before it (the door's next picture), then is gone.

## (Omni CK_ACT_SecurityDoorOpen: it follows itself.)
const ROWS: PackedStringArray = ["open - - step -- 15 0 0 open - - open"]
## The door's tiles, from its top left.
const SIZE := Vector2i(4, 4)
## Each step a tile becomes the one this many before it (Omni).
const TILE_STEP := -4
const STEPS := 3

## The door's top left tile.
var top_left := Vector2i.ZERO
var steps_done := 0
## Its action (it only holds itself weakly).
var _actions: Dictionary[StringName, GalaxyAction]


## Opens the door whose top left tile is [param cell].
static func open_at(world: GalaxyWorld, cell: Vector2i) -> Keen5SecurityDoor:
	var door := Keen5SecurityDoor.new()
	door.top_left = cell
	door.clip = Clip.NONE
	door.activity = Activity.ALWAYS
	world.add(door)
	door._actions = GalaxyAction.table_from(ROWS, {})
	door.start(door._actions[&"open"])
	return door


func _think_open() -> void:
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := top_left + Vector2i(x, y)
			world.set_fore_tile(cell, world.fore_tile(cell.x, cell.y) + TILE_STEP)
	steps_done += 1
	if steps_done == STEPS:
		action = null
