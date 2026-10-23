class_name GalaxyIntroCredits
extends RefCounted
## The intro credits of a Galaxy episode, the "terminator" (Omni
## `ck_inter.c`: CK_DrawTerminator and what it calls; facts and numbers
## only), counted in tics; [GalaxyTitleLayer] draws what this class says:
##   1. scroll: the second word ([member right_word]) comes in from the
##      left and the first ([member left_word], only its even rows) from the
##      right, both in proportion to the time, until the first word's right
##      edge is at x 120; meanwhile four credit pictures fly up from the
##      bottom to the middle, stay 200 tics and fly out at the top, two
##      pixels a tic;
##   2. zoom: both words joined (80 pixels apart, the second without its
##      first dark run) shrink in 30 tics to 33/256 of their size at the
##      top of the screen;
##   3. fizzle: the title picture appears pixel by pixel in a random order,
##      row by row from the top, over the zoom's last picture with the words
##      white ([member fizzle]);
##   4. the title picture stays [constant TITLE_TICS] tics.
## The colours are the original's palettes for this part: either word alone
## dark grey, both light grey, the credits blue, light blue and light cyan.

enum Phase { SCROLL, ZOOM, FIZZLE, TITLE, DONE }
enum CreditStage { LOADING, RISING, WAITING, LEAVING, GONE }

const SCREEN_SIZE := Vector2i(320, 200)
const SCREEN_MIDDLE := 160
const BYTE_PIXELS := 8
## The second word starts this far right of the buffer's left edge.
const RIGHT_WORD_MARGIN := 200
## The first word's right edge ends here.
const LEFT_WORD_END := 120
## A credit flies from y 240 (its middle) to 100, stays 200 tics, flies out
## to -40, at two pixels a tic.
const CREDIT_FROM := 240
const CREDIT_MIDDLE := 100
const CREDIT_PAUSE_TICS := 200
const CREDIT_GONE := -40
const CREDIT_SPEED := 2
const ZOOM_TICS := 30
const ZOOM_FULL := 256
const ZOOM_FINAL := 33
const ZOOM_FINAL_TOP := 4
const JOIN_GAP := 80
## Steps of the fizzle, one a tic; a row starts at its own step and is
## whole 160 steps later, two pixels a step.
const FIZZLE_STEPS := 360
const FIZZLE_ROW_STEPS := 160
const FIZZLE_PIXELS_PER_STEP := 2
const TITLE_TICS := 420
const FIZZLE_SEED := 4
## The colours of this part (EGA palette values the original sets).
const ONE_WORD := Color8(85, 85, 85)
const CREDIT_COLORS: PackedInt32Array = [0, 1, 9, 11]

var left_word: GalaxyIntroBitmap
## The colour of the words while they zoom (Keen 4's dark grey; Keen 5
## sets red).
var word_color := ONE_WORD
var right_word: GalaxyIntroBitmap
## The credit pictures, in their colours, see-through where they are dark.
var credits: Array[Image] = []
var phase := Phase.SCROLL
## Tics since the phase began.
var elapsed := 0
## The title picture, and the screen while it fizzles in.
var title: Image
var fizzle: Image
## The credit flying now (its index), or -1.
var credit := -1
var credit_y := CREDIT_GONE
var _credit_stage := CreditStage.LOADING
var _credit_left := 0
var _credit_since := 0
var _joined: Array[PackedInt32Array] = []
var _fizzle_columns := PackedInt32Array()


## The credits from the two words, the credit pictures (as decoded) and
## the [param title_picture].
static func create(
	first: GalaxyIntroBitmap,
	second: GalaxyIntroBitmap,
	pictures: Array[Image],
	title_picture: Image = null
) -> GalaxyIntroCredits:
	var intro := GalaxyIntroCredits.new()
	intro.title = title_picture
	intro.left_word = first
	intro.right_word = second
	for picture in pictures:
		intro.credits.append(credit_colors(picture))
	intro._join()
	intro._fizzle_columns = fizzle_columns(FIZZLE_SEED)
	intro.credit = 0 if not pictures.is_empty() else -1
	intro._advance_credit()
	return intro


