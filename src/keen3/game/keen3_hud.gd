class_name Keen3Hud
extends Hud
## The [Hud] of Keen 3 (widescreen only): the same two panels as Keen 1 and
## 2 (lives and score; raygun charges and keycards), with two changes:
##   - the little Keen for the lives is Keen 3's own map Keen looking at the
##     player (sprite 35; Keen 1's number 36 is another frame in Keen 3)
##   - while the ankh protects Keen, a third panel under the right one shows
##     the ankh and its time in whole "seconds" as the status screen counts
##     them ([method Keen3Body.ankh_seconds])
##   - the item pictures (raygun, keycards, ankh) leave out the background
##     colour of their row in the tile table (each row has its own; the
##     shared HUD only knows Keen 1's gray)
## The view sets [member ankh_tile] (the first tile with the ankh's
## behaviour, [method Keen2Icons.first_tile_with]) and calls
## [method show_ankh_time] every frame.

## Keen 3's map Keen looking at the player (MAPKEEND1).
const KEEN_3_LIFE_SPRITE := 35

## The ankh's tile; -1 draws no picture in its panel.
var ankh_tile := -1
## The ankh time shown; -1 when the ankh does not run (no panel).
var _ankh_seconds := -1
## Item tiles without their row's background, by tile; made for
## [member _cleared_for] (the scaled graphics in use, or null).
var _cleared_tiles: Dictionary[int, ImageTexture] = {}
var _cleared_for: ScaledGraphics


## [param tile] (an item tile) with every pixel of [param background]'s
## colour that touches its edge, directly or through more of that colour,
## left out. [param background] is the first tile of the item's row, a
## plain tile of the row's colour; colour inside the item stays.
static func without_row_background(tile: Image, background: Image) -> Image:
	var image := tile.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var color := background.get_pixel(0, 0)
	var size := image.get_size()
	var pending: Array[Vector2i] = []
	for x in size.x:
		pending.append_array([Vector2i(x, 0), Vector2i(x, size.y - 1)])
	for y in size.y:
		pending.append_array([Vector2i(0, y), Vector2i(size.x - 1, y)])
	while not pending.is_empty():
		var pixel: Vector2i = pending.pop_back()
		if not Rect2i(Vector2i.ZERO, size).has_point(pixel):
			continue
		if not image.get_pixelv(pixel).is_equal_approx(color):
			continue
		image.set_pixelv(pixel, Color.TRANSPARENT)
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			pending.append(pixel + step)
	return image


## Shows the ankh time, [param seconds], or no ankh panel when
## [param running] is false. Redraws only when something changed.
func show_ankh_time(running: bool, seconds: int) -> void:
	var shown := seconds if running else -1
	if shown == _ankh_seconds:
		return
	_ankh_seconds = shown
	queue_redraw()


func _draw() -> void:
	super._draw()
	if _textures != null and _ankh_seconds >= 0:
		_draw_ankh_panel()


## Lives and score, as [Hud] draws them, with Keen 3's little Keen.
func _draw_left_panel() -> void:
	var lives := str(_lives)
	var score := SCORE_LABEL + str(_score)
	var width := ICON + lives.length() * CHAR + SCORE_GAP + score.length() * CHAR
	var inside := _panel(Vector2(MARGIN, MARGIN), width)
	var keen := _textures.sprite(KEEN_3_LIFE_SPRITE)
	if keen != null:
		draw_texture(keen, inside)
	var x := inside.x + ICON
	_textures.draw_text(self, Vector2(x, inside.y + TEXT_OFFSET), lives, true)
	x += lives.length() * CHAR + SCORE_GAP
	_textures.draw_text(self, Vector2(x, inside.y + TEXT_OFFSET), score, true)


## The ankh and its time, against the right edge under the right panel.
func _draw_ankh_panel() -> void:
	var seconds := str(_ankh_seconds)
	var width := ICON + seconds.length() * CHAR
	var left := view_size.x - MARGIN - width - 2 * PADDING
	var top := MARGIN + ICON + 2 * PADDING + MARGIN
	var inside := _panel(Vector2(left, top), width)
	if ankh_tile >= 0:
		_draw_tile(inside, ankh_tile)
	_textures.draw_text(self, Vector2(inside.x + ICON, inside.y + TEXT_OFFSET), seconds, true)


## An item tile without its row's background (instead of [Hud]'s gray).
func _draw_tile(at: Vector2, tile: int) -> void:
	var texture := _cleared_tile(tile)
	if texture != null:
		draw_texture(texture, at)


func _cleared_tile(tile: int) -> ImageTexture:
	if _textures.graphics == null or tile < 0 or tile >= _textures.graphics.tiles.size():
		return null
	if _cleared_for != _textures.scaled:
		_cleared_tiles.clear()
		_cleared_for = _textures.scaled
	if not _cleared_tiles.has(tile):
		var tiles := _textures.graphics.tiles
		var background := tiles[Keen3LevelSession.row_background(tile)]
		var image := without_row_background(tiles[tile], background)
		_cleared_tiles[tile] = _texture_of(image, tile)
	return _cleared_tiles[tile]


## A texture of [param image], made from [param tile]: with scaled graphics
## the scaled tile with the same holes, at the original size.
func _texture_of(image: Image, tile: int) -> ImageTexture:
	var scaled := _textures.scaled
	if scaled == null:
		return ImageTexture.create_from_image(image)
	var texture := ImageTexture.create_from_image(scaled.derive(image, scaled.tiles[tile]))
	texture.set_size_override(image.get_size())
	return texture
