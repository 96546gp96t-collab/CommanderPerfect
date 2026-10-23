class_name Keen5GalaxyExplosion
extends GalaxyScene
## Keen 5's game over: the galaxy explodes (Omni `ck5_misc.c`:
## CK5_ExplodeGalaxy, CK_GalExplodeUpdateCoords; facts and numbers only;
## seen in the original, E7):
##   1. the game fades to black, the picture of the Milky Way fades in, each
##      by the EGA palettes of the original's fades, 6 tics a step
##      ([GalaxyEgaFade]);
##   2. 18 steps of 10 tics in which palette entries 7 and 8 take the
##      table's values, entry 7 from its second row, entry 8 from its first
##      (seen; Omnispeak gives both the first): the galaxy flashes;
##   3. the screen goes black and 4000 stars fly out, 60 frames of 4 tics:
##      every frame each star moves by its own step (the misc chunk GALAXY:
##      four arrays of 4000 16-bit numbers, x, dx, y, dy, in 1/128 pixel);
##      a star whose next place lies beyond the screen's right or bottom edge
##      (or wraps round below 0) stops and is not drawn again; one exactly on
##      the right edge (x 320) shows at the left of the next row, where the
##      original's screen memory goes on (seen);
##   4. the normal palette, the GAMEOVER picture at (32, 80) for 24 seconds
##      or until a key.
## A key during the flashing or the stars goes straight to 4; a key during
## the fades counts for nothing (the original clears the keys first).
## Palette values are shown as the EGA's 200-line modes show them (bit 4
## is the bright bit, bit 3 does nothing): 0x08 is black, 0x0F light grey.

enum Stage { FADE_OUT, FADE_IN, FLASH, STARS, GAME_OVER, DONE }

const FADE_STEP_TICS := GalaxyEgaFade.STEP_TICS
## The game's last picture as the fade out darkens it, then black; the
## galaxy from black to whole (Omni VL_FadeToBlack, VL_FadeFromBlack).
const FADE_OUT_LEVELS: PackedInt32Array = [3, 2, 1, 0]
const FADE_IN_LEVELS: PackedInt32Array = [0, 1, 2, 3]
const FLASH_STEPS := 18
const FLASH_STEP_TICS := 10
## The palette values of entries 7 and 8 per flash step (Omni
## endsplosion_pal_change: entry 8 takes its first row, entry 7 its second,
## seen in the original).
const FLASH_VALUES_7: PackedInt32Array = [
	0x7, 0x7, 0x7, 0x7, 0x7, 0xF, 0x7, 0x8, 0x0, 0x7, 0xF, 0x7, 0x8, 0x0, 0x0, 0x0, 0x0, 0x0
]
const FLASH_VALUES_8: PackedInt32Array = [
	0x8, 0x8, 0x7, 0xF, 0x7, 0x8, 0x0, 0x8, 0x7, 0xF, 0x7, 0x8, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
]
const FLASHED_ENTRIES: PackedInt32Array = [7, 8]
const STAR_FRAMES := 60
const STAR_FRAME_TICS := 4
const STAR_COUNT := 4000
const STAR_COLOR := 15
const UNITS_PER_PIXEL := 0x80
const WORD := 0x10000
const GAME_OVER_AT := Vector2i(32, 80)
## 24 seconds (Omni IN_UserInput(24 * 70)).
const GAME_OVER_TICS := 24 * 70
const SCREEN_SIZE := Vector2i(320, 200)
const BRIGHT_BIT := 0x10
const COLOR_BITS := 7
const BRIGHT_INDEX := 8

var stage := Stage.FADE_OUT
## Tics into the stage.
var elapsed := 0
## The star frame shown (0 before the first).
var star_frame := 0
var _galaxy: Image
var _game_over: Image
## The galaxy's pixels of entries 7 and 8 (masks for the flashing).
var _masks: Array[Image] = []
var _stars_x := PackedInt32Array()
var _stars_dx := PackedInt32Array()
var _stars_y := PackedInt32Array()
var _stars_dy := PackedInt32Array()
var _stars: Image


## The scene from the Milky Way picture, the GAMEOVER picture and the
## stars' chunk.
static func create(galaxy: Image, game_over: Image, stars: PackedByteArray) -> Keen5GalaxyExplosion:
	var scene := Keen5GalaxyExplosion.new()
	scene._galaxy = _rgba(galaxy)
	scene._game_over = _rgba(game_over)
	scene._find_masks()
	scene._read_stars(stars)
	return scene


## The scene from Keen 5's files: pictures counted from the end of the
## range (the Milky Way the tenth, GAMEOVER the last; Omni GFXCHUNK.CK5),
## the misc chunk GALAXY.
static func from_data(data: GalaxyData) -> Keen5GalaxyExplosion:
	var count := data.graphics.ranges.picture_count
	return create(
		data.graphics.picture(count - Keen5Episode.MILKY_WAY_FROM_END),
		data.graphics.picture(count - Keen5Episode.GAME_OVER_FROM_END),
		data.graphics.misc(Keen5Episode.GALAXY_MISC)
	)


## The colour palette value [param value] shows in the EGA's 200-line
## modes.
static func shown_color(value: int) -> Color:
	var index := value & COLOR_BITS
	if value & BRIGHT_BIT != 0:
		index += BRIGHT_INDEX
	return EgaPalette.color(index)


func advance(tics: int) -> bool:
	if stage == Stage.DONE:
		return false
	var before := _shown()
	elapsed += tics
	while stage != Stage.DONE and elapsed >= _stage_tics():
		elapsed -= _stage_tics()
		_next_stage()
	if stage == Stage.STARS:
		_move_stars_to(elapsed / STAR_FRAME_TICS + 1)
	return _shown() != before


