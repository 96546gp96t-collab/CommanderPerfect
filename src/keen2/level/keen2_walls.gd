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

const FOLDER_KEEN_2 := "res://assets/backgrounds/keen2"
const LATTICE_TILE := 143
const DARK_LATTICE_TILE := 147
const TEAL_TILE := 276
const LATTICE_NAME := "lattice"
const DARK_LATTICE_NAME := "lattice+dark"

var _lattice: LatticeWalls
var _dark_lattice: LatticeWalls


## Keen 2's walls: textures in [param folder] or the player's own folder in
## [param files], for the tiles [param tiles].
static func create(files: GameFiles, tiles: Array[Image], folder := FOLDER_KEEN_2) -> Keen2Walls:
	var walls := Keen2Walls.new()
	walls._textures = BackdropPictures.walls(files, folder)
	walls._tiles = tiles
	if tiles.size() > DARK_LATTICE_TILE:
		walls._lattice = LatticeWalls.create(tiles[LATTICE_TILE])
		walls._dark_lattice = LatticeWalls.create(tiles[LATTICE_TILE], tiles[DARK_LATTICE_TILE])
	return walls


func holes(level: LevelData, _sky_color: Color, wall: bool) -> BackdropHoles:
	if not wall or _lattice == null:
		return null
	var teal := _color_of(TEAL_TILE) if uses_tile(level, TEAL_TILE) else Color.TRANSPARENT
	if uses_tile(level, DARK_LATTICE_TILE):
		return BackdropHoles.create(Color.TRANSPARENT, teal, _dark_lattice, DARK_LATTICE_NAME)
	return BackdropHoles.create(Color.TRANSPARENT, teal, _lattice, LATTICE_NAME)
