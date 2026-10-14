class_name OpeningDoor
extends Actor
## A door that Keen opened with a keycard. The door tiles are already gone
## from the level; this actor draws them once more while they sink into the
## floor, one pixel at a time.

## Ticks per pixel the door sinks. An estimate, still to be compared with the
## original.
const TICKS_PER_PIXEL := 1

## The door tiles from top to bottom.
var tiles := PackedInt32Array()
## How many pixel rows of the door are still visible, from the top.
var visible_height := 0
var _timer := 0


## A door whose top tile was in [param top_cell].
static func create(top_cell: Vector2i, door_tiles: PackedInt32Array) -> OpeningDoor:
	var door := OpeningDoor.new()
	door.position = Vector2(top_cell * EgaGraphics.TILE_SIZE)
	door.tiles = door_tiles
	door.visible_height = door_tiles.size() * EgaGraphics.TILE_SIZE
	return door


func step(_session: LevelSession) -> void:
	_timer += 1
	if _timer < TICKS_PER_PIXEL:
		return
	_timer = 0
	position.y += 1
	visible_height -= 1
	if visible_height <= 0:
		removed = true
