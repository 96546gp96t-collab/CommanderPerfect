class_name ShipRepair
extends RefCounted
## Keen puts his ship back together, inside the ship ([ShipLevels]): when he
## walks into the place of a part that he has found, the part goes in. Once
## all four are in, the ship can fly home: a moment later the ending starts.
##
## Runs next to the [LevelSession] of the inside, one tick at a time, so
## that the tests can play it too. The parts that are in are kept in the
## [GameProgress], so that they stay in when Keen goes out and comes back.

## Emitted when a part goes into its place.
signal part_installed(part: Inventory.ShipPart)
## Emitted when Keen walks into the place of a part he has not found yet.
signal part_missing(part: Inventory.ShipPart)

## Ticks between the last part going in and the ship being ready to fly.
const FLY_DELAY_TICKS := 90

var progress: GameProgress
## The place of each part in the level, by [enum Inventory.ShipPart].
var places: Dictionary[int, Vector2i] = {}
var _touched: Dictionary[int, bool] = {}
var _ticks_complete := 0


## Starts the repair in [param level], whose info layer marks the places.
static func create(game: GameProgress, level: LevelData) -> ShipRepair:
	var repair := ShipRepair.new()
	repair.progress = game
	for index in level.infos.size():
		var part := ShipLevels.part_of_place(level.infos[index])
		if part >= 0:
			repair.places[part] = Vector2i(index % level.width, index / level.width)
	return repair


## Looks what the Keens of [param session] walk into, after its tick.
func step(session: LevelSession) -> void:
	for part: int in places:
		var touched := _is_touched(session, places[part])
		if touched and not _touched.get(part, false):
			_use_place(session, part as Inventory.ShipPart)
		_touched[part] = touched
	if progress.all_parts_installed():
		_ticks_complete += 1


## Whether all parts are in and the moment after the last one is over.
func is_ready_to_fly() -> bool:
	return _ticks_complete >= FLY_DELAY_TICKS


func _use_place(session: LevelSession, part: Inventory.ShipPart) -> void:
	if progress.installed_parts[part]:
		return
	if not progress.inventory.ship_parts[part]:
		part_missing.emit(part)
		return
	progress.install_part(part)
	session.set_tile(places[part], ShipLevels.PART_TILES[part])
	session.play_sound(Sound.Id.GOT_PART)
	part_installed.emit(part)


static func _is_touched(session: LevelSession, cell: Vector2i) -> bool:
	var area := Rect2(Vector2(cell * EgaGraphics.TILE_SIZE), Vector2.ONE * EgaGraphics.TILE_SIZE)
	for body in session.keens:
		if not body.is_dead and body.hitbox().intersects(area):
			return true
	return false
