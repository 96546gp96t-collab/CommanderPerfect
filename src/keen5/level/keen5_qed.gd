class_name Keen5Qed
extends GalaxyCreature
## The Quantum Explosion Dynamo of map 12 (Omni `ck5_obj3.c` CK5_QEDSpawn,
## CK5_MineShrapCol; facts and numbers only; docs/keen5/research.md §4): an
## unseen object (info 41 on map 12) whose box is 0x220 units square from
## 0x10 left of and above its tile's corner; it sleeps far from the view.
## Only the piece of a Shikadi mine destroys it ([Keen5Piece] calls
## [method hit_by_piece]): four fuse explosions at its corner tiles (its
## tile and the ones right of and below it), the 4 × 2 tile blocks at
## (16, 11) and (16, 13) become the ones at the map's (0, 0) and (4, 0) in
## all three planes, and 60 tics later the level ends
## ([Keen5LevelEnd]). It never moves (its facing is none).

## (Omni CK5_ACT_QED: no picture, 8 tics again and again; its speed of
## 128 across moves nothing without a facing, so it is left out.)
const ROWS: PackedStringArray = [
	"stand x x step -- 8 0 0 - - - stand",
]
## Its box (Omni).
const BOX_FROM_TILE := -0x10
const BOX_SIZE := 0x220
## Its corner tiles are its tile and the next column and row (Omni).
const CORNER_SPAN := 1
## The broken machine: what is copied where (Omni RF_ReplaceTileBlock).
const BLOCK_SIZE := Vector2i(4, 2)
const UPPER_FROM := Vector2i(0, 0)
const UPPER_TO := Vector2i(0x10, 0xB)
const LOWER_FROM := Vector2i(4, 0)
const LOWER_TO := Vector2i(0x10, 0xD)

## Its tile.
var cell := Vector2i.ZERO


## The QED at [param at_cell] of [param world].
static func spawn(
	world: GalaxyWorld, at_cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Qed:
	var qed := Keen5Qed.new()
	qed.cell = at_cell
	qed.clip = Clip.NONE
	qed.direction = Vector2i.ZERO
	var corner := Vector2i(GalaxyUnits.from_tile(at_cell.x), GalaxyUnits.from_tile(at_cell.y))
	qed.enter(world, corner, ROWS, sprites, &"stand")
	qed._set_box(corner + Vector2i(BOX_FROM_TILE, BOX_FROM_TILE))
	return qed


## A mine's piece [param _piece] touched it: it blows up (Omni
## CK5_MineShrapCol).
func hit_by_piece(_piece: GalaxyObject) -> void:
	if removed:
		return
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		Keen5Flash.fuse_explosion(world, cell + corner * CORNER_SPAN, sprites)
	world.copy_block(UPPER_FROM, UPPER_TO, BLOCK_SIZE)
	world.copy_block(LOWER_FROM, LOWER_TO, BLOCK_SIZE)
	Keen5LevelEnd.spawn(world, sprites)
	world.remove(self)


func _set_box(top_left: Vector2i) -> void:
	box.left = top_left.x
	box.top = top_left.y
	box.right = top_left.x + BOX_SIZE
	box.bottom = top_left.y + BOX_SIZE
	box.middle = (box.left + box.right) / 2
	box.tile_left = GalaxyUnits.to_tile(box.left)
	box.tile_top = GalaxyUnits.to_tile(box.top)
	box.tile_right = GalaxyUnits.to_tile(box.right)
	box.tile_bottom = GalaxyUnits.to_tile(box.bottom)
	box.tile_middle = GalaxyUnits.to_tile(box.middle)