## A key: from the flashing or the stars to GAMEOVER, from GAMEOVER the
## end.
func press() -> bool:
	match stage:
		Stage.FLASH, Stage.STARS:
			stage = Stage.GAME_OVER
			elapsed = 0
			return true
		Stage.GAME_OVER:
			stage = Stage.DONE
			return true
	return false


func screen() -> Image:
	match stage:
		Stage.FADE_OUT:
			return null
		Stage.FADE_IN:
			return _galaxy
		Stage.FLASH:
			var step := elapsed / FLASH_STEP_TICS
			return _flashed(PackedInt32Array([FLASH_VALUES_7[step], FLASH_VALUES_8[step]]))
		Stage.STARS:
			return _stars
		Stage.GAME_OVER:
			var image := _black()
			if _game_over != null:
				image.blit_rect(
					_game_over, Rect2i(Vector2i.ZERO, _game_over.get_size()), GAME_OVER_AT
				)
			return image
	return _black()


func fade_level() -> int:
	match stage:
		Stage.FADE_OUT:
			return FADE_OUT_LEVELS[_fade_step()]
		Stage.FADE_IN:
			return FADE_IN_LEVELS[_fade_step()]
	return GalaxyEgaFade.WHOLE


func is_done() -> bool:
	return stage == Stage.DONE


## The galaxy with entries 7 and 8 showing palette values [param values].
func _flashed(values: PackedInt32Array) -> Image:
	if _galaxy == null:
		return _black()
	var image := _galaxy.duplicate() as Image
	var solid := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	for entry in _masks.size():
		var mask := _masks[entry]
		solid.fill(shown_color(values[entry]))
		image.blit_rect_mask(solid, mask, Rect2i(Vector2i.ZERO, mask.get_size()), Vector2i.ZERO)
	return image


## What the screen shows, as a number that changes when it does.
func _shown() -> int:
	match stage:
		Stage.FADE_OUT, Stage.FADE_IN:
			return stage * 100 + _fade_step()
		Stage.FLASH:
			return stage * 100 + elapsed / FLASH_STEP_TICS
		Stage.STARS:
			return stage * 100 + star_frame
	return stage * 100


func _fade_step() -> int:
	return mini(elapsed / FADE_STEP_TICS, FADE_OUT_LEVELS.size() - 1)


func _stage_tics() -> int:
	match stage:
		Stage.FADE_OUT:
			return FADE_OUT_LEVELS.size() * FADE_STEP_TICS
		Stage.FADE_IN:
			return FADE_IN_LEVELS.size() * FADE_STEP_TICS
		Stage.FLASH:
			return FLASH_STEPS * FLASH_STEP_TICS
		Stage.STARS:
			return STAR_FRAMES * STAR_FRAME_TICS
		Stage.GAME_OVER:
			return GAME_OVER_TICS
	return 0


func _next_stage() -> void:
	stage = (stage + 1) as Stage
	if stage == Stage.STARS:
		star_frame = 0
		_move_stars_to(1)


## Moves the stars until [param frame] frames are shown (at most 60).
func _move_stars_to(frame: int) -> void:
	var target := mini(frame, STAR_FRAMES)
	while star_frame < target:
		star_frame += 1
		_move_stars()


## One frame of the stars (Omni CK_GalExplodeUpdateCoords, from the last
## star to the first).
func _move_stars() -> void:
	_stars = _black()
	var right := SCREEN_SIZE.x * UNITS_PER_PIXEL
	var bottom := SCREEN_SIZE.y * UNITS_PER_PIXEL
	var color := EgaPalette.color(STAR_COLOR)
	for star in range(_stars_x.size() - 1, -1, -1):
		var x := (_stars_x[star] + _stars_dx[star]) & (WORD - 1)
		if x > right:
			continue
		_stars_x[star] = x
		var y := (_stars_y[star] + _stars_dy[star]) & (WORD - 1)
		if y > bottom:
			continue
		_stars_y[star] = y
		var pixel := Vector2i(x / UNITS_PER_PIXEL, y / UNITS_PER_PIXEL)
		if pixel.x == SCREEN_SIZE.x:
			# On the right edge: the next row's first pixel in screen memory.
			pixel = Vector2i(0, pixel.y + 1)
		if pixel.y < SCREEN_SIZE.y:
			_stars.set_pixelv(pixel, color)


func _read_stars(chunk: PackedByteArray) -> void:
	var count := mini(STAR_COUNT, chunk.size() / 8)
	if count < STAR_COUNT:
		push_error("The galaxy's stars are %d bytes, not %d." % [chunk.size(), STAR_COUNT * 8])
	var arrays: Array[PackedInt32Array] = [_stars_x, _stars_dx, _stars_y, _stars_dy]
	for array in arrays.size():
		var start := array * STAR_COUNT * 2
		for star in count:
			var at := start + star * 2
			arrays[array].append(chunk.decode_u16(at) if array % 2 == 0 else chunk.decode_s16(at))


## The galaxy's pixels of each flashed entry, as masks.
func _find_masks() -> void:
	for entry in FLASHED_ENTRIES:
		var mask := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
		if _galaxy != null:
			for y in mini(_galaxy.get_height(), SCREEN_SIZE.y):
				for x in mini(_galaxy.get_width(), SCREEN_SIZE.x):
					if GalaxyEga.index_of(_galaxy.get_pixel(x, y)) == entry:
						mask.set_pixel(x, y, Color.WHITE)
		_masks.append(mask)


static func _black() -> Image:
	var image := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	return image


static func _rgba(picture: Image) -> Image:
	if picture == null:
		return null
	var copy := picture.duplicate() as Image
	if copy.get_format() != Image.FORMAT_RGBA8:
		copy.convert(Image.FORMAT_RGBA8)
	return copy