## How long the scroll takes, in tics.
func scroll_tics() -> int:
	return absi(LEFT_WORD_END - left_word.width - SCREEN_SIZE.x)


## Lets [param tics] tics pass.
func advance(tics: int) -> void:
	elapsed += tics
	match phase:
		Phase.SCROLL:
			_advance_credit()
			if elapsed > scroll_tics():
				_next(Phase.ZOOM)
		Phase.ZOOM:
			if elapsed >= ZOOM_TICS:
				_next(Phase.FIZZLE)
				_start_fizzle()
		Phase.FIZZLE:
			_fizzle_steps(elapsed - tics, elapsed)
			if elapsed >= FIZZLE_STEPS:
				_next(Phase.TITLE)
		Phase.TITLE:
			if elapsed >= TITLE_TICS:
				_next(Phase.DONE)


## Where the second word's left edge is on the screen now.
func right_word_x() -> int:
	var total := scroll_tics()
	var screen_left := (
		(right_word.width + RIGHT_WORD_MARGIN) * (total - mini(elapsed, total)) / total
	)
	return RIGHT_WORD_MARGIN - screen_left


## Where the first word's left edge is on the screen now.
func left_word_x() -> int:
	var total := scroll_tics()
	var travel := LEFT_WORD_END - left_word.width - SCREEN_SIZE.x
	return SCREEN_SIZE.x + travel * mini(elapsed, total) / total


## Where the credit flying now has its top-left corner.
func credit_corner() -> Vector2i:
	if credit < 0 or credit >= credits.size():
		return Vector2i(0, SCREEN_SIZE.y)
	var size := credits[credit].get_size()
	# Half its width in whole bytes (seen in the original, D8: the 72-pixel
	# credit is 4 pixels right of the middle Omnispeak gives).
	var half := size.x / BYTE_PIXELS / 2 * BYTE_PIXELS
	return Vector2i(SCREEN_MIDDLE - half, credit_y - size.y / 2)


## The zoom's picture [param tics] tics into it (palette: the joined
## words dark grey on black).
func zoom_image(tics: int) -> Image:
	var image := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	var step := mini(maxi(tics, 1), ZOOM_TICS)
	var scale := ZOOM_FULL - (ZOOM_FULL - ZOOM_FINAL) * step / ZOOM_TICS
	var left := (LEFT_WORD_END - left_word.width) * (ZOOM_TICS - step) / ZOOM_TICS
	var top := step * ZOOM_FINAL_TOP / ZOOM_TICS
	if step == ZOOM_TICS:
		scale = ZOOM_FINAL
		left = 0
		top = ZOOM_FINAL_TOP
	var row_step := 0x10000 / scale
	for row in (SCREEN_SIZE.y * scale) >> 8:
		var source := _joined[mini((row * row_step) >> 8, _joined.size() - 1)]
		for index in range(1, source.size() - 1, 2):
			var from := left + source[index] * scale / ZOOM_FULL
			var to := mini(left + source[index + 1] * scale / ZOOM_FULL, SCREEN_SIZE.x)
			from = maxi(from, 0)
			if to > from:
				image.fill_rect(Rect2i(from, row + top, to - from, 1), word_color)
	return image


## The pixels the fizzle shows in step [param step], as x, y pairs.
func fizzle_pixels(step: int) -> PackedInt32Array:
	var pixels := PackedInt32Array()
	var first := maxi(step - FIZZLE_ROW_STEPS, 0)
	var last := mini(step, SCREEN_SIZE.y - 1)
	for y in range(first, last + 1):
		for pixel in FIZZLE_PIXELS_PER_STEP:
			var done := (step - y) * FIZZLE_PIXELS_PER_STEP + pixel
			var column := (_fizzle_columns[y] + done) % SCREEN_SIZE.x
			pixels.append(_fizzle_columns[column])
			pixels.append(y)
	return pixels


