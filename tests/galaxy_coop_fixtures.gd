extends RefCounted
## Helpers for the Galaxy two-player tests (milestone D12): a second Keen
## put into a hand-made mini level ([code]galaxy_keen_fixtures.gd[/code])
## the way the level session does it (the second object, with a view of
## his own), and frames run with a set of buttons for each Keen. Nothing
## comes from the game files.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

## Cells of the rows lie this far into the map (its solid border).
const BORDER := Vector2i(2, 2)


## Player 2's Keen at [param cell] (a cell of the rows, as the info plane's
## K would put him), facing [param facing], with his own view on him and
## player 1's inventory.
static func add_partner(world: GalaxyWorld, cell: Vector2i, facing := 1) -> GalaxyKeen:
	var keen := GalaxyKeen.spawn(world, cell + BORDER, facing, Keen4Sprites.all())
	world.objects.erase(keen)
	var view := Fixtures.camera_for(world.map)
	world.add_partner(keen, view)
	keen.inventory = (world.player() as GalaxyKeenBody).inventory
	view.centre_on(keen.position.x, keen.box.bottom)
	return keen


## Player 2 swimming (level 17) at [param cell] (a cell of the rows), with
## his own view and player 1's inventory.
static func add_swimmer(world: GalaxyWorld, cell: Vector2i) -> Keen4SwimmingKeen:
	var keen := Keen4SwimmingKeen.spawn(world, cell + BORDER, Keen4Sprites.all())
	world.objects.erase(keen)
	var view := Fixtures.camera_for(world.map)
	world.add_partner(keen, view)
	keen.inventory = (world.player() as GalaxyKeenBody).inventory
	return keen


## A camera for a map wider than the view, so that the two Keens can be
## out of each other's view: as wide as the map, and at least as high as
## the view and its border (as [code]camera_for[/code]).
static func wide_camera(map: GalaxyMap) -> GalaxyCamera:
	var smallest := GalaxyCamera.VIEW_TILES + Vector2i(4, 4)
	return GalaxyCamera.for_map(Vector2i(map.width, map.height).max(smallest))


## Runs [param frames] logic frames with [param first] and [param second]
## (Callables on the frame number that return a [KeenInput]) held by
## player 1 and player 2.
static func run(world: GalaxyWorld, frames: int, first: Callable, second: Callable) -> void:
	for frame in frames:
		var tics := GalaxyClock.LEVEL_START_TICS if world.tic == 0 else GalaxyClock.NORMAL_TICS
		world.tics = tics
		(world.player() as GalaxyKeenBody).begin_frame(first.call(frame))
		if world.partner != null:
			(world.partner as GalaxyKeenBody).begin_frame(second.call(frame))
		world.run_frame(tics, world.tic + tics)


## Runs [param frames] frames with [param first] and [param second] held
## the whole time.
static func hold(world: GalaxyWorld, frames: int, first: KeenInput, second: KeenInput) -> void:
	run(
		world,
		frames,
		func(_frame: int) -> KeenInput: return first,
		func(_frame: int) -> KeenInput: return second
	)


static func still() -> KeenInput:
	return KeenInput.new()
