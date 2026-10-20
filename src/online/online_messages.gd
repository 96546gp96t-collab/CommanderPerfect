class_name OnlineMessages
extends RefCounted
## Every message other than [Snapshot]: how it is put together, and how it
## is read back with every part checked, because it comes from the network.
## Each reader returns an empty array (or null) for a message that is not a
## sane one of its kind.

## What the host's screen shows, for [constant OnlineProtocol.Message.SCENE].
## WAITING: the host is not in a game (title, high scores, menus).
## EARTH_EXPLODES: Keen 2's Tantalus Ray hit the Earth (map 81), game over.
enum Scene { WAITING, MAP, LEVEL, GAME_OVER, ENDING, EARTH_EXPLODES }

## Things the host shows that the joiner shows too, for
## [constant OnlineProtocol.Message.EVENT].
enum Event {
	## A statue spoke; the value is the level, whose message the joiner
	## reads from his own files.
	HINT,
	## The "Keens Left" window; the value is the number of lives.
	KEENS_LEFT,
	## The ship is missing parts.
	SHIP_MISSING,
	## A short message such as "Battery in place!"; the value is the text.
	MESSAGE,
	## Keen 2: the lights of the level went off (value 1) or on (0).
	LIGHTS,
	## Keen 3: the ship spoke; the value is which of its four messages, read
	## by the joiner from his own files.
	SHIP_MESSAGE,
	## Keen 3: Mortimer starts speaking at the start of level 16 (value 1),
	## or is done (0).
	MORTIMER,
	## Keen 3: a spark or the heart of the machine was shot, and the border
	## around the picture flashes.
	BORDER_FLASH,
}

## Characters of a message that are shown at most.
const MAX_TEXT := 60
## Numbers per changed tile: x, y, tile.
const TILE_FIELDS := 3
## A level of Keen 1 is far smaller; anything larger is not one.
const MAX_CELL := 1024
const MAX_TILE := 65535


static func scene(scene_id: int, kind: Scene, number: int, tiles: PackedInt32Array) -> Array:
	return [OnlineProtocol.Message.SCENE, scene_id, kind, number, tiles]


## [scene id, kind, number, tiles] or empty.
static func read_scene(message: Array) -> Array:
	if message.size() != 5 or not _all_ints(message.slice(1, 4)):
		return []
	if message[2] < 0 or message[2] >= Scene.size() or not message[4] is PackedInt32Array:
		return []
	var tiles: PackedInt32Array = message[4]
	if tiles.size() % TILE_FIELDS != 0:
		return []
	for start in range(0, tiles.size(), TILE_FIELDS):
		if not _sane_tile(tiles[start], tiles[start + 1], tiles[start + 2]):
			return []
	return [message[1], message[2], message[3], tiles]


static func tile(scene_id: int, cell: Vector2i, tile_number: int) -> Array:
	return [OnlineProtocol.Message.TILE, scene_id, cell.x, cell.y, tile_number]


## [scene id, cell, tile] or empty.
static func read_tile(message: Array) -> Array:
	if message.size() != 5 or not _all_ints(message.slice(1)):
		return []
	if not _sane_tile(message[2], message[3], message[4]):
		return []
	return [message[1], Vector2i(message[2], message[3]), message[4]]


static func event(scene_id: int, kind: Event, value: Variant) -> Array:
	return [OnlineProtocol.Message.EVENT, scene_id, kind, value]


## [scene id, kind, value] or empty. The value of a message is plain text.
static func read_event(message: Array) -> Array:
	if message.size() != 4 or not message[1] is int or not message[2] is int:
		return []
	if message[2] < 0 or message[2] >= Event.size():
		return []
	if message[2] == Event.MESSAGE:
		if not message[3] is String:
			return []
		return [message[1], message[2], _plain(message[3])]
	if not message[3] is int:
		return []
	return [message[1], message[2], message[3]]


static func input(bits: int) -> Array:
	return [OnlineProtocol.Message.INPUT, bits]


## The bits, or -1.
static func read_input(message: Array) -> int:
	if message.size() != 2 or not message[1] is int:
		return -1
	return message[1] & OnlineInput.ALL_BITS


static func view(rect: Rect2) -> Array:
	return [OnlineProtocol.Message.VIEW, rect.position.x, rect.position.y, rect.size.x, rect.size.y]


## The rectangle, or an empty one. No larger than a big screen.
static func read_view(message: Array) -> Rect2:
	if message.size() != 5:
		return Rect2()
	for index in range(1, 5):
		if not (message[index] is float or message[index] is int):
			return Rect2()
	var rect := Rect2(message[1], message[2], message[3], message[4])
	if not rect.position.is_finite() or not rect.size.is_finite():
		return Rect2()
	rect.size = rect.size.clamp(Vector2.ZERO, Vector2(MAX_CELL, MAX_CELL))
	return rect


static func _all_ints(values: Array) -> bool:
	return values.all(func(value: Variant) -> bool: return value is int)


static func _sane_tile(x: int, y: int, tile_number: int) -> bool:
	return (
		x >= 0
		and y >= 0
		and x < MAX_CELL
		and y < MAX_CELL
		and tile_number >= 0
		and tile_number <= MAX_TILE
	)


## Only printable characters, cut to length.
static func _plain(text: String) -> String:
	var kept := ""
	for index in mini(text.length(), MAX_TEXT):
		var code := text.unicode_at(index)
		if code >= PlayerName.FIRST_PRINTABLE and code <= PlayerName.LAST_PRINTABLE:
			kept += String.chr(code)
	return kept