## The columns in a random order (the original shuffles them anew each
## time; ours with [param seed], so it is the same every time).
static func fizzle_columns(seed: int) -> PackedInt32Array:
	var random := RandomNumberGenerator.new()
	random.seed = seed
	var columns := PackedInt32Array(range(SCREEN_SIZE.x))
	for index in SCREEN_SIZE.x:
		var other := random.randi_range(0, SCREEN_SIZE.x - 1)
		var kept := columns[other]
		columns[other] = columns[index]
		columns[index] = kept
	return columns


## [param picture] (a credit as decoded) in the intro's colours: its blue
## and green planes pick blue, light blue or light cyan; where both are off
## it is see-through.
static func credit_colors(picture: Image) -> Image:
	var colored := Image.create_empty(
		picture.get_width(), picture.get_height(), false, Image.FORMAT_RGBA8
	)
	for y in picture.get_height():
		for x in picture.get_width():
			var index := GalaxyEga.index_of(picture.get_pixel(x, y))
			var planes := index & 3
			if planes != 0:
				colored.set_pixel(x, y, EgaPalette.color(CREDIT_COLORS[planes]))
	return colored


## The fizzle starts from the zoom's last picture in the normal palette
## (the words white; seen in the original, D8).
func _start_fizzle() -> void:
	fizzle = zoom_image(ZOOM_TICS)
	for y in fizzle.get_height():
		for x in fizzle.get_width():
			if fizzle.get_pixel(x, y) == word_color:
				fizzle.set_pixel(x, y, Color.WHITE)


## The title's pixels of the fizzle steps from [param from] to [param to].
func _fizzle_steps(from: int, to: int) -> void:
	if title == null or fizzle == null:
		return
	for step in range(maxi(from, 0), mini(to, FIZZLE_STEPS)):
		var pixels := fizzle_pixels(step)
		for index in range(0, pixels.size(), 2):
			var pixel := Vector2i(pixels[index], pixels[index + 1])
			fizzle.set_pixelv(pixel, title.get_pixelv(pixel))


func _next(next_phase: Phase) -> void:
	phase = next_phase
	elapsed = 0


## The credits' own clock (Omni AdvanceTerminatorCredit): each frame
## measures the tics since the last; a credit that has flown out makes room
## for the next one a frame later.
func _advance_credit() -> void:
	if credit < 0:
		return
	if _credit_stage == CreditStage.GONE:
		credit += 1
		if credit >= credits.size():
			credit = -1
			credit_y = CREDIT_GONE
			return
		_credit_stage = CreditStage.LOADING
	if _credit_stage == CreditStage.LOADING:
		_credit_stage = CreditStage.RISING
		_credit_left = CREDIT_FROM
		_credit_since = elapsed
	match _credit_stage:
		CreditStage.RISING:
			_credit_left -= (elapsed - _credit_since) * CREDIT_SPEED
			if _credit_left < CREDIT_MIDDLE:
				_credit_left = CREDIT_MIDDLE
				_credit_stage = CreditStage.WAITING
			_credit_since = elapsed
		CreditStage.WAITING:
			if elapsed - _credit_since > CREDIT_PAUSE_TICS:
				_credit_stage = CreditStage.LEAVING
				_credit_since = elapsed
		CreditStage.LEAVING:
			_credit_left -= (elapsed - _credit_since) * CREDIT_SPEED
			_credit_since = elapsed
			if _credit_left < CREDIT_GONE:
				_credit_left = CREDIT_GONE
				_credit_stage = CreditStage.GONE
	credit_y = _credit_left


## The two words as one row of runs each (dark first), for the zoom.
func _join() -> void:
	var base := left_word.width + JOIN_GAP
	for row in GalaxyIntroBitmap.ROW_COUNT:
		var first := left_word.rows[row]
		var second := right_word.rows[row]
		var joined := first.slice(0, first.size() - 1)
		if second.size() > 1:
			var skipped := second[1]
			for index in range(1, second.size()):
				joined.append(base + second[index] - skipped)
		else:
			joined.append(base)
		_joined.append(joined)
