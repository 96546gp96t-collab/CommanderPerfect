class_name Keen3MapSession
extends MapSession
## Keen on Keen 3's world map (map 80), advanced one fixed tick at a time:
## Keen 1's [MapSession] (walking, entrances that block the way until their
## level is done, entering a level with the jump or pogo button) with what
## Keen 3 has instead (Choco `game/worldmap.c`, `CVort3_worldmap_sprites`,
## `CVort3_do_messie`; docs/keen3/research.md §8 and gameplay.md):
##   - Keen walks with Keen 3's sprites and speed ([Keen3MapKeen])
##   - the button uses the info cells under Keen's box: column by column,
##     row by row, the last non-zero one counts (Keen's start, 255, counts
##     as nothing); see [Keen3MapInfo]:
##       1-16 (also + 0x8000)  enters the level, unless it is done
##       20                    the ship: [signal MapSession.ship_used] (the
##                             view shows one of its four messages)
##       0x0Fsd                a teleporter ([Keen3MapTeleport])
##       0x2000-0x22FF         Messie's cells: nothing
##   - Messie ([Keen3Messie]) swims her loop; Keen gets on by walking into
##     her and off by pressing a direction toward a landing. On her back he
##     is hidden and cannot use anything
##   - a done level gets its sign, 56 on an entrance of one cell, 52-55 on
##     one of 2x2 cells (when the cell right of its first cell belongs to the
##     same level), and its info cells are cleared, which also opens the
##     cells with 0x8000
##   - the view moves as in the original ([Keen3MapScroll])
## Messie and the view are kept in the [Keen3Progress] while Keen is in a
## level. The button must be pressed anew for each use, as in Keen 1 (the
## original also acts while it is held).

## The "done" signs: one cell; 2x2 cells (top left, top right, bottom left,
## bottom right).
const KEEN_3_DONE_TILE := 56
const KEEN_3_BIG_DONE_TILES: PackedInt32Array = [52, 53, 54, 55]
const BIG_ENTRANCE_CELLS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
]
const NO_CELL := Vector2i(-1, -1)

## The part of the map the view shows.
var scroll: Keen3MapScroll
## Messie; null on a map without her path.
var messie: Keen3Messie
## The cell of each teleporter slot (0-15) found on the map.
var teleporters: Dictionary[int, Vector2i] = {}
var _keen_3_teleport: Keen3MapTeleport
var _button_was_held := false


## Keen on [param map] with [param game]: where he entered the last level,
## or at the start cell (info 255) in a new game. [param view_size] is the
## view's size in pixels.
static func opened(
	map: LevelData,
	tile_properties: TileProperties,
	game: Keen3Progress,
	view_size := Keen3MapScroll.ORIGINAL_VIEW
) -> Keen3MapSession:
	var session := Keen3MapSession.new()
	session.level = map
	session.properties = tile_properties
	session.progress = game
	session.collision = MapCollision.create_for_map(map, tile_properties, game)
	var start := game.map_position
	if not start.is_finite():
		start = Vector2(map.find_info(LevelData.PLAYER_START_INFO) * EgaGraphics.TILE_SIZE)
	session.keen = Keen3MapKeen.placed(session.collision, start)
	session.keen.sound_played.connect(session.sound_played.emit)
	for number in game.completed_levels():
		session._mark_done(number)
	session.teleporters = find_teleporters(map)
	session._set_up_messie(game)
	session._set_up_scroll(game, view_size)
	return session


## The cell of each teleporter slot on [param map]. When a slot appears
## twice, the last cell (row by row) counts, as in the original.
static func find_teleporters(map: LevelData) -> Dictionary[int, Vector2i]:
	var found: Dictionary[int, Vector2i] = {}
	for index in map.infos.size():
		var info := map.infos[index]
		if Keen3MapInfo.is_teleporter(info):
			found[Keen3MapInfo.own_slot(info)] = Vector2i(index % map.width, index / map.width)
	return found


## Advances one tick with the buttons in [param input].
func step(input: KeenInput) -> void:
	if outcome != Outcome.PLAYING:
		return
	var button := input.jump or input.pogo
	var pressed := button and not _button_was_held
	_button_was_held = button
	scroll.begin_tick()
	if _keen_3_teleport != null:
		_keen_3_teleport.step(self, scroll)
		if _keen_3_teleport.is_done():
			_keen_3_teleport = null
		return
	if messie != null:
		_swim(input)
	if is_riding():
		return
	# The original reads the cells under Keen before he moves.
	var info := info_under_keen()
	var before := keen.position
	keen.step(input)
	scroll.follow(keen.position, keen.position - before)
	_try_to_get_on()
	if pressed and not is_riding():
		_use(info)


