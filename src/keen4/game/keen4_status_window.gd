class_name Keen4StatusWindow
extends GalaxyStatusWindow
## Keen 4's status window (Enter; Omni `ck_play.c:CK_DrawStatusWindow`,
## facts and numbers only; compared with the original, D7): the Galaxy
## window ([GalaxyStatusWindow], since milestone E13) with Keen 4's own
## rows:
##   - RESCUED (one icon per council member) at the left of LEVEL;
##   - below the counts the wetsuit's word on a white bar ("???" without
##     it).
## The "press a key" tiles start at (160, 140), the window's default.

## Keen 4's labels of the status run beyond the shared ones: RESCUED is
## the episode's own row, the wetsuit's two words follow the drops.
const RESCUED_TEXT := Text.MIDDLE
const WETSUIT_TEXT := 12
const NO_WETSUIT_TEXT := 13
## A rescued member's 8×8 tile, the bar of the rescued, the wetsuit's bar
## and the top of its word.
const RESCUED_ICON := 40
const RESCUED_BAR := Rect2i(79, 95, 66, 10)
const WETSUIT_BAR := Rect2i(79, 143, 66, 10)
const WETSUIT_TOP := 144
const KEY_TILES_AT := KEEN_4_KEY_TILES_AT


## The window of [param data] by Keen 4's rules (or [param game_rules]).
static func create(data: GalaxyData, game_rules: GalaxyGameRules = null) -> Keen4StatusWindow:
	var window := Keen4StatusWindow.new()
	window.use_data(data, game_rules if game_rules != null else Keen4Episode.game_rules())
	return window


## RESCUED: one icon per council member rescued.
func _draw_middle(_inventory: GalaxyInventory, progress: GalaxyProgress) -> void:
	_column_label(RESCUED_TEXT, LEFT, MIDDLE_LABELS)
	_screen.fill_rect(RESCUED_BAR, BLACK)
	var keen_4 := progress as Keen4Progress
	var rescued := keen_4.rescued if keen_4 != null else 0
	for member in rescued:
		_tile(RESCUED_ICON, RESCUED_BAR.position + Vector2i(1 + CELL * member, 1))


## The wetsuit's word, or "???" without it.
func _draw_bottom(_inventory: GalaxyInventory, progress: GalaxyProgress) -> void:
	_screen.fill_rect(WETSUIT_BAR, WHITE)
	var keen_4 := progress as Keen4Progress
	var suit := WETSUIT_TEXT if keen_4 != null and keen_4.wetsuit else NO_WETSUIT_TEXT
	_centred(label(suit), LEFT, COLUMN_WIDTH, WETSUIT_TOP, BLACK)
