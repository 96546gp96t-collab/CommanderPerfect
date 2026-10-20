extends RefCounted
## Helpers for the creature tests (milestone D5): a hand-made mini level
## ([code]galaxy_keen_fixtures.gd[/code]) with creatures put on its info
## plane and placed as the level session does, frames run with Keen
## standing still, and stunner shots fired at a creature. Nothing comes
## from the game files.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
## Every frame after the first is 2 tics (35 a second).
const FRAME_TICS := 2
## Made-up hit boxes for the creatures' sprites, by the start of their
## names (the first that fits): left, top, right, bottom in units. The
## bottom is chosen so that a creature placed by its info value stands on
## the floor under its tile (its rise + 255); a bite and a flame reach
## forward. Not the game's own boxes.
const BOXES: Array = [
	["SLUG", [32, 128, 240, 368]],
	["MUSHROOM", [64, 0, 400, 496]],
	["EGG", [48, 64, 304, 368]],
	["BIRD_FLY", [64, 32, 368, 256]],
	["BIRD", [96, 32, 368, 496]],
	["ARACHNUT", [64, 64, 544, 624]],
	["MIMROCK", [32, 192, 336, 463]],
	["SMIRKY", [0, 160, 608, 639]],
	["BOUNDER", [64, 64, 304, 383]],
	["BERKELOID", [128, 128, 368, 767]],
	["WORMMOUTH_BITE_R", [0, -192, 560, 112]],
	["WORMMOUTH_BITE_L", [-320, -192, 240, 112]],
	["WORMMOUTH", [0, 0, 112, 112]],
	["LICK_FLAME_L", [-224, 0, 304, 255]],
	["LICK_FLAME_R", [0, 0, 528, 255]],
	["CLOUD", [0, 0, 1008, 368]],
	["BOLT", [128, 0, 240, 1136]],
]
const OTHER_BOX: Array[int] = [32, 32, 240, 255]
## A shot starts this far left of what it is fired at, its position this
## far above the bottom of the target's box (its box ends 208 units under
## its position: galaxy_keen_fixtures.gd).
const SHOT_LEAD := 200
const SHOT_BOTTOM := 209
## The made-up random table: 256 numbers, each this much more than the one
## before (mod 256).
const RANDOM_COUNT := 256
const RANDOM_STEP := 73
const RANDOM_START := 41
const RANDOM_MASK := 0xFF


## A world of [param rows] (Keen at K or k) with info value [param info]
## put at each cell of [param cells] (cells of the rows), and the
## creatures placed for [param difficulty].
static func world(
	rows: PackedStringArray,
	info: int,
	cells: Array[Vector2i],
	difficulty := GalaxyDifficulty.DEFAULT
) -> GalaxyWorld:
	var world := Fixtures.world(rows)
	world.random_table = random_table()
	_give_boxes(world)
	for cell in cells:
		Fixtures.put_info(world.map, cell, info)
	Keen4Creatures.place_all(world, difficulty, Keen4Sprites.all())
	return world


## A fixed table of 256 made-up random numbers, so the tests do the same
## every run (the game's own table is in the EXE).
static func random_table() -> PackedByteArray:
	var table := PackedByteArray()
	for index in RANDOM_COUNT:
		table.append((index * RANDOM_STEP + RANDOM_START) & RANDOM_MASK)
	return table


## Gives the creatures' sprites the boxes above.
static func _give_boxes(world: GalaxyWorld) -> void:
	var sprites := Keen4CreatureSprites.SPRITES
	for name in sprites:
		var rect: Array = OTHER_BOX
		for entry in BOXES:
			if String(name).begins_with(entry[0]):
				rect = entry[1]
				break
		var info := GalaxySpriteInfo.new()
		info.box_left = rect[0]
		info.box_top = rect[1]
		info.box_right = rect[2]
		info.box_bottom = rect[3]
		world.sprite_infos[sprites[name]] = info


## The first object of [param world] that is a [param type].
static func first(world: GalaxyWorld, type: Script) -> GalaxyObject:
	for object in world.objects:
		if is_instance_of(object, type) and not object.removed:
			return object
	return null


## How many objects of [param type] are in [param world].
static func count(world: GalaxyWorld, type: Script) -> int:
	var total := 0
	for object in world.objects:
		if is_instance_of(object, type) and not object.removed:
			total += 1
	return total


## Runs [param frames] frames with Keen standing still.
static func wait(world: GalaxyWorld, frames: int) -> void:
	Fixtures.run(world, frames, Fixtures.nothing)


## Runs [param frames] frames with [param held] (a [KeenInput]) every frame.
static func hold(world: GalaxyWorld, frames: int, held: KeenInput) -> void:
	Fixtures.run(world, frames, func(_frame: int) -> KeenInput: return held)


## A stunner shot fired to the right at [param creature], from just left
## of its box, its box ending a unit above the creature's bottom (so it
## never touches the floor): it hits within a frame or two.
## The shot's actions are kept in [param keep].
static func shoot(world: GalaxyWorld, creature: GalaxyObject, keep: Array) -> GalaxyStunnerShot:
	var actions := GalaxyStunnerShot.actions_for(Keen4Sprites.all())
	keep.append(actions)
	var at := Vector2i(creature.box.left - SHOT_LEAD, creature.box.bottom - SHOT_BOTTOM)
	return GalaxyStunnerShot.fire(world, at, Vector2i.RIGHT, actions)


## Runs frames until [param done] (a Callable on nothing) is true, at most
## [param limit]; returns the frames run.
static func run_until(world: GalaxyWorld, done: Callable, limit: int) -> int:
	for frame in limit:
		if done.call():
			return frame
		wait(world, 1)
	return limit
