class_name Keen4GameBoxes
extends RefCounted
## The boxes of Keen 4 between the levels (milestone D7; Omni `ck_game.c`:
## CK_BeginCacheBox, CK_UpdateCacheBox, CK_TryAgainMenu, CK_GameOver,
## CK_GameLoop's "One moment"; `ck4_misc.c:CK4_ShowCantSwimMessage`; facts
## only; seen in the original, D7), each a 320 × 200 picture with a
## [GalaxyWindow] on it:
##   - entering a map: a window of 26 × 8 cells with Keen's count-down
##     picture at its left and the map's "Keen enters ..." text centred in
##     the rest, a little above the middle; while the map "loads" his
##     fingers count down (five small pictures over the big one);
##   - "One moment" when Keen leaves the world map (the same window, the
##     text 25 pixels down, centred: seen in the original, D7, where
##     Omnispeak prints it from the left);
##   - "I can't swim!" (Keen talking on the right, the text 12 down: seen
##     in the original, D7; Omnispeak 6);
##   - after a death: "You didn't make it past" the level, "Try Again" and
##     "Exit to Shadowlands" in a window of 20 × 8 cells; the choice has a
##     frame of 2 pixels that blinks light red and blue every 16 tics;
##   - "Game Over!" in a window of 16 × 3 cells.
## The texts are the player's own ([Keen4Episode.GAME_TEXTS], the level
## names and entry texts, the council messages); the pictures the last of
## the picture range.

const WINDOW_CELLS := Vector2i(26, 8)
const PICTURE_WIDTH := 0x30
## Keen counting down, from the end of the picture range: the whole
## picture (5), then the fingers 4 … 0 (Omni PIC_COUNTDOWN5-0).
const COUNTDOWN_FROM_END := 6
const FINGER_PICTURES := 5
## The fingers go here, from the window's corner (Omni: 24 left of the
## text area, 40 down).
const FINGERS_AT := Vector2i(PICTURE_WIDTH - 24, 40)
## The entry text sits this much above the middle of the window (Omni).
const TEXT_RAISE := 4
## "One moment" goes this far down (Omni), "I can't swim!" this far
## (seen in the original, D7).
const ONE_MOMENT_DOWN := 25
const CANT_SWIM_DOWN := 12
const KEEN_TALK_FROM_END := 10
## The council messages: "I can't swim!" is the sixth (files, v1.0).
const CANT_SWIM_MESSAGE := 5
## The run of [Keen4Episode.GAME_TEXTS].
const GAME_OVER_TEXT := 0
const TRY_AGAIN_INTRO := 7
const TRY_AGAIN_TEXT := 8
const EXIT_TEXT := 9
const ONE_MOMENT_TEXT := 12
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

var _graphics: GalaxyGraphics
var _names := PackedStringArray()
var _entries := PackedStringArray()
var _game := PackedStringArray()
var _council := PackedStringArray()
var _picture_count := 0


static func create(data: GalaxyData) -> Keen4GameBoxes:
	var boxes := Keen4GameBoxes.new()
	boxes._graphics = data.graphics
	boxes._names = data.executable.level_names()
	boxes._entries = data.executable.entry_texts()
	boxes._game = data.executable.texts(Keen4Episode.GAME_TEXTS)
	boxes._council = data.executable.messages(Keen4Episode.COUNCIL_MESSAGES)
	boxes._picture_count = data.graphics.ranges.picture_count
	return boxes


## The box when Keen enters map [param map]: the first screen with the
## whole count-down picture, then one per finger counted down (Omni
## CK_BeginCacheBox, CK_UpdateCacheBox).
func entering(map: int) -> Array[Image]:
	var window := _window()
	window.open_centred(WINDOW_CELLS)
	window.draw_picture(_picture(COUNTDOWN_FROM_END), Vector2i.ZERO)
	window.narrow(PICTURE_WIDTH, 0)
	var text := _text(_entries, map)
	window.skip((window.inside.size.y - window.text_height(text)) / 2 - TEXT_RAISE)
	window.print_centred(text)
	var screens: Array[Image] = [window.image()]
	for finger in FINGER_PICTURES:
		window.draw_picture(_picture(COUNTDOWN_FROM_END - 1 - finger), FINGERS_AT)
		screens.append(window.image())
	return screens


## "One moment", when Keen leaves the world map (Omni CK_GameLoop; centred
## as the original shows it).
func one_moment() -> Image:
	var window := _window()
	window.open_centred(WINDOW_CELLS)
	window.skip(ONE_MOMENT_DOWN)
	window.print_centred(_text(_game, ONE_MOMENT_TEXT))
	return window.image()


## "I can't swim!" (Omni CK4_ShowCantSwimMessage).
func cant_swim() -> Image:
	var window := _window()
	window.open_centred(WINDOW_CELLS)
	var right := WINDOW_CELLS.x * GalaxyWindow.CELL - PICTURE_WIDTH
	window.draw_picture(_picture(KEEN_TALK_FROM_END), Vector2i(right, 0))
	window.narrow(0, PICTURE_WIDTH)
	window.skip(CANT_SWIM_DOWN)
	window.print_centred(_text(_council, CANT_SWIM_MESSAGE))
	return window.image()


## The box after a death in map [param map], with choice [param choice]
## (0 try again, 1 exit) framed in the colour of tic [param tic] (Omni
## CK_TryAgainMenu).
func try_again(map: int, choice: int, tic: int) -> Image:
	var window := _window()
	window.open_centred(TRY_AGAIN_CELLS)
	window.skip(INTRO_DOWN)
	window.print_centred(_text(_game, TRY_AGAIN_INTRO))
	var first := window.print_y + CHOICE_GAP
	var name := _text(_names, map)
	if window.text_height(name) < SHORT_NAME:
		window.skip(SHORT_NAME_DOWN)
	window.print_centred(name)
	window.print_y = first + FIRST_CHOICE_DOWN
	window.print_centred(_text(_game, TRY_AGAIN_TEXT))
	window.skip(SECOND_CHOICE_DOWN)
	var second := window.print_y - CHOICE_TOP_ABOVE_TEXT
	window.print_centred(_text(_game, EXIT_TEXT))
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


## "Game Over!" (Omni CK_GameOver).
func game_over() -> Image:
	var window := _window()
	window.open_centred(GAME_OVER_CELLS)
	window.print_in_middle(_text(_game, GAME_OVER_TEXT))
	return window.image()


func _window() -> GalaxyWindow:
	return GalaxyWindow.create(_graphics, Keen4Episode.MENU_FONT)


func _picture(from_end: int) -> int:
	return _picture_count - from_end


static func _text(texts: PackedStringArray, index: int) -> String:
	return texts[index] if index >= 0 and index < texts.size() else ""
