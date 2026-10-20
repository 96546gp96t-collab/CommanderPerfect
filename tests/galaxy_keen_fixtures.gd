extends RefCounted
## Hand-made mini levels for the Galaxy physics and Keen tests (D4): a map
## drawn as rows of characters, a TILEINFO with one tile per kind, and a
## sprite table in which every sprite has Keen's standing hit box (the
## stunner shots and items their own). None of it comes from the game.
##
## Characters (foreground tile, what it is):
##   .  nothing            #  solid on all sides     =  a thin floor (top)
##   2-7 a slope (top)      ^  a ceiling (bottom)     X  deadly (misc 3)
##   D  a deadly floor (9)  |  a pole (misc 1)        o  a pole hole in a floor
##   d  a door (misc 2)     *  a lifewater drop       $  100 points (misc 21)
##   +  an extra life (27)  G  a red gem holder (7)   B  a gem door (3 steps)
##   s  a bridge switch (15) b a bridge tile that moves on
## and on the info plane: K Keen facing right, k facing left, P Keen
## facing right in front of a pole; [method put_info] adds other values.

const UNITS := 16
const TILE := 256
const BACK_TILES := 4
const FORE_TILES := 64
## Foreground tile numbers.
const EMPTY := 0
const SOLID := 1
const THIN := 2
const SLOPE_FIRST := 3
const CEILING := 9
const DEADLY := 10
const DEADLY_FLOOR := 11
const POLE := 12
const POLE_HOLE := 13
const DOOR := 14
const DROP := 15
const POINTS := 16
const EXTRA_LIFE := 17
const GEM_HOLDER := 18
## The holder with its gem: + 18 (Omni).
const GEM_HOLDER_FULL := GEM_HOLDER + 18
const GEM_DOOR := 40
const SWITCH := 45
const BRIDGE := 47
## Sprite boxes: Keen's (Omni sprite 6: 4-19 × 0-31 pixels), a shot's.
const KEEN_BOX := Rect2i(64, 0, 240, 496)
const SHOT_BOX := Rect2i(32, 32, 176, 176)
const ITEM_BOX := Rect2i(0, 0, 240, 240)
const SPRITE_COUNT := 400
const SHOT_SPRITES: PackedInt32Array = [50, 51, 52, 53, 54, 55]
const ITEM_SPRITES_FROM := 91
const ITEM_SPRITES_TO := 128

const CHARACTERS: Dictionary[String, int] = {
	".": EMPTY,
	"#": SOLID,
	"=": THIN,
	"2": SLOPE_FIRST,
	"3": SLOPE_FIRST + 1,
	"4": SLOPE_FIRST + 2,
	"5": SLOPE_FIRST + 3,
	"6": SLOPE_FIRST + 4,
	"7": SLOPE_FIRST + 5,
	"^": CEILING,
	"X": DEADLY,
	"D": DEADLY_FLOOR,
	"|": POLE,
	"o": POLE_HOLE,
	"d": DOOR,
	"*": DROP,
	"$": POINTS,
	"+": EXTRA_LIFE,
	"G": GEM_HOLDER,
	"B": GEM_DOOR,
	"s": SWITCH,
	"b": BRIDGE,
}


## A map of [param rows] (all as wide as the first), with a two-tile border
## of solid tiles around it, as Galaxy maps have; Keen's info from K / k.
static func level(rows: PackedStringArray) -> GalaxyMap:
	var map := GalaxyMap.new()
	map.width = rows[0].length() + 4
	map.height = rows.size() + 4
	for layer in GalaxyMap.PLANE_COUNT:
		var plane := PackedInt32Array()
		plane.resize(map.width * map.height)
		map.planes.append(plane)
	for y in map.height:
		for x in map.width:
			var inside := x >= 2 and y >= 2 and x < map.width - 2 and y < map.height - 2
			var tile := SOLID
			if inside:
				var character := rows[y - 2][x - 2]
				tile = CHARACTERS.get(character, EMPTY)
				if character in ["K", "k", "P"]:
					map.planes[GalaxyMap.Layer.INFO][y * map.width + x] = (
						2 if character == "k" else 1
					)
				if character == "P":
					tile = POLE
			map.planes[GalaxyMap.Layer.FOREGROUND][y * map.width + x] = tile
	return map


## Puts [param value] on the info plane at [param cell] (a cell of the
## rows, without the border).
static func put_info(map: GalaxyMap, cell: Vector2i, value: int) -> void:
	var at := cell + Vector2i(2, 2)
	map.planes[GalaxyMap.Layer.INFO][at.y * map.width + at.x] = value


## The tile information of the characters above.
static func tile_info() -> GalaxyTileInfo:
	var data := PackedByteArray()
	data.resize(GalaxyTileInfo.BACK_TABLES * BACK_TILES + GalaxyTileInfo.FORE_TABLES * FORE_TILES)
	var fore := GalaxyTileInfo.BACK_TABLES * BACK_TILES
	for entry in _tile_sides():
		data[fore + entry[0] * FORE_TILES + entry[1]] = entry[2] & 0xFF
	return GalaxyTileInfo.parse(data, BACK_TILES, FORE_TILES)


