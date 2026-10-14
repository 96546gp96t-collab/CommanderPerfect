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


static func fill(window: GameWindow, inventory: Inventory, god_mode: bool) -> void:
	window.open(SIZE)
	window.put_text(Vector2i(0, 0), "SCORE")
	window.put_text_right(11, 0, str(inventory.score))
	window.put_text(Vector2i(14, 0), "NEXT KEEN")
	window.put_text_right(RIGHT_EDGE, 0, str(inventory.next_extra_life()))
	window.put_text(Vector2i(0, 2), "LIVES")
	window.put_text_right(11, 2, str(maxi(inventory.lives, 0)))
	if god_mode:
		window.put_text(Vector2i(14, 2), "GOD MODE")

	window.put_text(Vector2i(0, 5), "RAYGUN")
	window.put_tile(Vector2i(7, 4), RAYGUN_TILE, inventory.charges == 0)
	window.put_text(Vector2i(10, 5), "x %d" % inventory.charges)
	window.put_text(Vector2i(17, 5), "POGO")
	window.put_tile(Vector2i(22, 4), POGO_TILE, not inventory.has_pogo)

	window.put_text(Vector2i(0, 8), "KEYCARDS")
	for color in KEYCARD_TILES.size():
		window.put_tile(
			Vector2i(ITEM_COLUMNS[color], 7), KEYCARD_TILES[color], not inventory.keycards[color]
		)
	window.put_text(Vector2i(0, 11), "SHIP PARTS")
	for part in SHIP_PART_TILES.size():
		window.put_tile(
			Vector2i(ITEM_COLUMNS[part], 10), SHIP_PART_TILES[part], not inventory.ship_parts[part]
		)
	window.put_text(Vector2i(9, 13), "PRESS ENTER")
