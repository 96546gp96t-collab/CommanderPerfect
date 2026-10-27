class_name Keen3Ending
extends RefCounted
## The end of Keen 3, after level 16 is won (Chocolate Keen, `CVort3_draw_win`
## and `CVort3_blink_camera_flash`; docs/keen3/research.md §9). Only the
## logic, counted in VGA retraces (70.086 a second); [Keen3EndingScreen]
## shows what [member stage] asks for.
##   HALL_FADE_IN    map 81 with the view's corner at tile (2,2), a Vorticon
##                   and Keen ([constant VORTICON_CELL], [constant KEEN_CELL])
##                   fade in
##   HALL_BOXES      the four pages, typed one after another, each followed by
##                   [constant PAGE_PAUSE_RETRACES]
##   FLASHES         five camera flashes ([constant FLASH_CELLS]): a tile
##                   changes, the whole picture is bright for
##                   [constant FLASH_RETRACES] with CLICKSND, the tile changes
##                   back, a wait; then [constant AFTER_FLASHES_RETRACES]
##   HALL_FADE_OUT   the hall fades out
##   PICTURE_FADE_IN FINALE.CK3 fades in
##   PICTURE_WAIT    [constant PICTURE_WAIT_RETRACES]
##   PICTURE_BOX     the box over the picture is typed; then a key
##   END_TEXT        the end text from KEEN3.EXE, scrolled with up and down,
##                   with MORTIMER playing; a key ends it
##   FINISHED        the view goes on (GAME OVER, then the start screen)
## Choco gives the boxes' places in cells of the screen buffer, whose
## visible part starts 4 cells right of the picture's left edge
## ([constant SCREEN_ORIGIN] takes that off, which centres every box). Its
## rows are the picture's own: seen in the original (C11), the pages stand on
## rows 18-23 (y 144) and the box over FINALE.CK3 on rows 20-24 (y 160);
## C7's reading, 4 rows up as well, put them 32 pixels too high.

## Emitted when the stage, the typed text or the end text's position
## changes.
signal changed
## Emitted when a tile of map 81 changes (the camera flashes).
signal tile_changed(cell: Vector2i, tile: int)
## Emitted at the start of each camera flash (CLICKSND).
signal flashed
## Emitted when the end text begins (MORTIMER plays).
signal end_text_started

enum Stage {
	HALL_FADE_IN,
	HALL_BOXES,
	FLASHES,
	HALL_FADE_OUT,
	PICTURE_FADE_IN,
	PICTURE_WAIT,
	PICTURE_BOX,
	END_TEXT,
	FINISHED,
}

const RETRACES_PER_SECOND := Keen3TypedBoxes.RETRACES_PER_SECOND
## The view's top left on map 81, in tiles (Choco).
const VIEW_CORNER := Vector2i(2, 2)
## Where the Vorticon (sprite 67) and Keen (sprite 0) stand, in tiles (Choco).
const VORTICON_CELL := Vector2(14, 6)
const VORTICON_SPRITE := 67
const KEEN_CELL := Vector2(15.5, 6.5)
const KEEN_SPRITE := 0
## Choco's text cells start this far left of the picture's, on the same rows
## (seen in the original, C11).
const SCREEN_ORIGIN := Vector2i(4, 0)
## The frames of the four pages and of the box over the picture, top left
## and bottom right, in Choco's cells.
const PAGE_FRAME_STARTS: Array[Vector2i] = [
	Vector2i(4, 18), Vector2i(4, 18), Vector2i(4, 18), Vector2i(17, 18)
]
const PAGE_FRAME_ENDS: Array[Vector2i] = [
	Vector2i(43, 23), Vector2i(43, 22), Vector2i(43, 22), Vector2i(30, 20)
]
## Seen in the original (C11): ~1.9 s from a page's last letter to the next
## page's first, its line end, these 120 retraces and the first letter.
const PAGE_PAUSE_RETRACES := 120.0
const THE_END_FRAME_START := Vector2i(18, 20)
const THE_END_FRAME_END := Vector2i(29, 24)
## The camera flashes: the cell, its tile during the flash, its tile after
## it, and the wait after it in retraces (Choco).
const FLASH_CELLS: Array[Vector2i] = [
	Vector2i(19, 5), Vector2i(3, 8), Vector2i(5, 8), Vector2i(20, 5), Vector2i(8, 8)
]
const FLASH_TILES: PackedInt32Array = [58, 60, 60, 58, 60]
const AFTER_FLASH_TILES: PackedInt32Array = [72, 61, 61, 72, 61]
const FLASH_WAITS: PackedInt32Array = [20, 10, 5, 10, 15]
const FLASH_RETRACES := 2.0
const AFTER_FLASHES_RETRACES := 120.0
## Seen in the original (C11): 5.71 s from FINALE.CK3 to the box.
const PICTURE_WAIT_RETRACES := 400.0
## Once the box over the picture is typed, a spinning ball waits for a key
## in the middle of its last row (seen in the original, C11): font
## characters 9-12, the next every 5 retraces, from a letter's time after
## the last letter on.
const CURSOR_FIRST_CHAR := 9
const CURSOR_FRAMES := 4
const CURSOR_FRAME_RETRACES := 5.0
## A fade: [constant FADE_STEPS] steps, [constant FADE_STEP_RETRACES] apart
## (seen in the original, C11: the hall fades in in steps ~114 ms apart).
const FADE_STEPS := 4
const FADE_STEP_RETRACES := 8.0
## The end text in the original's reader (seen in the original, C11): a
## window filling the 320x200 picture, 38 characters wide; 21 lines of text,
## then the window's bottom edge across it and a footer line from KEEN3.EXE
## ([constant READER_FOOTER_ROW], red on gray). Keen 1's and Keen 2's show
## 23 lines in the shared window.
const TEXT_WIDTH := 38
const TEXT_LINES := 21
const READER_SIZE := Vector2i(TEXT_WIDTH, 23)
const READER_EDGE_ROW := 21
const READER_FOOTER_ROW := 22
## Seconds between two lines while up or down is held (Keen 2: 4 ticks).
const SCROLL_SECONDS := 4.0 / 60.0

