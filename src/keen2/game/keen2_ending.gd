class_name Keen2Ending
extends RefCounted
## The end of Keen 2, once all eight cities are saved, in fixed ticks. Only
## the logic; [Keen2View] shows what [member stage] asks for.
##
##   SHIP_HOME   map 81: Keen's small ship flies from the mothership down to
##               the Earth ([Keen2Flight]), with the first text
##   MOTHERSHIP  map 81 again: the mothership flies off, with the second
##   AT_HOME     the picture of FINALE.CK2 with the pages at home, one per
##               button press, and "TO BE CONTINUED...." last
##   END_TEXT    the end text from KEEN2.EXE, scrolled with up and down
##   FINISHED    the view goes on (the start screen; B7: the high scores)
## A flight stage ends when the ship is there and its text is closed. A
## button (jump, pogo, fire or Enter) closes a text or turns a page. Texts
## that were not found are left out. The order and the timings come from
## Commander Genius (docs/keen2/research.md section 9); that the end text
## follows is our reading of the original (Commander Genius shows none).

## Emitted when the stage, the page or the text position changes: the view
## then redraws the window and loads the right map.
signal changed

enum Stage { SHIP_HOME, MOTHERSHIP, AT_HOME, END_TEXT, FINISHED }

const ENDING := Keen2Executable.EndingText
## Where Keen's ship starts on map 81: where this tile is (part of the
## mothership's picture).
const SHIP_START_TILE := 593
## The pages at home, in order.
const HOME_PAGES: Array[Keen2Executable.EndingText] = [
	ENDING.HOME_1, ENDING.HOME_2, ENDING.HOME_3, ENDING.HOME_4, ENDING.TO_BE_CONTINUED
]
## Characters per line and lines per page of the end text, inside the
## border of a 320x200 screen (the same as Keen 1's end text).
const TEXT_WIDTH := 38
const TEXT_LINES := 23
## Ticks between two lines while up or down is held.
const SCROLL_TICKS := 4

var stage := Stage.SHIP_HOME
var flight: Keen2Flight
## The texts of the ending, in the order of [enum Keen2Executable.EndingText].
var texts: Array[PackedStringArray] = []
## Whether the text of a flight stage is still open.
var message_open := false
## The pages at home that were found, and the one shown.
var pages: Array[PackedStringArray] = []
var page := 0
## The end text, laid out for [constant TEXT_WIDTH] columns.
var end_text := PackedStringArray()
## First line of the end text that is shown.
var text_offset := 0
var _ship_start := Vector2.ZERO
var _confirm_was_held := true
var _scroll_timer := 0


## [param ending_texts] in the order of [enum Keen2Executable.EndingText],
## [param end_text_data] the end text block (or empty), [param ship_start]
## the top left of Keen's ship on map 81 (see [method ship_start_in]).
static func create(
	ending_texts: Array[PackedStringArray], end_text_data: PackedByteArray, ship_start: Vector2
) -> Keen2Ending:
	var ending := Keen2Ending.new()
	ending.texts = ending_texts
	ending._ship_start = ship_start
	if not end_text_data.is_empty():
		ending.end_text = TextDocument.layout(end_text_data, TEXT_WIDTH)
	for which in HOME_PAGES:
		var lines := ending._text(which)
		if not lines.is_empty():
			ending.pages.append(lines)
	ending._begin(Stage.SHIP_HOME)
	return ending


## Where Keen's ship starts on [param space] (map 81): the top left of the
## first [constant SHIP_START_TILE], or the top left of the map.
static func ship_start_in(space: LevelData) -> Vector2:
	var index := space.tiles.find(SHIP_START_TILE)
	if index < 0:
		return Vector2(space.playable_rect().position * EgaGraphics.TILE_SIZE)
	return Vector2(Vector2i(index % space.width, index / space.width) * EgaGraphics.TILE_SIZE)


## Advances one tick. [param confirm_held] is true while one of the buttons
## that move on is held; [param vertical] scrolls the end text.
func step(confirm_held: bool, vertical := 0) -> void:
	var confirmed := confirm_held and not _confirm_was_held
	_confirm_was_held = confirm_held
	match stage:
		Stage.SHIP_HOME, Stage.MOTHERSHIP:
			flight.step()
			if confirmed:
				confirm()
			elif flight.is_finished() and not message_open:
				_next_stage()
		Stage.END_TEXT:
			_scroll(vertical)
			if confirmed:
				confirm()
		Stage.AT_HOME:
			if confirmed:
				confirm()


## Moves on from the text that is shown (also for Enter).
func confirm() -> void:
	match stage:
		Stage.SHIP_HOME, Stage.MOTHERSHIP:
			if message_open:
				message_open = false
				changed.emit()
		Stage.AT_HOME:
			page += 1
			if page >= pages.size():
				_next_stage()
			else:
				changed.emit()
		Stage.END_TEXT:
			_next_stage()


## The lines of the window that is open, or none.
func window_lines() -> PackedStringArray:
	match stage:
		Stage.SHIP_HOME:
			return _text(ENDING.SHIP_HOME) if message_open else PackedStringArray()
		Stage.MOTHERSHIP:
			return _text(ENDING.MOTHERSHIP) if message_open else PackedStringArray()
		Stage.AT_HOME:
			return pages[page]
		Stage.END_TEXT:
			return end_text.slice(text_offset, text_offset + TEXT_LINES)
	return PackedStringArray()


## Whether map 81 is shown (the flights); otherwise the picture or the text.
func shows_space() -> bool:
	return stage in [Stage.SHIP_HOME, Stage.MOTHERSHIP]


func shows_picture() -> bool:
	return stage == Stage.AT_HOME


## Where the view looks on map 81: at the ship, or (for the mothership) at
## a fixed place. Its middle, in map pixels, for a view of [param view_size].
func view_center(view_size: Vector2) -> Vector2:
	if stage == Stage.MOTHERSHIP:
		return Keen2Flight.MOTHERSHIP_VIEW + view_size / 2.0
	return flight.position


func is_finished() -> bool:
	return stage == Stage.FINISHED


func _text(which: Keen2Executable.EndingText) -> PackedStringArray:
	return texts[which] if which < texts.size() else PackedStringArray()


func _next_stage() -> void:
	_begin((stage + 1) as Stage)


func _begin(next: Stage) -> void:
	stage = next
	match stage:
		Stage.SHIP_HOME:
			flight = Keen2Flight.home(_ship_start)
			message_open = not _text(ENDING.SHIP_HOME).is_empty()
		Stage.MOTHERSHIP:
			flight = Keen2Flight.mothership()
			message_open = not _text(ENDING.MOTHERSHIP).is_empty()
		Stage.AT_HOME:
			page = 0
			if pages.is_empty():
				_begin(Stage.END_TEXT)
				return
		Stage.END_TEXT:
			text_offset = 0
			if end_text.is_empty():
				_begin(Stage.FINISHED)
				return
	changed.emit()


func _scroll(vertical: int) -> void:
	if vertical == 0:
		_scroll_timer = 0
		return
	if _scroll_timer > 0:
		_scroll_timer -= 1
		return
	_scroll_timer = SCROLL_TICKS
	var last := maxi(0, end_text.size() - TEXT_LINES)
	var offset := clampi(text_offset + vertical, 0, last)
	if offset != text_offset:
		text_offset = offset
		changed.emit()
