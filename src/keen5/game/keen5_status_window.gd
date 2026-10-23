class_name Keen5StatusWindow
extends GalaxyStatusWindow
## Keen 5's status window (Enter; milestone E6; Omni
## `ck_play.c:CK_DrawStatusWindow`, facts and numbers only; compared with
## the original v1.4 to the pixel, E6): the Galaxy window
## ([GalaxyStatusWindow]) with Keen 5's own row, KEYCARD printed from
## (80, 92) beside a black square at (135, 91) of 10 × 10 pixels that shows
## the card (8×8 tile 40 at (136, 92)) while Keen has it (the original
## draws the row one pixel lower than Omnispeak's 91 and 90); no
## wetsuit and no rescued members; the "press a key" tiles start at
## (120, 140). The drops are Keen 5's Vitalin (its own label).

## The keycard's label, square and tile (seen in the original, E6;
## Omnispeak has them a pixel higher).
const KEYCARD_LABEL_AT := Vector2i(80, 92)
const KEYCARD_BOX := Rect2i(135, 91, 10, 10)
const KEYCARD_TILE := 40
const KEYCARD_TILE_AT := Vector2i(136, 92)
## Where the "press a key" tiles are in Keen 5 (Omni).
const KEY_TILES_AT := Vector2i(120, 140)


static func create_keen5(data: GalaxyData, game_rules: GalaxyGameRules) -> Keen5StatusWindow:
	var window := Keen5StatusWindow.new()
	window.use_data(data, game_rules)
	window.key_tiles_at = KEY_TILES_AT
	return window


func _draw_middle(inventory: GalaxyInventory, _progress: GalaxyProgress) -> void:
	_print(label(Text.MIDDLE), KEYCARD_LABEL_AT, DARK_GREY)
	_screen.fill_rect(KEYCARD_BOX, BLACK)
	var carried := inventory as Keen5Inventory
	if carried != null and carried.keycard:
		_tile(KEYCARD_TILE, KEYCARD_TILE_AT)
