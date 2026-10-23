extends RefCounted
## Hand-made mini levels with Keen 5's own tiles, for the tests of Keen 5's
## Keen (milestone E3): the tiles of [code]galaxy_keen_fixtures.gd[/code]
## and a security door (misc 32) whose tiles, as Keen 5's, step back 4
## tiles each time it opens a little. A door is a block of 4 × 4 tiles: its
## two middle columns are the door (misc 32), the outer ones only its
## frame. None of it comes from the game.

const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const SECURITY_DOOR := 60
const SECURITY_FRAME := 61
const SECURITY_MISC := 32
const DOOR_SIZE := Vector2i(4, 4)
const MIDDLE_COLUMNS := [1, 2]
## Keen in front of a door at the door row: the door's two tiles are at
## columns 2 and 3 of the rows, his head in their row, the target of the
## door (or of the exit) at their left one. [constant DOOR_AT] is the
## door's block's top left in map cells (Keen's middle column − 2, his
## bottom row − 4 when he stands at the door).
const DOOR_ROWS: PackedStringArray = [
	"....................",
	"....................",
	"..dd................",
	"..........K.........",
	"####################",
]
const DOOR_TARGET_CELL := Vector2i(2, 2)
const DOOR_AT := Vector2i(3, 1)


## The tile information of the shared fixtures with the security door.
static func tile_info() -> GalaxyTileInfo:
	var back := Keen.BACK_TILES
	var fore := Keen.FORE_TILES
	var data := PackedByteArray()
	data.resize(GalaxyTileInfo.BACK_TABLES * back + GalaxyTileInfo.FORE_TABLES * fore)
	var start := GalaxyTileInfo.BACK_TABLES * back
	var sides := Keen._tile_sides()
	sides.append([GalaxyTileInfo.Fore.MISC, SECURITY_DOOR, SECURITY_MISC])
	for entry in sides:
		data[start + entry[0] * fore + entry[1]] = entry[2] & 0xFF
	return GalaxyTileInfo.parse(data, back, fore)


## The door rows with a security door instead of the plain one: its 4 × 4
## block at [constant DOOR_AT].
static func security_door_level() -> GalaxyMap:
	var map := Keen.level(DOOR_ROWS)
	for y in DOOR_SIZE.y:
		for x in DOOR_SIZE.x:
			var tile := SECURITY_DOOR if x in MIDDLE_COLUMNS else SECURITY_FRAME
			var cell := DOOR_AT + Vector2i(x, y)
			map.planes[GalaxyMap.Layer.FOREGROUND][cell.y * map.width + cell.x] = tile
	return map


## The world of [param map] with Keen 5's Keen at K, carrying a new game's
## inventory; the sounds played are appended to [param sounds].
static func world(map: GalaxyMap, sounds: Array[StringName] = []) -> GalaxyWorld:
	var world := GalaxyWorld.create(map, tile_info(), Keen.sprite_infos())
	world.camera = Keen.camera_for(map)
	world.sound_player = func(name: StringName, _interrupt: bool) -> void: sounds.append(name)
	var start := GalaxyStart.find(map, Keen5Episode.game_rules())
	var keen := GalaxyKeen.spawn(
		world, start.cell, start.facing, Keen5Sprites.all(), Keen5Keen.new()
	)
	keen.inventory = Keen5Inventory.new_game()
	world.camera.centre_on(keen.position.x, keen.box.bottom)
	return world


## Walks Keen of [param world] left until his middle column is
## [param column] (map cells), then lets go of the keys for a frame.
static func walk_to(world: GalaxyWorld, column: int) -> void:
	var keen := world.player() as GalaxyKeen
	for frame in 60:
		if keen.box.tile_middle == column:
			break
		Keen.run(world, 1, func(_frame: int) -> KeenInput: return Keen.press(-1))
	Keen.run(world, 1, Keen.nothing)


## One frame with up held.
static func press_up(world: GalaxyWorld) -> void:
	Keen.run(world, 1, func(_frame: int) -> KeenInput: return Keen.press(0, -1))