var stage := Stage.HALL_FADE_IN
## The pages being typed, then the box over the picture.
var boxes := Keen3TypedBoxes.new()
## The flash being shown or waited after (FLASHES); 5 for the last wait.
var flash := 0
## Whether the picture is bright now.
var flashing := false
## The end text, laid out for [constant TEXT_WIDTH] columns, and its first
## line shown.
var end_text := PackedStringArray()
var text_offset := 0
var _pages: Array[PackedStringArray] = []
var _the_end := PackedStringArray()
## The end text block as read, and the language [member end_text] is laid
## out in.
var _end_text_data := PackedByteArray()
var _end_text_language := ""
## Retraces spent in the current wait.
var _time := 0.0
var _scroll_time := 0.0
## Retraces since the box over the picture was typed.
var _typed_time := 0.0


## The ending with the four [param pages], the box over the picture
## ([param the_end]) and the end text block ([param end_text_data]; empty
## when not found), from [Keen3GameData].
static func create(
	pages: Array[PackedStringArray], the_end: PackedStringArray, end_text_data: PackedByteArray
) -> Keen3Ending:
	var ending := Keen3Ending.new()
	ending._pages = pages
	ending._the_end = the_end
	ending._end_text_data = end_text_data
	ending._follow_language()
	return ending


## Where a frame from [param start] to [param end] in Choco's cells has its
## top left on the picture, and the size of its inside.
static func frame_on_picture(start: Vector2i, end: Vector2i) -> Rect2i:
	return Rect2i(start - SCREEN_ORIGIN, end - start - Vector2i.ONE)


## Goes on for [param seconds]; [param vertical] (-1 up, 1 down) scrolls the
## end text.
func advance(seconds: float, vertical := 0) -> void:
	if stage == Stage.END_TEXT:
		_scroll(seconds, vertical)
		return
	if stage == Stage.PICTURE_BOX and boxes.is_pausing():
		var shown := cursor_char()
		_typed_time += seconds * RETRACES_PER_SECOND
		if cursor_char() != shown:
			changed.emit()
		return
	if stage in [Stage.HALL_BOXES, Stage.PICTURE_BOX]:
		boxes.advance(seconds)
		if stage == Stage.HALL_BOXES and boxes.is_finished():
			_begin(Stage.FLASHES)
		return
	_time += seconds * RETRACES_PER_SECOND
	match stage:
		Stage.HALL_FADE_IN, Stage.HALL_FADE_OUT, Stage.PICTURE_FADE_IN:
			if _time >= fade_retraces():
				_begin((stage + 1) as Stage)
			else:
				changed.emit()
		Stage.FLASHES:
			_advance_flashes()
		Stage.PICTURE_WAIT:
			if _time >= PICTURE_WAIT_RETRACES:
				_begin(Stage.PICTURE_BOX)


## A key was pressed: it closes the box over the picture once it is typed,
## and the end text.
func confirm() -> void:
	if stage == Stage.PICTURE_BOX and boxes.is_pausing():
		_begin(Stage.END_TEXT)
	elif stage == Stage.END_TEXT:
		_begin(Stage.FINISHED)


## How bright the picture is, 0 (black) to 1, in steps while it fades.
func brightness() -> float:
	var progress := clampf(_time / fade_retraces(), 0.0, 1.0)
	var stepped := floorf(progress * FADE_STEPS) / FADE_STEPS
	match stage:
		Stage.HALL_FADE_IN, Stage.PICTURE_FADE_IN:
			return stepped
		Stage.HALL_FADE_OUT:
			return 1.0 - stepped
	return 1.0