## Whether Keen rides on Messie.
func is_riding() -> bool:
	return messie != null and messie.carrying


func is_teleporting() -> bool:
	return _keen_3_teleport != null


## The info value that the button uses where Keen stands now.
func info_under_keen() -> int:
	var cells := LevelCollision.cells_under(keen.hitbox())
	# Column by column, and in each column row by row.
	cells.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	var bounds := Rect2i(Vector2i.ZERO, Vector2i(level.width, level.height))
	var found := 0
	for cell in cells:
		if not bounds.has_point(cell) or level.info_at(cell) == 0:
			continue
		found = level.info_at(cell)
		if found == LevelData.PLAYER_START_INFO:
			found = 0
	return found


## The view is [param size] pixels now (widescreen on or off).
func set_view_size(size: Vector2) -> void:
	scroll.resize(size)


## The first cell (row by row) of the entrance of level [param number], or
## (-1, -1).
func entrance_of(number: int) -> Vector2i:
	for index in level.infos.size():
		if MapInfo.level_of(level.infos[index]) == number:
			return Vector2i(index % level.width, index / level.width)
	return NO_CELL


func _use(info: int) -> void:
	if info == 0 or Keen3MapInfo.is_messie_cell(info):
		return
	if MapInfo.is_ship(info):
		ship_used.emit()
	elif Keen3MapInfo.is_teleporter(info):
		_start_keen_3_teleport(info)
	else:
		var number := MapInfo.level_of(info)
		if number != 0 and not progress.is_completed(number):
			_enter(number)


func _enter(level_number: int) -> void:
	super._enter(level_number)
	(progress as Keen3Progress).map_corner = scroll.corner


func _start_keen_3_teleport(info: int) -> void:
	var source_slot := Keen3MapInfo.own_slot(info)
	var destination_slot := Keen3MapInfo.destination_slot(info)
	if not teleporters.has(source_slot) or not teleporters.has(destination_slot):
		return
	var source: Vector2i = teleporters[source_slot]
	_keen_3_teleport = Keen3MapTeleport.started(self, source, teleporters[destination_slot])


## Messie swims; with Keen on her back the view follows her, and a direction
## toward a landing puts him there.
func _swim(input: KeenInput) -> void:
	var before := messie.position
	messie.swim(level)
	if not messie.carrying:
		return
	scroll.follow(messie.position, messie.position - before)
	var toward := Vector2i(input.direction, input.vertical)
	if messie.landing_toward(level, toward) != NO_CELL:
		keen.position = messie.put_off(toward)
		keen.hidden = false


func _try_to_get_on() -> void:
	if messie == null or not messie.can_carry(keen.position):
		return
	messie.take_on()
	keen.hidden = true
	sound_played.emit(Sound.Id.CRYSTAL)


## Puts the "done" sign on the entrance of level [param number] and clears
## its info cells.
func _mark_done(number: int) -> void:
	var first := entrance_of(number)
	if first == NO_CELL:
		return
	var right := first + Vector2i.RIGHT
	var is_big := right.x < level.width and MapInfo.level_of(level.info_at(right)) == number
	if not is_big:
		_clear_info(first)
		set_tile(first, KEEN_3_DONE_TILE)
		return
	for corner in BIG_ENTRANCE_CELLS.size():
		var cell := first + BIG_ENTRANCE_CELLS[corner]
		_clear_info(cell)
		set_tile(cell, KEEN_3_BIG_DONE_TILES[corner])


func _clear_info(cell: Vector2i) -> void:
	level.infos[cell.y * level.width + cell.x] = 0


func _set_up_messie(game: Keen3Progress) -> void:
	if game.messie == null:
		game.messie = Keen3Messie.from_map(level)
	messie = game.messie
	keen.hidden = is_riding()


func _set_up_scroll(game: Keen3Progress, view_size: Vector2) -> void:
	var area := Rect2(LevelMap.playable_pixels(level))
	if game.map_corner.is_finite():
		scroll = Keen3MapScroll.at_corner(area, view_size, game.map_corner)
	else:
		scroll = Keen3MapScroll.showing(area, view_size, keen.position)
