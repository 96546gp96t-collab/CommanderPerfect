class_name MapTeleport
extends RefCounted
## A teleporter on the world map taking Keen somewhere else. Three phases:
##   leaving    the teleporter at the start flickers, Keen still stands on it
##   traveling  Keen, not drawn, moves to the destination; the view follows
##   arriving   the teleporter at the destination flickers
## The flicker cycles four tiles in place of the teleporter: 342-345 for the
## one on the ice (tile 99), 338-341 for the one on red ground (tile 325).

enum Phase { LEAVING, TRAVELING, ARRIVING, DONE }

const ICE_TELEPORTER_TILE := 99
const ICE_FLICKER_TILE := 342
const GROUND_FLICKER_TILE := 338
const FLICKER_FRAMES := 4
## Ticks per flicker frame, and how many frames the flicker lasts.
## From the published constants of Commander Genius; still to be compared
## with the original.
const FLICKER_FRAME_TICKS := 2
const FLICKER_FRAME_COUNT := 20
## Pixels per tick while traveling (4 pixels, from Commander Genius).
const TRAVEL_SPEED := 4.0

var phase := Phase.LEAVING
var destination := Vector2.ZERO
var _cell := Vector2i.ZERO
var _idle_tile := 0
var _frame_count := 0
var _timer := 0


## Starts at the teleporter in [param from_cell], or with traveling when
## [param from_cell] is not a teleporter (Keen comes out of a level).
static func create(session: MapSession, from_cell: Vector2i, to_cell: Vector2i) -> MapTeleport:
	var teleport := MapTeleport.new()
	teleport.destination = Vector2(to_cell * EgaGraphics.TILE_SIZE)
	if MapInfo.is_teleporter(session.level.info_at(from_cell)):
		teleport._start_flicker(session, from_cell)
	else:
		teleport.phase = Phase.TRAVELING
		session.keen.hidden = true
	return teleport


func step(session: MapSession) -> void:
	match phase:
		Phase.LEAVING, Phase.ARRIVING:
			_flicker(session)
		Phase.TRAVELING:
			_travel(session)


func is_done() -> bool:
	return phase == Phase.DONE


func _start_flicker(session: MapSession, cell: Vector2i) -> void:
	_cell = cell
	_idle_tile = session.level.tile_at(cell)
	_frame_count = 0
	_timer = 0
	session.set_tile(cell, _flicker_tile(0))


func _flicker(session: MapSession) -> void:
	_timer += 1
	if _timer < FLICKER_FRAME_TICKS:
		return
	_timer = 0
	_frame_count += 1
	if _frame_count <= FLICKER_FRAME_COUNT:
		session.set_tile(_cell, _flicker_tile(_frame_count % FLICKER_FRAMES))
		return
	session.set_tile(_cell, _idle_tile)
	if phase == Phase.LEAVING:
		phase = Phase.TRAVELING
		session.keen.hidden = true
	else:
		phase = Phase.DONE


func _travel(session: MapSession) -> void:
	var keen := session.keen
	# Each axis moves at full speed until it is there (as in Commander Genius).
	var limit := Vector2(TRAVEL_SPEED, TRAVEL_SPEED)
	keen.position += (destination - keen.position).clamp(-limit, limit)
	if keen.position != destination:
		return
	keen.hidden = false
	keen.facing = Vector2i.DOWN
	phase = Phase.ARRIVING
	_start_flicker(session, Vector2i(destination) / EgaGraphics.TILE_SIZE)


func _flicker_tile(frame: int) -> int:
	var first := ICE_FLICKER_TILE if _idle_tile == ICE_TELEPORTER_TILE else GROUND_FLICKER_TILE
	return first + frame
