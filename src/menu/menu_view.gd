class_name MenuView
extends RefCounted
## Fills a [GameWindow] with a [Menu]: its header lines, an empty line, and
## the choices, with the spinning ball of the font as the cursor in front
## of the current one. Choices that cannot be picked are left out of the
## cursor's way but still shown.

## Font characters 9-15 are the frames of a spinning ball.
const CURSOR_FIRST_CHAR := 9
const CURSOR_FRAMES := 7
## Seconds per frame of the spinning ball.
const CURSOR_FRAME_SECONDS := 0.08
## Columns in front of each choice: room for the ball and a space.
const ITEM_INDENT := 2


## Shows [param menu] in [param window]; [param seconds] turns the ball.
static func fill(window: GameWindow, menu: Menu, seconds: float) -> void:
	var rows := menu.header.size() + menu.items.size()
	if not menu.header.is_empty():
		rows += 1
	window.open(Vector2i(menu.width(), rows))
	for row in menu.header.size():
		window.put_text(Vector2i(0, row), menu.header[row])
	var first := menu.header.size() + (1 if not menu.header.is_empty() else 0)
	for index in menu.items.size():
		var item := menu.items[index]
		window.put_text(Vector2i(ITEM_INDENT, first + index), item.label)
		if index == menu.cursor and item.enabled:
			window.put_text(Vector2i(0, first + index), String.chr(cursor_char(seconds)))


static func cursor_char(seconds: float) -> int:
	return CURSOR_FIRST_CHAR + int(seconds / CURSOR_FRAME_SECONDS) % CURSOR_FRAMES
