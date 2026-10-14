class_name MapMessages
extends RefCounted
## Fills a [GameWindow] with the messages of the world map: how many lives
## Keen has left, and which parts his ship is still missing.

const LIVES_TITLE := "Keens Left"
## Keen on the map, looking at the player, stands for one life.
const LIFE_SPRITE := MapKeen.SPRITE_DOWN
## Cells per life picture; at most [constant MAX_LIVES_SHOWN] are drawn.
const LIFE_CELLS := 2
const MAX_LIVES_SHOWN := 10
## The pictures of the joystick, battery, vacuum cleaner and whiskey in the
## message of the ship (in the order of [enum Inventory.ShipPart]).
const PART_TILES: PackedInt32Array = [321, 322, 323, 324]
## Row and columns of those pictures in the message.
const PART_ROW := 3
const PART_COLUMNS: PackedInt32Array = [3, 7, 11, 15]


## "Keens Left", with a little Keen for every life.
static func show_lives(window: GameWindow, lives: int) -> void:
	var shown := clampi(lives, 0, MAX_LIVES_SHOWN)
	var width := maxi(LIVES_TITLE.length(), shown * LIFE_CELLS)
	window.open(Vector2i(width, 3))
	window.put_text(Vector2i((width - LIVES_TITLE.length()) / 2, 0), LIVES_TITLE)
	var first := (width - shown * LIFE_CELLS) / 2
	for life in shown:
		window.put_sprite(Vector2i(first + life * LIFE_CELLS, 1), LIFE_SPRITE)


## [param lines] is the message from [EndingTexts]; only the parts that
## Keen does not have yet are drawn in it.
static func show_missing_parts(
	window: GameWindow, lines: PackedStringArray, inventory: Inventory
) -> void:
	window.show_lines(lines)
	for part in PART_TILES.size():
		if not inventory.ship_parts[part]:
			window.put_tile(Vector2i(PART_COLUMNS[part], PART_ROW), PART_TILES[part])
