class_name Keen4Messages
extends RefCounted
## The message boxes of Keen 4 inside a level (Omni `ck4_misc.c`:
## CK4_ShowCouncilMessage, CK4_ShowJanitorMessage, CK4_ShowPrincessMessage,
## CK4_ShowWetsuitMessage; facts only; seen in the original, D6), each a
## series of screens ([GalaxyWindow]) that wait for a key one by one. The
## texts are the player's own, read from the program
## ([GalaxyExecutable.messages]); the pictures are the last ones of the
## picture range (the same order in v1.0 and v1.4: the Oracle elder,
## Keen talking, Keen with his thumb up, Keen cross, Lindsey).
##
## Every box is a window of 26 × 8 cells in the middle of the screen. The
## one who speaks is on the left (his picture at the window's left edge,
## the text 6 pixels down, right of it) or, for Keen, on the right (the
## text 12 pixels down, left of it):
##   - a council member: his thanks (in level 17 the bubbly version),
##     Keen's answer (one of eight, by how many were rescued before), then
##     Keen with his thumb up in the same box;
##   - the janitor (level 14): two boxes of his, Keen's, his last, then
##     Keen alone, cross;
##   - Lindsey: "Princess Lindsey says:" and her hint (level 7: the
##     wetsuit, else the way to the Pyramid of the Forbidden), Keen's
##     thanks, then his thumb up;
##   - the wetsuit: Keen's words, then his thumb up.

## The run of messages in the program (files, v1.0; [Keen4Episode]): by
## their place in it.
const HINT_WETSUIT := 0
const HINT_PYRAMID := 1
const THANKS_HINT_WETSUIT := 2
const THANKS_HINT_PYRAMID := 3
const LINDSEY_SAYS := 4
const GOT_WETSUIT := 6
const FIRST_ANSWER := 7
const ANSWER_COUNT := 8
const THANKS_UNDER_WATER := 15
const THANKS := 16
## The janitor's run: his three texts and Keen's reply (third).
const JANITOR_TEXTS: PackedInt32Array = [0, 1, 2, 3]
const JANITOR_KEEN := 2
## Pictures, counted back from the end of the picture range (Omni PIC_ORACLE
## … PIC_LINDSEY; checked on v1.0's pictures 96-100 of 107).
const ORACLE_FROM_END := 11
const KEEN_TALK_FROM_END := 10
const KEEN_THUMB_FROM_END := 9
const KEEN_CROSS_FROM_END := 8
const LINDSEY_FROM_END := 7
## The window, in cells, and the layout in pixels (Omni).
const WINDOW_CELLS := Vector2i(26, 8)
const PICTURE_WIDTH := 0x30
const SPEAKER_TEXT_DOWN := 6
const KEEN_TEXT_DOWN := 12
## Keen's cross face goes over his talking picture here (Omni).
const CROSS_FACE := Vector2i(0x28, 0x18)
## The level of the wetsuit hint, and the one under water (Omni).
const HINT_WETSUIT_LEVEL := 7
const UNDER_WATER_LEVEL := 17

## The text each screen of the last call printed (empty for a screen of
## pictures only), for the tests.
var texts := PackedStringArray()
var _graphics: GalaxyGraphics
var _council := PackedStringArray()
var _janitor := PackedStringArray()
var _picture_count := 0


## The boxes of Keen 4 with the texts and pictures of [param data].
static func create(data: GalaxyData) -> Keen4Messages:
	var messages := Keen4Messages.new()
	messages._graphics = data.graphics
	messages._council = data.executable.messages(Keen4Episode.COUNCIL_MESSAGES)
	messages._janitor = data.executable.messages(Keen4Episode.JANITOR_MESSAGES)
	messages._picture_count = data.graphics.ranges.picture_count
	return messages


