class_name GalaxyGameBoxes
extends RefCounted
## The boxes of a Galaxy episode between its maps (made from Keen 4's
## [Keen4GameBoxes], milestone E6; Omni `ck_game.c`: CK_BeginCacheBox,
## CK_UpdateCacheBox, CK_TryAgainMenu, CK_GameOver, CK_GameLoop's "One
## moment"; facts only; seen in the original, D7 and E6), each a 320 × 200
## picture with a [GalaxyWindow] on it:
##   - while a map "loads": a window of 26 × 8 cells with Keen's count-down
##     picture at its left and a text centred in the rest, a little above
##     the middle (the map's "Keen enters ..." text, "DEMO", Keen 5's
##     arrival on Korath III); his fingers count down (five small pictures
##     over the big one);
##   - "One moment" when Keen leaves the world map (the same window, the
##     text 25 pixels down, centred);
##   - after a death: "You didn't make it past" the level, "Try Again" and
##     the way back to the map ("Exit to Shadowlands", "Exit to
##     Armageddon") in a window of 20 × 8 cells; the choice has a frame of
##     2 pixels that blinks light red and blue every 16 tics;
##   - "Game Over!" in a window of 16 × 3 cells, when the episode has that
##     text (Keen 5 shows a scene instead: none).
## The texts are the player's own (the rules' game run, the level names
## and entry texts); the count-down pictures are counted from the end of
## the picture range ([member GalaxyGameRules.countdown_from_end]).

const WINDOW_CELLS := Vector2i(26, 8)
## The box after a game is loaded (Omni).
const PAUSED_TEXT := "PAUSED"
const PAUSED_MARGIN_CELLS := 2
const PAUSED_CELLS_HIGH := 3
const PICTURE_WIDTH := 0x30
## The whole count-down picture, then the fingers 4 … 0 follow it (Omni
## PIC_COUNTDOWN5-0).
const FINGER_PICTURES := 5
## The fingers go here, from the window's corner (Omni: 24 left of the
## text area, 40 down).
const FINGERS_AT := Vector2i(PICTURE_WIDTH - 24, 40)
## The loading text sits this much above the middle of the window (Omni).
const TEXT_RAISE := 4
## "One moment" goes this far down (Omni).
const ONE_MOMENT_DOWN := 25
## The box after a death (Omni CK_TryAgainMenu).
const TRY_AGAIN_CELLS := Vector2i(20, 8)
const INTRO_DOWN := 3
const CHOICE_GAP := 22
const SHORT_NAME := 15
const SHORT_NAME_DOWN := 4
const FIRST_CHOICE_DOWN := 2
const SECOND_CHOICE_DOWN := 4
const CHOICE_FRAME_INSET := 4
const CHOICE_FRAME_HEIGHT := 14
const CHOICE_FRAME_WIDTH := 2
const CHOICE_TOP_ABOVE_TEXT := 2
## The blinking colours (Omni: EGA 12 and 1, every 16 tics).
const BLINK_ON := Color8(255, 85, 85)
const BLINK_OFF := Color8(0, 0, 170)
const BLINK_SHIFT := 4
const GAME_OVER_CELLS := Vector2i(16, 3)

var _rules: GalaxyGameRules
var _graphics: GalaxyGraphics
var _names := PackedStringArray()
var _entries := PackedStringArray()
var _game := PackedStringArray()
var _picture_count := 0


## The boxes of [param data] for the episode of [param game_rules]; into
## [param into] when given (a subclass: [GalaxyNamedBoxes]).
static func create(
	data: GalaxyData, game_rules: GalaxyGameRules, into: GalaxyGameBoxes = null
) -> GalaxyGameBoxes:
	var boxes := into if into != null else GalaxyGameBoxes.new()
	boxes._rules = game_rules
	boxes._graphics = data.graphics
	boxes._names = data.executable.level_names()
	boxes._entries = data.executable.entry_texts()
	boxes._game = data.executable.texts(game_rules.game_texts)
	boxes._picture_count = data.graphics.ranges.picture_count
	return boxes


## Text [param index] of the episode's game run ("" when there is none).
func game_text(index: int) -> String:
	return _text(_game, index)


