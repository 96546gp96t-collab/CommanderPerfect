class_name Keen2Walls
extends LevelWalls
## Keen 2's back walls (milestone AB2, the user's choice of 22-10-2026):
## every level is a room of the Vorticon Mothership, so it has no sky; its
## back wall is fixed to the level (it moves 1:1 with the tiles, as the
## lattice does), and the walls' shadows fall on it as dark bands without
## the lattice. The rules, by the tiles a level uses:
##   - the lattice (tile 143) by the pattern rule ([LatticeWalls]), lit and
##     in the shadows of the walls
##   - the lattice in the dark (tile 147, levels 5 and 14) too, shown dim,
##     so the grey cones under the lamps there stay lit
##   - the plain teal of level 12 (tile 276) by the colour rule
## The textures are Keen 2's own (keen2/wallNN), never Keen 1's.
##
## Two kinds of tile have rules of their own (fixes of 22-10, with the tile
## properties): the lattice around an item is found by the item rule
## ([method LatticeWalls.item_background]), so no lattice is left at its
## sides; and the windows (masked tiles with a mask, 403-422 in version
## 1.31, in levels 6, 7 and 9) show the wall through their glass: only
## the glass their mask draws in front of Keen (the streaks and the frame)
## stays ([method BackdropHoles.window_kinds], the user's choice of 22-10).

const FOLDER_KEEN_2 := "res://assets/backgrounds/keen2"
const LATTICE_TILE := 143
const DARK_LATTICE_TILE := 147
const TEAL_TILE := 276
const LATTICE_NAME := "lattice"
const DARK_LATTICE_NAME := "lattice+dark"
## Below this brightness a pixel of a mask is drawn in front of Keen, as in
## masked_tiles.gdshader.
const MASK_THRESHOLD := 0.5

var _lattice: LatticeWalls
var _dark_lattice: LatticeWalls
var _items: Dictionary[int, bool] = {}
var _windows: Dictionary[int, PackedByteArray] = {}


## Keen 2's walls: textures in [param folder] or the player's own folder in
## [param files], for the tiles [param tiles], whose [param properties] tell
## the items and the windows (none without them).
static func create(
	files: GameFiles,
	tiles: Array[Image],
	folder := FOLDER_KEEN_2,
	properties: TileProperties = null
) -> Keen2Walls:
	var walls := Keen2Walls.new()
	walls._textures = BackdropPictures.walls(files, folder)
	walls._tiles = tiles
	if tiles.size() > DARK_LATTICE_TILE:
		walls._lattice = LatticeWalls.create(tiles[LATTICE_TILE])
		walls._dark_lattice = LatticeWalls.create(tiles[LATTICE_TILE], tiles[DARK_LATTICE_TILE])
	if properties != null:
		walls._items = items(properties, tiles.size())
		walls._windows = windows(properties, tiles)
	return walls


## The item tiles among the first [param count] of [param properties].
static func items(properties: TileProperties, count: int) -> Dictionary[int, bool]:
	var found: Dictionary[int, bool] = {}
	for tile in mini(count, properties.tile_count):
		if properties.is_item(tile):
			found[tile] = true
	return found


## The windows: masked tiles of [param tiles] whose next tile is their mask
## ([method EgaGraphics.has_tile_mask]), each with 1 for every pixel its
## mask draws in front of Keen.
static func windows(
	properties: TileProperties, tiles: Array[Image]
) -> Dictionary[int, PackedByteArray]:
	var found: Dictionary[int, PackedByteArray] = {}
	for tile in mini(tiles.size() - 1, properties.tile_count):
		if (
			properties.behavior(tile) == TileProperties.Behavior.MASKED
			and EgaGraphics.is_black_and_white(tiles[tile + 1])
		):
			found[tile] = _in_front(tiles[tile + 1])
	return found


## 1 for every black pixel of [param mask].
static func _in_front(mask: Image) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(mask.get_width() * mask.get_height())
	for i in result.size():
		var pixel := mask.get_pixel(i % mask.get_width(), i / mask.get_width())
		result[i] = 1 if pixel.get_luminance() < MASK_THRESHOLD else 0
	return result


func holes(level: LevelData, _sky_color: Color, wall: bool) -> BackdropHoles:
	if not wall or _lattice == null:
		return null
	var teal := _color_of(TEAL_TILE) if uses_tile(level, TEAL_TILE) else Color.TRANSPARENT
	var holes: BackdropHoles
	if uses_tile(level, DARK_LATTICE_TILE):
		holes = BackdropHoles.create(Color.TRANSPARENT, teal, _dark_lattice, DARK_LATTICE_NAME)
	else:
		holes = BackdropHoles.create(Color.TRANSPARENT, teal, _lattice, LATTICE_NAME)
	holes.item_tiles = _items
	holes.windows = _windows
	return holes