## The screens of rescuing a council member in level [param level], who
## was rescued after [param rescued_before] others.
func council(level: int, rescued_before: int) -> Array[Image]:
	var window := _window()
	var thanks := THANKS_UNDER_WATER if level == UNDER_WATER_LEVEL else THANKS
	_speaker_box(window, ORACLE_FROM_END, _text(_council, thanks))
	var screens: Array[Image] = [window.image()]
	var answer := FIRST_ANSWER + clampi(rescued_before, 0, ANSWER_COUNT - 1)
	screens.append_array(_keen_answer(window, _text(_council, answer)))
	texts = [_text(_council, thanks), _text(_council, answer), _text(_council, answer)]
	return screens


## The janitor's five screens (level 14).
func janitor() -> Array[Image]:
	var window := _window()
	var screens: Array[Image] = []
	texts = PackedStringArray()
	for index in JANITOR_TEXTS:
		texts.append(_text(_janitor, index))
		if index == JANITOR_KEEN:
			_keen_box(window, _text(_janitor, index))
		else:
			_speaker_box(window, ORACLE_FROM_END, _text(_janitor, index))
		screens.append(window.image())
	window.open_centred(WINDOW_CELLS)
	var right := WINDOW_CELLS.x * GalaxyWindow.CELL
	window.draw_picture(_picture(KEEN_TALK_FROM_END), Vector2i(right - PICTURE_WIDTH, 0))
	window.draw_picture(_picture(KEEN_CROSS_FROM_END), Vector2i(right - CROSS_FACE.x, CROSS_FACE.y))
	screens.append(window.image())
	texts.append("")
	return screens


## Lindsey's screens in level [param level].
func lindsey(level: int) -> Array[Image]:
	var window := _window()
	var wetsuit_hint := level == HINT_WETSUIT_LEVEL
	var hint := HINT_WETSUIT if wetsuit_hint else HINT_PYRAMID
	_speaker_box(window, LINDSEY_FROM_END, _text(_council, LINDSEY_SAYS))
	window.print_centred(_text(_council, hint))
	var screens: Array[Image] = [window.image()]
	var thanks := THANKS_HINT_WETSUIT if wetsuit_hint else THANKS_HINT_PYRAMID
	screens.append_array(_keen_answer(window, _text(_council, thanks)))
	var said := _text(_council, LINDSEY_SAYS) + _text(_council, hint)
	texts = [said, _text(_council, thanks), _text(_council, thanks)]
	return screens


## The screens of finding the wetsuit.
func wetsuit() -> Array[Image]:
	var said := _text(_council, GOT_WETSUIT)
	texts = [said, said]
	return _keen_answer(_window(), said)


## Keen's box with [param text], then the same with his thumb up.
func _keen_answer(window: GalaxyWindow, text: String) -> Array[Image]:
	_keen_box(window, text)
	var screens: Array[Image] = [window.image()]
	var right := WINDOW_CELLS.x * GalaxyWindow.CELL - PICTURE_WIDTH
	window.draw_picture(_picture(KEEN_THUMB_FROM_END), Vector2i(right, 0))
	screens.append(window.image())
	return screens


## A box of the one on the left (picture [param from_end]) saying
## [param text].
func _speaker_box(window: GalaxyWindow, from_end: int, text: String) -> void:
	window.open_centred(WINDOW_CELLS)
	window.draw_picture(_picture(from_end), Vector2i.ZERO)
	window.skip(SPEAKER_TEXT_DOWN)
	window.narrow(PICTURE_WIDTH, 0)
	window.print_centred(text)


## A box of Keen (on the right) saying [param text].
func _keen_box(window: GalaxyWindow, text: String) -> void:
	window.open_centred(WINDOW_CELLS)
	var right := WINDOW_CELLS.x * GalaxyWindow.CELL - PICTURE_WIDTH
	window.draw_picture(_picture(KEEN_TALK_FROM_END), Vector2i(right, 0))
	window.narrow(0, PICTURE_WIDTH)
	window.skip(KEEN_TEXT_DOWN)
	window.print_centred(text)


func _window() -> GalaxyWindow:
	return GalaxyWindow.create(_graphics, Keen4Episode.MENU_FONT)


func _picture(from_end: int) -> int:
	return _picture_count - from_end


static func _text(texts: PackedStringArray, index: int) -> String:
	return texts[index] if index < texts.size() else ""
