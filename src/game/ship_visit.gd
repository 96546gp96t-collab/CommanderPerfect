class_name ShipVisit
extends RefCounted
## Keen's visit to his crashed ship ([ShipLevels]), with the extra levels
## on: what [LevelView] does differently in the two ship levels, and where
## Keen goes from them.
##
##   outside  Keen can walk away at the sides, back to the world map; the
##            back of the ship takes him inside, as an exit door does
##   inside   he puts the parts back ([ShipRepair]); out through the hatch
##            at the left he is outside again, next to the ship
## In both, items stay where they are: the parts in their places are not
## picked up again.

## A short note: a part went in, or is still missing.
signal note_shown(text: String)

## Where Keen goes next: back to the map, or into the other ship level.
const TO_MAP := 0
## The ship parts in the notes, by [enum Inventory.ShipPart].
const PART_NAMES: PackedStringArray = ["Joystick", "Battery", "Vacuum", "Everclear"]
const REPAIRED_NOTE := "All parts in! Ready to fly!"

## Inside the ship: Keen putting the parts back; null elsewhere.
var repair: ShipRepair
## Whether Keen is on his way out of the ship: outside, he starts next to it.
var _leaving := false


## Where Keen starts in [param level], ship level [param number]; elsewhere
## [param usual].
func start_cell(level: LevelData, number: int, usual: Vector2i) -> Vector2i:
	var leaving := _leaving
	_leaving = false
	if leaving and number == ShipLevels.OUTSIDE_LEVEL:
		return level.find_info(ShipLevels.DOOR_START_INFO)
	return usual


## Sets up [param session] for ship level [param number] (or nothing for
## another level).
func set_up(session: LevelSession, number: int, progress: GameProgress) -> void:
	repair = null
	if not ShipLevels.is_ship_level(number):
		return
	session.picks_up_items = false
	session.collision.solid_cells = ShipLevels.solid_cells(number)
	session.exit_cells = ShipLevels.entrance_cells(number)
	if number == ShipLevels.OUTSIDE_LEVEL:
		session.open_sides()
		return
	# Only the hatch at the left leads out.
	session.open_sides(true, false)
	repair = ShipRepair.create(progress, session.level)
	repair.part_installed.connect(_on_part_installed.bind(progress))
	repair.part_missing.connect(_on_part_missing)


## One tick, after the tick of [param session].
func step(session: LevelSession) -> void:
	if repair != null:
		repair.step(session)


## Whether every part is back and the ship is ready to fly home.
func is_ready_to_fly() -> bool:
	return repair != null and repair.is_ready_to_fly()


## Where Keen goes after ship level [param number] ended with [param outcome]:
## [constant TO_MAP] or the number of the other ship level.
func next_level(number: int, outcome: LevelSession.Outcome) -> int:
	repair = null
	if number == ShipLevels.INSIDE_LEVEL:
		_leaving = true
		return ShipLevels.OUTSIDE_LEVEL
	if outcome == LevelSession.Outcome.COMPLETED:
		return ShipLevels.INSIDE_LEVEL
	return TO_MAP


## Keen is somewhere else now (the map, another level, the title).
func leave() -> void:
	repair = null


func _on_part_installed(part: Inventory.ShipPart, progress: GameProgress) -> void:
	if progress.all_parts_installed():
		note_shown.emit(REPAIRED_NOTE)
	else:
		note_shown.emit("%s in place!" % PART_NAMES[part])


func _on_part_missing(part: Inventory.ShipPart) -> void:
	note_shown.emit("%s still missing" % PART_NAMES[part])