## [table, tile, value] for every side and meaning of the tiles above.
static func _tile_sides() -> Array[Array]:
	var top := GalaxyTileInfo.Fore.TOP
	var right := GalaxyTileInfo.Fore.RIGHT
	var bottom := GalaxyTileInfo.Fore.BOTTOM
	var left := GalaxyTileInfo.Fore.LEFT
	var misc := GalaxyTileInfo.Fore.MISC
	var offset := GalaxyTileInfo.Fore.ANIMATION_OFFSET
	var sides: Array[Array] = [
		[top, SOLID, 1],
		[right, SOLID, 1],
		[bottom, SOLID, 1],
		[left, SOLID, 1],
		[top, THIN, 1],
		[bottom, CEILING, 1],
		[misc, DEADLY, GalaxyTileKinds.DEADLY],
		[top, DEADLY_FLOOR, 9],
		[misc, POLE, GalaxyTileKinds.POLE],
		[misc, POLE_HOLE, GalaxyTileKinds.POLE],
		[top, POLE_HOLE, GalaxyTileKinds.POLE_HOLE],
		[bottom, POLE_HOLE, GalaxyTileKinds.POLE_HOLE],
		[misc, DOOR, GalaxyTileKinds.DOOR],
		[misc, DROP, GalaxyTileKinds.DROP],
		[misc, POINTS, GalaxyTileKinds.FIRST_ITEM_TILE],
		[misc, EXTRA_LIFE, GalaxyTileKinds.FIRST_ITEM_TILE + 6],
		[misc, GEM_HOLDER, GalaxyTileKinds.FIRST_GEM_HOLDER],
		[top, GEM_HOLDER, 1],
		[top, GEM_HOLDER_FULL, 1],
		[misc, SWITCH, GalaxyTileKinds.BRIDGE_SWITCH],
		[offset, SWITCH, 1],
		[offset, BRIDGE, 1],
	]
	for slope in 6:
		sides.append([top, SLOPE_FIRST + slope, slope + 2])
	# The gem door: three solid steps, then open.
	for step in 3:
		for side in [top, right, left]:
			sides.append([side, GEM_DOOR + step, 1])
	return sides


## A sprite table where every sprite has Keen's box, the shots and items
## their own.
static func sprite_infos() -> Array[GalaxySpriteInfo]:
	var infos: Array[GalaxySpriteInfo] = []
	for sprite in SPRITE_COUNT:
		var box := KEEN_BOX
		if SHOT_SPRITES.has(sprite):
			box = SHOT_BOX
		elif sprite >= ITEM_SPRITES_FROM and sprite <= ITEM_SPRITES_TO:
			box = ITEM_BOX
		var info := GalaxySpriteInfo.new()
		info.box_left = box.position.x
		info.box_top = box.position.y
		info.box_right = box.end.x
		info.box_bottom = box.end.y
		infos.append(info)
	return infos


## A world of [param rows] with Keen (K or k) in it, the camera on him.
static func world(rows: PackedStringArray) -> GalaxyWorld:
	var map := level(rows)
	var world := GalaxyWorld.create(map, tile_info(), sprite_infos())
	world.camera = camera_for(map)
	var start := Keen4Start.find(map)
	var keen := GalaxyKeen.spawn(world, start.cell, start.facing, Keen4Sprites.all())
	keen.inventory = Keen4Inventory.new_game()
	world.camera.centre_on(keen.position.x, keen.box.bottom)
	return world


## A camera for [param map]: as for a map at least as large as the view
## and its border, so that a small level lies wholly in the view (a real
## map's camera cannot be smaller than the view).
static func camera_for(map: GalaxyMap) -> GalaxyCamera:
	var smallest := GalaxyCamera.VIEW_TILES + Vector2i(4, 4)
	return GalaxyCamera.for_map(Vector2i(map.width, map.height).max(smallest))


## Runs [param frames] logic frames of [param world] with the buttons
## [param held] returns for each frame number (a [KeenInput]); the first
## frame of a level covers 3 tics, the others 2 (as [GalaxyClock]).
## Returns Keen's highest position (smallest y) on the way.
static func run(world: GalaxyWorld, frames: int, held: Callable) -> int:
	var keen := world.player() as GalaxyKeen
	var highest := keen.position.y
	for frame in frames:
		var tics := GalaxyClock.LEVEL_START_TICS if world.tic == 0 else GalaxyClock.NORMAL_TICS
		world.tics = tics
		keen.begin_frame(held.call(frame))
		world.run_frame(tics, world.tic + tics)
		highest = mini(highest, keen.position.y)
	return highest


## Buttons: [param direction], [param vertical], and jump / pogo / fire.
static func press(direction := 0, vertical := 0, jump := false, pogo := false) -> KeenInput:
	var input := KeenInput.create(direction, jump, pogo)
	input.vertical = vertical
	return input


static func nothing(_frame: int) -> KeenInput:
	return KeenInput.new()
