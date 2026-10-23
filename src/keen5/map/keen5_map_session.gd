class_name Keen5MapSession
extends GalaxyMapSession
## Keen 5's world map, the Omegamatic (map 0), being played (milestone E6;
## Omni `ck5_misc.c:CK5_ScanInfoLayer`, `CK5_OpenMapTeleporter`,
## `CK5_CloseMapTeleporter`, `ck5_map.c`; facts only; docs/keen5/
## research.md §8, docs/keen5/gameplay.md "The world map"): the Galaxy map
## ([GalaxyMapSession]) with
##   - Keen 5's map Keen ([Keen5MapKeen]): no water, no Foot;
##   - waving flags only, at (−0x50, −0x1E0) from their holders (the rules);
##   - the teleporters and elevators, whose rides stop the game while they
##     run ([Keen5MapRide]);
##   - the shafts, set when the map starts by the row Keen stands in: the
##     door of the bottom elevator (24, 76) closes and the middle one's
##     left door (22, 55) opens when he is above row 75 or on Korath III
##     (below row 100); the middle one's right door (26, 55), to the top,
##     opens below row 39 once levels 4, 6, 8 and 10 are done; the top
##     door (24, 30) opens above row 39 or on Korath III. A door is the
##     2 × 2 tiles of the template in the map's top-left corner: open
##     (10, 0), closed (0, 0);
##   - Korath III: after the door to it in level 11 Keen does not stand on
##     the map-Keen info but on info 26, facing west;
##   - the plain yellow background tile the map is filled with around the
##     station's star field, where the original's view never comes, is
##     drawn as black space (tile 0): a wider view (widescreen) would show
##     it (files, E6). Korath III's yellow ground below row 100 stays.
##     With the pictures behind the levels on, the space shows the world
##     map's picture (E10, [Keen5BackdropPictures]).

## Info 26: where Keen steps out onto Korath III (Omni CK5_MapKeenTeleSpawn).
const KORATH_INFO := 26
## The doors of the shafts (Omni CK5_ScanInfoLayer).
const BOTTOM_DOOR := Vector2i(24, 76)
const MIDDLE_DOWN_DOOR := Vector2i(22, 55)
const MIDDLE_UP_DOOR := Vector2i(26, 55)
const TOP_DOOR := Vector2i(24, 30)
## The rows that tell where Keen is: above the bottom part, below the top,
## and beyond the station's last row (Korath III).
const BOTTOM_PART_ROW := 75
const TOP_PART_ROW := 39
const KORATH_ROW := 100
## The door pictures in the map's top-left corner (2 × 2 tiles each).
const DOOR_SIZE := Vector2i(2, 2)
const OPEN_DOOR := Vector2i(10, 0)
const CLOSED_DOOR := Vector2i(0, 0)
## The yellow filler around the station and the black tile drawn instead
## (files: back tile 850 is all EGA yellow, tile 0 all black).
const FILLER_TILE := 850
const SPACE_TILE := 0

## The ride that holds the game, or null.
var ride: Keen5MapRide


## Keen 5's world map [param world_map] of [param data] for a game at
## [param progress] (see [method GalaxyMapSession.start]).
static func start_map(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	world_map: GalaxyMap,
	progress: GalaxyProgress,
	random_start := 0
) -> Keen5MapSession:
	var session := Keen5MapSession.new()
	if not session.begin_with(data, game_rules, world_map, progress, random_start):
		return null
	return session


## Whether a ride holds the game.
func rides() -> bool:
	return ride != null


func _new_keen() -> GalaxyMapKeen:
	return Keen5MapKeen.new()


## On Korath III after its door: at info 26; otherwise as on every map.
func _keen_place(start_place: GalaxyStart, progress: GalaxyProgress) -> Vector2i:
	var keen_5 := progress as Keen5Progress
	if keen_5 != null and keen_5.korath_arrival:
		for y in map.height:
			for x in map.width:
				if map.tile(GalaxyMap.Layer.INFO, x, y) == KORATH_INFO:
					return Vector2i(x, y) * GalaxyCamera.UNITS_PER_TILE
	return super(start_place, progress)


## The shafts by the row Keen stands in (Omni CK5_ScanInfoLayer).
func _place_extras(progress: GalaxyProgress) -> void:
	var row := GalaxyUnits.to_tile(keen.position.y)
	var on_korath := row > KORATH_ROW
	if row < BOTTOM_PART_ROW or on_korath:
		_set_door(BOTTOM_DOOR, CLOSED_DOOR)
		_set_door(MIDDLE_DOWN_DOOR, OPEN_DOOR)
	var keen_5 := progress as Keen5Progress
	if keen_5 != null and keen_5.shaft_fuses_broken() and row > TOP_PART_ROW:
		_set_door(MIDDLE_UP_DOOR, OPEN_DOOR)
	if row < TOP_PART_ROW or on_korath:
		_set_door(TOP_DOOR, OPEN_DOOR)
	_hide_filler()


## A ride runs instead of the world; one that ends lets the world go on
## from the next frame.
func _runs_own_frame(tics: int, tic: int) -> bool:
	if ride == null:
		return false
	ride.advance(tics, tic)
	if ride.is_done():
		ride = null
		(keen as Keen5MapKeen).ride = Keen5MapKeen.Ride.NONE
	return true


## After the world's frame: a ride the tile under Keen asks for, or the
## end of his flight in the elevator.
func _after_world_frame() -> void:
	var walker := keen as Keen5MapKeen
	if walker.arrived:
		walker.arrived = false
		ride = Keen5MapRide.coming_out(walker, camera)
	elif walker.ride != Keen5MapKeen.Ride.NONE:
		ride = Keen5MapRide.going_in(walker, camera, walker.ride_cell)


## The station's yellow filler becomes black space (not on Korath III).
func _hide_filler() -> void:
	for y in mini(map.height, KORATH_ROW + 1):
		for x in map.width:
			if map.tile(GalaxyMap.Layer.BACKGROUND, x, y) == FILLER_TILE:
				world.set_back_tile(Vector2i(x, y), SPACE_TILE)


## Puts the door picture at [param picture] (the template's corner) at
## [param corner] (Omni RF_ReplaceTiles).
func _set_door(corner: Vector2i, picture: Vector2i) -> void:
	if corner.x + DOOR_SIZE.x > map.width or corner.y + DOOR_SIZE.y > map.height:
		return
	for y in DOOR_SIZE.y:
		for x in DOOR_SIZE.x:
			var tile := world.fore_tile(picture.x + x, picture.y + y)
			world.set_fore_tile(corner + Vector2i(x, y), tile)
