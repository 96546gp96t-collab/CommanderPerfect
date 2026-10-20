class_name GalaxyGemDoor
extends GalaxyObject
## The door that a gem holder opens (Omni `ck_obj.c:CK_DoorOpen`,
## `ck_keen.c:CK_KeenPlaceGem`; docs/keen4/research.md §9): an object
## without a sprite that, three times 10 tics apart, moves every tile of
## the door's column on by one (tile + 1). The door is the column of equal
## tiles from its target down, and the two tiles under it.

## (Omni CK_ACT_DoorOpen1-3.)
const ROWS: PackedStringArray = [
	"open_1 - - step -- 10 0 0 open - - open_2",
	"open_2 - - step -- 10 0 0 open - - open_3",
	"open_3 - - step -- 10 0 0 open - - -",
]
## The tiles under the door's own tiles that change too (Omni).
const EXTRA_TILES := 2
## A door is at most this tall, its two extra tiles included (Omni).
const MAX_HEIGHT := 50

## The door's top tile.
var top_cell := Vector2i.ZERO
## Its own tiles (without the two under it).
var height := 0
## Its actions (they only hold each other weakly).
var _actions: Dictionary[StringName, GalaxyAction]


## Opens the door whose top tile is [param cell].
static func open_at(world: GalaxyWorld, cell: Vector2i) -> GalaxyGemDoor:
	var door := GalaxyGemDoor.new()
	door.top_cell = cell
	var tile := world.fore_tile(cell.x, cell.y)
	while world.fore_tile(cell.x, cell.y + door.height) == tile and door.height < MAX_HEIGHT:
		door.height += 1
	door.clip = Clip.NONE
	door.activity = Activity.ALWAYS
	world.add(door)
	door._actions = GalaxyAction.table_from(ROWS, {})
	door.start(door._actions[&"open_1"])
	return door


func _think_open() -> void:
	for row in mini(height + EXTRA_TILES, MAX_HEIGHT):
		var cell := top_cell + Vector2i(0, row)
		world.set_fore_tile(cell, world.fore_tile(cell.x, cell.y) + 1)
