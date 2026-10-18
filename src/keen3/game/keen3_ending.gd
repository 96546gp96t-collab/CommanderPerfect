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
## visible part starts at the view's corner, tile (2,2): 4 cells right and
## down. [constant SCREEN_ORIGIN] takes that off, which centres every box
## (the y offset is our reading; to check in js-dos).

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
## Choco's text cells start this far left and up of the picture's.
const SCREEN_ORIGIN := Vector2i(4, 4)
## The frames of the four pages and of the box over the picture, top left
## and bottom right, in Choco's cells.
const PAGE_FRAME_STARTS: Array[Vector2i] = [
	Vector2i(4, 18), Vector2i(4, 18), Vector2i(4, 18), Vector2i(17, 18)
]
const PAGE_FRAME_ENDS: Array[Vector2i] = [
	Vector2i(43, 23), Vector2i(43, 22), Vector2i(43, 22), Vector2i(30, 20)
]
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
const PICTURE_WAIT_RETRACES := 400.0
## A fade: [constant FADE_STEPS] steps, [constant FADE_STEP_RETRACES] apart
## (estimate: a death's fade in js-dos stepped ~114 ms apart).
const FADE_STEPS := 4
const FADE_STEP_RETRACES := 8.0
## The end text: as Keen 1's and Keen 2's, 38 characters by 23 lines.
const TEXT_WIDTH := 38
const TEXT_LINES := 23
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
## Retraces spent in the current wait.
var _time := 0.0
var _scroll_time := 0.0


## The ending with the four [param pages], the box over the picture
## ([param the_end]) and the end text block ([param end_text_data]; empty
## when not found), from [Keen3GameData].
static func create(
	pages: Array[PackedStringArray], the_end: PackedStringArray, end_text_data: PackedByteArray
) -> Keen3Ending:
	var ending := Keen3Ending.new()
	ending._pages = pages
	ending._the_end = the_end
	if not end_text_data.is_empty():
		ending.end_text = TextDocument.layout(end_text_data, TEXT_WIDTH)
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


## The lines of the end text on the screen.
func end_text_lines() -> PackedStringArray:
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
		boxes.add(_pages[index], frame.position, frame.size, PAGE_PAUSE_RETRACES)
	boxes.changed.connect(changed.emit)


func _add_the_end() -> void:
	boxes = Keen3TypedBoxes.new()
	var frame := frame_on_picture(THE_END_FRAME_START, THE_END_FRAME_END)
	# No pause: the box stays until a key is pressed.
	boxes.add(_the_end, frame.position, frame.size, INF)
	boxes.changed.connect(changed.emit)


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
