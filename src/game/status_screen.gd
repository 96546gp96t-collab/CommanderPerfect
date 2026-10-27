class_name StatusScreen
extends RefCounted
## Fills a [GameWindow] with what Keen carries, like the status screen of the
## original game: score, lives, raygun charges, the pogo stick, keycards and
## ship parts. Things Keen does not have yet are drawn faintly.

const SIZE := Vector2i(30, 14)
const RAYGUN_TILE := 175
const POGO_TILE := 176
## The first tile of each keycard and ship part, in the order of
## [enum TileProperties.KeyColor] and [enum Inventory.ShipPart].
const KEYCARD_TILES: PackedInt32Array = [190, 191, 192, 193]
const SHIP_PART_TILES: PackedInt32Array = [221, 237, 241, 245]
## Columns where the four keycards and ship parts are drawn.
const ITEM_COLUMNS: PackedInt32Array = [12, 15, 18, 21]
const RIGHT_EDGE := 30
## Each label and where it starts, and the room it has before what follows
## it (a number, a tile or the edge): a translation must fit in that room,
## as the columns are the original's.
const LABEL_CELLS: Dictionary[String, Vector2i] = {
	"SCORE": Vector2i(0, 0),
	"NEXT KEEN": Vector2i(14, 0),
	"LIVES": Vector2i(0, 2),
	"GOD MODE": Vector2i(14, 2),
	"RAYGUN": Vector2i(0, 5),
	"POGO": Vector2i(17, 5),
	"KEYCARDS": Vector2i(0, 8),
	"SHIP PARTS": Vector2i(0, 11),
}
const LABEL_ROOM: Dictionary[String, int] = {
	"SCORE": 5,
	"NEXT KEEN": 10,
	"LIVES": 8,
	"GOD MODE": 16,
	"RAYGUN": 6,
	"POGO": 5,
	"KEYCARDS": 11,
	"SHIP PARTS": 11,
	"PRESS ENTER": SIZE.x,
}
## The last row: "PRESS ENTER" in the middle.
const PROMPT := "PRESS ENTER"
const PROMPT_ROW := 13


static func fill(window: GameWindow, inventory: Inventory, god_mode: bool) -> void:
	window.open(SIZE)
	_put_label(window, "SCORE")
	window.put_text_right(11, 0, str(inventory.score))
	_put_label(window, "NEXT KEEN")
	window.put_text_right(RIGHT_EDGE, 0, str(inventory.next_extra_life()))
	_put_label(window, "LIVES")
	window.put_text_right(11, 2, str(maxi(inventory.lives, 0)))
	if god_mode:
		_put_label(window, "GOD MODE")

	_put_label(window, "RAYGUN")
	window.put_tile(Vector2i(7, 4), RAYGUN_TILE, inventory.charges == 0)
	window.put_text(Vector2i(10, 5), "x %d" % inventory.charges)
	_put_label(window, "POGO")
	window.put_tile(Vector2i(22, 4), POGO_TILE, not inventory.has_pogo)

	_put_label(window, "KEYCARDS")
	for color in KEYCARD_TILES.size():
		window.put_tile(
			Vector2i(ITEM_COLUMNS[color], 7), KEYCARD_TILES[color], not inventory.keycards[color]
		)
	_put_label(window, "SHIP PARTS")
	for part in SHIP_PART_TILES.size():
		window.put_tile(
			Vector2i(ITEM_COLUMNS[part], 10), SHIP_PART_TILES[part], not inventory.ship_parts[part]
		)
	var prompt := label(PROMPT)
	window.put_text(Vector2i((SIZE.x - prompt.length()) / 2, PROMPT_ROW), prompt)


## The label [param english] in the language in use, cut to its room.
static func label(english: String) -> String:
	return Lang.text(english).left(LABEL_ROOM[english])


static func _put_label(window: GameWindow, english: String) -> void:
	window.put_text(LABEL_CELLS[english], label(english))
