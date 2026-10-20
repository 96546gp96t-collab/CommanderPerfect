class_name GalaxySnapshot
extends RefCounted
## What the player who joins sees of one logic frame of a Galaxy game
## (milestone D12), the Galaxy counterpart of Keen 1-3's [Snapshot]: where
## his view is, every sprite drawn (objects and their overlays, the Keens
## marked), the sounds of the frame, the song, the screen's brightness and
## the box shown (an episode's description of it, which the joiner draws
## from his own files), and the episode's own numbers ([member extra]: Keen
## 4's inventory and progress, [Keen4OnlineState]). The host sends one
## every frame, unreliably; a lost one is replaced by the next.
##
## On the wire it is a short array of packed numbers ([method to_message]);
## [method from_message] checks every part.

## Numbers per figure: x, y (units), sprite, flags.
const FIGURE_FIELDS := 4
## The flags: the drawing priority in the low bits, then which Keen it is.
const PRIORITY_MASK := 3
const HOST_KEEN := 4
const PARTNER_KEEN := 8
const FLAG_MASK := 15
## More than this is not a level but somebody's attack.
const MAX_FIGURES := 512
const MAX_SOUNDS := 64
const MAX_BOX := 8
const MAX_EXTRA := 32
const MAX_SPRITE := 4096
const MAX_SONG := 63
const FULL_BRIGHTNESS := 100
## Positions (units) stay within a map of 1024 tiles a side, give or take.
const MAX_UNITS := GalaxyOnlineMessages.MAX_CELL * GalaxyUnits.PER_TILE
const PARTS := 10
## Added to a sound's number when it stops the sound playing.
const INTERRUPT := 128

var scene := 0
## The top left of the joiner's view, in units.
var view := Vector2i.ZERO
## x, y, sprite, flags for every sprite drawn.
var figures := PackedInt32Array()
## The sounds of the frame: the sound's number, plus [constant INTERRUPT]
## when it stops the one playing.
var sounds := PackedByteArray()
var song := -1
## 0 (black) to [constant FULL_BRIGHTNESS].
var brightness := FULL_BRIGHTNESS
## The box shown, as the episode describes it; empty: none.
var box := PackedInt32Array()
var extra := PackedInt32Array()


## Adds a sprite: [param sprite] at [param at] (units) with [param flags].
func add_figure(at: Vector2i, sprite: int, flags: int) -> void:
	if figures.size() < MAX_FIGURES * FIGURE_FIELDS:
		figures.append_array([at.x, at.y, sprite, flags & FLAG_MASK])


## Adds the sprites of [param objects] as [GalaxyObjectLayer] draws them:
## every awake object with a sprite, and its overlays; [param host] and
## [param partner] are the two Keens.
func add_objects(
	objects: Array[GalaxyObject], host: GalaxyObject = null, partner: GalaxyObject = null
) -> void:
	for object in objects:
		if not GalaxyWorld.is_awake(object) or object.hidden:
			continue
		var flags := clampi(object.priority, 0, PRIORITY_MASK)
		if object == host:
			flags |= HOST_KEEN
		elif object == partner and partner != null:
			flags |= PARTNER_KEEN
		if object.sprite != GalaxyObject.NO_SPRITE:
			add_figure(object.position + object.draw_offset, object.sprite, flags)
		for overlay in object.overlays:
			if overlay.sprite != GalaxyObject.NO_SPRITE:
				add_figure(object.position + overlay.offset, overlay.sprite, overlay.priority)


func figure_count() -> int:
	return figures.size() / FIGURE_FIELDS


func to_message() -> Array:
	return [
		OnlineProtocol.Message.GALAXY_SNAPSHOT,
		scene,
		view.x,
		view.y,
		figures,
		sounds,
		song,
		brightness,
		box,
		extra,
	]


## The snapshot in [param message], or null when it is not a sane one.
static func from_message(message: Array) -> GalaxySnapshot:
	if message.size() != PARTS:
		return null
	for index in [1, 2, 3, 6, 7]:
		if not message[index] is int:
			return null
	if not (
		message[4] is PackedInt32Array
		and message[5] is PackedByteArray
		and message[8] is PackedInt32Array
		and message[9] is PackedInt32Array
	):
		return null
	var snapshot := GalaxySnapshot.new()
	snapshot.scene = message[1]
	snapshot.view = Vector2i(message[2], message[3])
	snapshot.figures = message[4]
	snapshot.sounds = message[5]
	snapshot.song = message[6]
	snapshot.brightness = message[7]
	snapshot.box = message[8]
	snapshot.extra = message[9]
	return snapshot if snapshot._is_sane() else null


func _is_sane() -> bool:
	var sizes_fit := (
		sounds.size() <= MAX_SOUNDS
		and box.size() <= MAX_BOX
		and extra.size() <= MAX_EXTRA
		and figures.size() % FIGURE_FIELDS == 0
		and figures.size() <= MAX_FIGURES * FIGURE_FIELDS
	)
	var numbers_fit := (
		_in_map(view.x)
		and _in_map(view.y)
		and song >= -1
		and song <= MAX_SONG
		and brightness >= 0
		and brightness <= FULL_BRIGHTNESS
	)
	return sizes_fit and numbers_fit and _figures_are_sane()


func _figures_are_sane() -> bool:
	for start in range(0, figures.size(), FIGURE_FIELDS):
		var sprite := figures[start + 2]
		var flags := figures[start + 3]
		if not _in_map(figures[start]) or not _in_map(figures[start + 1]):
			return false
		if sprite < 0 or sprite >= MAX_SPRITE or flags < 0 or flags > FLAG_MASK:
			return false
	return true


static func _in_map(units: int) -> bool:
	return units > -MAX_UNITS and units < MAX_UNITS