## How long a fade takes, in retraces.
static func fade_retraces() -> float:
	return FADE_STEPS * FADE_STEP_RETRACES


## Whether map 81 is shown (otherwise the picture or the end text).
func shows_hall() -> bool:
	return stage <= Stage.HALL_FADE_OUT


func shows_picture() -> bool:
	return stage in [Stage.PICTURE_FADE_IN, Stage.PICTURE_WAIT, Stage.PICTURE_BOX]


func is_finished() -> bool:
	return stage == Stage.FINISHED


## The font character of the ball under the typed box over the picture,
## or -1 while there is none.
func cursor_char() -> int:
	if stage != Stage.PICTURE_BOX or not boxes.is_pausing():
		return -1
	var waited := _typed_time - Keen3TypedBoxes.LETTER_RETRACES
	if waited < 0.0:
		return -1
	return CURSOR_FIRST_CHAR + floori(waited / CURSOR_FRAME_RETRACES) % CURSOR_FRAMES


## The lines of the end text on the screen.
func end_text_lines() -> PackedStringArray:
	_follow_language()
	return end_text.slice(text_offset, text_offset + TEXT_LINES)


func _begin(next: Stage) -> void:
	stage = next
	_time = 0.0
	match stage:
		Stage.HALL_BOXES:
			_add_pages()
			if boxes.is_finished():
				_begin(Stage.FLASHES)
				return
		Stage.FLASHES:
			flash = 0
			_start_flash()
		Stage.PICTURE_BOX:
			_add_the_end()
		Stage.END_TEXT:
			text_offset = 0
			if end_text.is_empty():
				_begin(Stage.FINISHED)
				return
			end_text_started.emit()
	changed.emit()


func _add_pages() -> void:
	boxes = Keen3TypedBoxes.new()
	for index in mini(_pages.size(), PAGE_FRAME_STARTS.size()):
		var frame := frame_on_picture(PAGE_FRAME_STARTS[index], PAGE_FRAME_ENDS[index])
		var lines := Lang.game_lines(Keen3Texts.ENDING_PAGE % (index + 1), _pages[index])
		boxes.add(lines, frame.position, frame.size, PAGE_PAUSE_RETRACES)
	boxes.changed.connect(changed.emit)


func _add_the_end() -> void:
	boxes = Keen3TypedBoxes.new()
	var frame := frame_on_picture(THE_END_FRAME_START, THE_END_FRAME_END)
	# No pause: the box stays until a key is pressed.
	boxes.add(Lang.game_lines(Keen3Texts.THE_END, _the_end), frame.position, frame.size, INF)
	boxes.changed.connect(changed.emit)


## Lays out the end text again when the language has changed.
func _follow_language() -> void:
	if _end_text_data.is_empty() or _end_text_language == Lang.code():
		return
	_end_text_language = Lang.code()
	var data := GameTexts.document(Keen3Texts.END_TEXT, _end_text_data)
	end_text = Keen3EndText.layout(data, TEXT_WIDTH)
	text_offset = clampi(text_offset, 0, maxi(0, end_text.size() - TEXT_LINES))


func _start_flash() -> void:
	flashing = true
	tile_changed.emit(FLASH_CELLS[flash], FLASH_TILES[flash])
	flashed.emit()


## The flashes and the waits after them, as far as [member _time] reaches.
## [member flash] equal to the number of flashes is the last wait.
func _advance_flashes() -> void:
	while stage == Stage.FLASHES:
		if flashing:
			if _time < FLASH_RETRACES:
				return
			_time -= FLASH_RETRACES
			flashing = false
			tile_changed.emit(FLASH_CELLS[flash], AFTER_FLASH_TILES[flash])
			changed.emit()
		var last_wait := flash >= FLASH_CELLS.size()
		var wait := AFTER_FLASHES_RETRACES if last_wait else float(FLASH_WAITS[flash])
		if _time < wait:
			return
		_time -= wait
		if last_wait:
			_begin(Stage.HALL_FADE_OUT)
			return
		flash += 1
		if flash < FLASH_CELLS.size():
			_start_flash()
			changed.emit()


func _scroll(seconds: float, vertical: int) -> void:
	if vertical == 0:
		_scroll_time = 0.0
		return
	_scroll_time -= seconds
	if _scroll_time > 0.0:
		return
	_scroll_time = SCROLL_SECONDS
	var last := maxi(0, end_text.size() - TEXT_LINES)
	var offset := clampi(text_offset + vertical, 0, last)
	if offset != text_offset:
		text_offset = offset
		changed.emit()