## The box when Keen enters map [param map]: the first screen with the
## whole count-down picture, then one per finger counted down (Omni
## CK_BeginCacheBox, CK_UpdateCacheBox).
func entering(map: int) -> Array[Image]:
	return loading(_text(_entries, map))


## The same box before a demo, with the text "DEMO" (Omni CK_LoadLevel).
func demo_entering() -> Array[Image]:
	return loading(game_text(_rules.demo_text))


## The box while a map loads with [param text] (see [method entering]).
func loading(text: String) -> Array[Image]:
	var window := _window()
	window.open_centred(WINDOW_CELLS)
	window.draw_picture(_picture(_rules.countdown_from_end), Vector2i.ZERO)
	window.narrow(PICTURE_WIDTH, 0)
	window.skip((window.inside.size.y - window.text_height(text)) / 2 - TEXT_RAISE)
	window.print_centred(text)
	var screens: Array[Image] = [window.image()]
	for finger in FINGER_PICTURES:
		window.draw_picture(_picture(_rules.countdown_from_end - 1 - finger), FINGERS_AT)
		screens.append(window.image())
	return screens


## The loading box with text [param index] of the game run (Keen 5's
## arrival on Korath III).
func loading_game_text(index: int) -> Array[Image]:
	return loading(game_text(index))


## "PAUSED" after a game is loaded, until a key (Omni CK_PlayLoop).
func paused() -> Image:
	var window := _window()
	window.open_centred(Vector2i(PAUSED_TEXT.length() + PAUSED_MARGIN_CELLS, PAUSED_CELLS_HIGH))
	window.print_in_middle(PAUSED_TEXT)
	return window.image()


## "One moment", when Keen leaves the world map (Omni CK_GameLoop; centred
## as the original shows it).
func one_moment() -> Image:
	var window := _window()
	window.open_centred(WINDOW_CELLS)
	window.skip(ONE_MOMENT_DOWN)
	window.print_centred(game_text(_rules.one_moment_text))
	return window.image()


## The box after a death in map [param map], with choice [param choice]
## (0 try again, 1 exit) framed in the colour of tic [param tic] (Omni
## CK_TryAgainMenu).
func try_again(map: int, choice: int, tic: int) -> Image:
	var window := _window()
	window.open_centred(TRY_AGAIN_CELLS)
	window.skip(INTRO_DOWN)
	window.print_centred(game_text(_rules.try_again_intro_text))
	var first := window.print_y + CHOICE_GAP
	var name := _text(_names, map)
	if window.text_height(name) < SHORT_NAME:
		window.skip(SHORT_NAME_DOWN)
	window.print_centred(name)
	window.print_y = first + FIRST_CHOICE_DOWN
	window.print_centred(game_text(_rules.try_again_text))
	window.skip(SECOND_CHOICE_DOWN)
	var second := window.print_y - CHOICE_TOP_ABOVE_TEXT
	window.print_centred(game_text(_rules.exit_text))
	var top := second if choice != 0 else first
	var frame := Rect2i(
		window.inside.position.x + CHOICE_FRAME_INSET,
		top,
		window.inside.size.x - 2 * CHOICE_FRAME_INSET + 1,
		CHOICE_FRAME_HEIGHT
	)
	window.outline(frame, CHOICE_FRAME_WIDTH, blink_color(tic))
	return window.image()


## The colour of the choice's frame at tic [param tic].
static func blink_color(tic: int) -> Color:
	return BLINK_ON if (tic >> BLINK_SHIFT) & 1 == 1 else BLINK_OFF


## "Game Over!" (Omni CK_GameOver); null when the episode has no such text.
func game_over() -> Image:
	if _rules.game_over_text < 0:
		return null
	var window := _window()
	window.open_centred(GAME_OVER_CELLS)
	window.print_in_middle(game_text(_rules.game_over_text))
	return window.image()


func _window() -> GalaxyWindow:
	return GalaxyWindow.create(_graphics, _rules.menu_font)


func _picture(from_end: int) -> int:
	return _picture_count - from_end


static func _text(texts: PackedStringArray, index: int) -> String:
	return texts[index] if index >= 0 and index < texts.size() else ""
