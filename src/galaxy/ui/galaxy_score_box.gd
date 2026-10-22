class_name GalaxyScoreBox
extends Sprite2D
## The original's score box, the only HUD of a Galaxy episode (decided by
## the user: in the top-left of the visible picture, in 4:3 and widescreen
## alike; docs/keen4/architecture.md, "The score box and the HUD"). It is
## the episode's SCOREBOX sprite with the numbers drawn into it as the
## original does (Omni `ck_map.c:CK_UpdateScoreBox`): unmasked 8×8 tiles
## for the digits ('0' is tile 42, a blank 41), right-aligned, the score
## (9 digits) at (8, 4), the lives (2) at (24, 20) and the stunner charges
## (2) at (64, 20); at most 99 is shown. The original puts the sprite 4
## pixels from the view's top-left corner, in front of everything.

## Where the box is drawn on the screen, in pixels (Omni: scroll + 0x40
## units).
const SCREEN_OFFSET := Vector2(4, 4)
## The 8×8 tile of the digit 0 (the character code − 6), and of a blank.
const ZERO_TILE := 42
const BLANK_TILE := 41
const DIGIT_SIZE := 8
const SCORE_AT := Vector2i(8, 4)
const SCORE_DIGITS := 9
const LIVES_AT := Vector2i(24, 20)
const SHOTS_AT := Vector2i(64, 20)
const SMALL_DIGITS := 2
const MAX_SMALL := 99

var _graphics: GalaxyGraphics
var _blank: Image
var _shown := PackedInt32Array([-1, -1, -1])


func _init() -> void:
	centered = false
	position = SCREEN_OFFSET
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Uses sprite [param sprite] of [param graphics] as the box (its origin is
## added to [constant SCREEN_OFFSET]).
func use_graphics(graphics: GalaxyGraphics, sprite: int) -> void:
	_graphics = graphics
	_blank = graphics.sprite(sprite)
	if _blank != null:
		_blank.convert(Image.FORMAT_RGBA8)
		var origin := graphics.sprite_infos[sprite].origin
		position = SCREEN_OFFSET + Vector2(origin / GalaxyUnits.PER_PIXEL)
	_shown = PackedInt32Array([-1, -1, -1])


## Shows [param score], [param lives] and [param shots]; the picture is
## only made again when one of them changed.
func show_numbers(score: int, lives: int, shots: int) -> void:
	var numbers := PackedInt32Array([score, lives, shots])
	if numbers == _shown or _blank == null:
		return
	_shown = numbers
	texture = ImageTexture.create_from_image(picture_for(score, lives, shots))


## The box with [param score], [param lives] and [param shots] drawn in.
func picture_for(score: int, lives: int, shots: int) -> Image:
	var image := _blank.duplicate() as Image
	_draw_number(image, str(score), SCORE_AT, SCORE_DIGITS)
	_draw_number(image, str(mini(lives, MAX_SMALL)), LIVES_AT, SMALL_DIGITS)
	_draw_number(image, str(mini(shots, MAX_SMALL)), SHOTS_AT, SMALL_DIGITS)
	return image


## [param text] right-aligned in [param places] digits at [param at];
## only where the box itself is drawn (its mask stays as it is).
func _draw_number(image: Image, text: String, at: Vector2i, places: int) -> void:
	var digits := text.right(places)
	for place in places:
		var index := place - (places - digits.length())
		var tile := BLANK_TILE
		if index >= 0:
			tile = ZERO_TILE + digits.unicode_at(index) - "0".unicode_at(0)
		var digit := _graphics.tile8(tile)
		if digit == null:
			continue
		var corner := at + Vector2i(place * DIGIT_SIZE, 0)
		for y in DIGIT_SIZE:
			for x in DIGIT_SIZE:
				var pixel := corner + Vector2i(x, y)
				if image.get_pixelv(pixel).a > 0.0:
					image.set_pixelv(pixel, digit.get_pixel(x, y))
