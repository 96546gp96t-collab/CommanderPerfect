class_name Keen3MapTeleport
extends RefCounted
## A teleporter of Keen 3's world map at work (Choco
## `CVort3_worldmap_sprites`; docs/keen3/research.md §8). Keen 1's
## [MapTeleport] does not fit: it flies Keen across the map and flickers
## Keen 1's tiles. Here, while everything else stands still (Messie too):
##   source       the teleporter Keen used cycles tiles 130-133 twice, with
##                TELEPORTSND at the start of each cycle, then shows 134
##   destination  the view jumps so that the destination teleporter is 10
##                cells from the left and 6 from the top
##                ([method Keen3MapScroll.show_destination]); the same
##                animation there
##   done         Keen stands on the destination cell (the top left of his
##                sprite on its top left)
## Keen is not drawn meanwhile (seen in js-dos: he disappears from the
## source and appears on the destination after its last tile). Each tile
## shows 5 retraces (71 ms; seen in js-dos), 1.14 s in all.

enum Phase { SOURCE, DESTINATION, DONE }

const FIRST_TILE := 130
const TILES := 4
const CYCLES := 2
## The teleporter at rest.
const RESTING_TILE := 134
## Ticks each tile shows: 5 retraces of 70.086 Hz (the original waits 4
## after drawing it, and one more for its next frame; seen in js-dos).
const TILE_TICKS := 5.0 / 70.086 * 60.0

var phase := Phase.SOURCE
var source := Vector2i.ZERO
var destination := Vector2i.ZERO
var _step := 0
var _ticks := 0.0


## Keen uses the teleporter at [param from_cell] to go to [param to_cell].
## The first tile is shown at once.
static func started(
	session: MapSession, from_cell: Vector2i, to_cell: Vector2i
) -> Keen3MapTeleport:
	var teleport := Keen3MapTeleport.new()
	teleport.source = from_cell
	teleport.destination = to_cell
	teleport._show_step(session, from_cell)
	session.keen.hidden = true
	return teleport


## One tick. [param scroll] is the view that jumps to the destination.
func step(session: MapSession, scroll: Keen3MapScroll) -> void:
	if phase == Phase.DONE:
		return
	_ticks += 1.0
	if _ticks < TILE_TICKS:
		return
	_ticks -= TILE_TICKS
	_step += 1
	var at := source if phase == Phase.SOURCE else destination
	if _step < TILES * CYCLES:
		_show_step(session, at)
		return
	session.set_tile(at, RESTING_TILE)
	_step = 0
	if phase == Phase.SOURCE:
		phase = Phase.DESTINATION
		scroll.show_destination(destination)
		_show_step(session, destination)
	else:
		phase = Phase.DONE
		session.keen.position = Vector2(destination * EgaGraphics.TILE_SIZE)
		session.keen.hidden = false


func is_done() -> bool:
	return phase == Phase.DONE


func _show_step(session: MapSession, at: Vector2i) -> void:
	session.set_tile(at, FIRST_TILE + _step % TILES)
	if _step % TILES == 0:
		session.sound_played.emit(Sound.Id.TELEPORT)
