class_name Keen5Messages
extends RefCounted
## The message boxes of Keen 5 after a level (milestone E5; Omni
## `ck5_misc.c` CK5_FuseMessage, facts only; docs/keen5/research.md §4):
## after a level ended by its fuse, a window of 26 × 8 cells in the middle
## of the screen with Keen talking at its right (KEENTALK1) and his words
## 12 pixels down, centred left of the picture: on map 13 (Korath III)
## "I wonder what that fuse was for....", elsewhere that one of the four
## machines guarding the main elevator shaft is toast. Then the same box
## with his thumb up (KEENTALK2 over the first picture). Each screen shows
## 30 tics before a key counts ([constant KEY_WAIT_TICS]). The texts are
## the player's own ([Keen5Episode.FUSE_TEXTS]); the pictures are counted
## back from the end of the picture range (Omni PIC_KEENTALK1, 2: pictures
## 84 and 85 of 93 in v1.4).

const WINDOW_CELLS := Vector2i(26, 8)
const PICTURE_WIDTH := 0x30
const TEXT_DOWN := 0xC
## Keen talking and with his thumb up, from the end of the picture range.
const KEEN_TALK_FROM_END := 9
const KEEN_THUMB_FROM_END := 8
## Korath III's map has its own words (Omni).
const KORATH_MAP := 13
## Each screen waits this long before a key counts (Omni VL_DelayTics).
const KEY_WAIT_TICS := 30

## The text each screen of the last call printed, for the tests.
var texts := PackedStringArray()
var _graphics: GalaxyGraphics
var _fuse := PackedStringArray()
var _picture_count := 0


## The boxes with the texts and pictures of [param data]; into
## [param into] when given (a subclass: [Keen5NamedMessages]).
static func create(data: GalaxyData, into: Keen5Messages = null) -> Keen5Messages:
	var messages := into if into != null else Keen5Messages.new()
	messages._graphics = data.graphics
	messages._fuse = data.executable.texts(Keen5Episode.FUSE_TEXTS)
	messages._picture_count = data.graphics.ranges.picture_count
	return messages


## The two screens after the fuse of map [param map] broke (Omni
## CK5_FuseMessage).
func fuse(map: int) -> Array[Image]:
	var which := Keen5Episode.KORATH_FUSE_TEXT if map == KORATH_MAP else Keen5Episode.FUSE_TEXT
	var english := _fuse[which] if which < _fuse.size() else ""
	var text := GalaxyTexts.run_text(
		Keen5Episode.TEXT_NAMES, Keen5Episode.FUSE_TEXTS, which, english
	)
	var window := GalaxyWindow.create(_graphics, Keen5Episode.MENU_FONT)
	window.open_centred(WINDOW_CELLS)
	var right := Vector2i(WINDOW_CELLS.x * GalaxyWindow.CELL - PICTURE_WIDTH, 0)
	window.draw_picture(_picture_count - KEEN_TALK_FROM_END, right)
	window.narrow(0, PICTURE_WIDTH)
	window.skip(TEXT_DOWN)
	window.print_centred(text)
	var talking := window.image()
	window.draw_picture(_picture_count - KEEN_THUMB_FROM_END, right)
	texts = PackedStringArray([text, ""])
	return [talking, window.image()]
