class_name Hud
extends Node2D
## A little extra information in the top corners of the view, shown only in
## widescreen, where there is room for it. The original has nothing like
## it; it only has the status screen.
##
##   top left    Keen (as in the "Keens Left" window) with the number of
##               lives, and "Score" with the score: the game has no picture
##               that clearly means score
##   top right   the raygun with its charges, and the keycards Keen has
## Each corner is one row on a small light blue panel, drawn with the game
## font and the item tiles, whose gray level background is left out. Put
## the node in a CanvasLayer, so that the camera does not move it.

## Keen on the map, looking at the player, stands for a life.
const LIFE_SPRITE := MapMessages.LIFE_SPRITE
const CHAR := EgaGraphics.FONT_CHAR_SIZE
const ICON := EgaGraphics.TILE_SIZE
## Distance of the panels from the edges of the view, and the space around
## their contents.
const MARGIN := 3
const PADDING := 2
## Space between a number and the next icon.
const GAP := 6
## Space between the lives and the score, so that they look apart.
const SCORE_GAP := 12
const SCORE_LABEL := "Score "
## Text is 8 pixels high, icons 16: this puts the text in the middle.
const TEXT_OFFSET := (ICON - CHAR) / 2
## Baby blue, close to white, with a soft blue edge.
const PANEL_COLOR := Color("e4f1ff")
const OUTLINE_COLOR := Color("8fb6e6")

## Size of the view in game pixels; the right panel sits against its edge.
var view_size := Vector2i(426, 200)
var _textures: GraphicsTextures
var _lives := 0
var _score := 0
var _charges := 0
var _keycards: Array[bool] = [false, false, false, false]


func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures
	queue_redraw()


## Shows what [param inventory] holds; redraws only when something changed.
func show_inventory(inventory: Inventory) -> void:
	var lives := maxi(inventory.lives, 0)
	if (
		lives == _lives
		and inventory.score == _score
		and inventory.charges == _charges
		and inventory.keycards == _keycards
	):
		return
	_lives = lives
	_score = inventory.score
	_charges = inventory.charges
	_keycards = inventory.keycards.duplicate()
	queue_redraw()


## The tiles in the right panel after the raygun: the keycards Keen has, in
## the order of [enum TileProperties.KeyColor].
static func keycard_tiles(keycards: Array[bool]) -> PackedInt32Array:
	var tiles := PackedInt32Array()
	for color in keycards.size():
		if keycards[color]:
			tiles.append(StatusScreen.KEYCARD_TILES[color])
	return tiles


func _draw() -> void:
	if _textures == null:
		return
	_draw_left_panel()
	_draw_right_panel()


func _draw_left_panel() -> void:
	var lives := str(_lives)
	var score := SCORE_LABEL + str(_score)
	var width := ICON + lives.length() * CHAR + SCORE_GAP + score.length() * CHAR
	var inside := _panel(Vector2(MARGIN, MARGIN), width)
	var keen := _textures.sprite(LIFE_SPRITE)
	if keen != null:
		draw_texture(keen, inside)
	var x := inside.x + ICON
	_textures.draw_text(self, Vector2(x, inside.y + TEXT_OFFSET), lives, true)
	x += lives.length() * CHAR + SCORE_GAP
	_textures.draw_text(self, Vector2(x, inside.y + TEXT_OFFSET), score, true)


func _draw_right_panel() -> void:
	var charges := str(_charges)
	var cards := keycard_tiles(_keycards)
	var width := ICON + charges.length() * CHAR
	if not cards.is_empty():
		width += GAP + cards.size() * ICON
	var left := view_size.x - MARGIN - width - 2 * PADDING
	var inside := _panel(Vector2(left, MARGIN), width)
	_draw_tile(inside, StatusScreen.RAYGUN_TILE)
	_textures.draw_text(self, Vector2(inside.x + ICON, inside.y + TEXT_OFFSET), charges, true)
	var x := inside.x + ICON + charges.length() * CHAR + GAP
	for tile in cards:
		_draw_tile(Vector2(x, inside.y), tile)
		x += ICON


## Draws a panel at [param at] for contents [param width] pixels wide and
## one icon high. Returns the top left of the contents.
func _panel(at: Vector2, width: int) -> Vector2:
	var rect := Rect2(at, Vector2(width + 2 * PADDING, ICON + 2 * PADDING))
	draw_rect(rect, PANEL_COLOR)
	draw_rect(rect.grow(1), OUTLINE_COLOR, false, 1.0)
	return at + Vector2(PADDING, PADDING)


func _draw_tile(at: Vector2, tile: int) -> void:
	var texture := _textures.clear_tile(tile)
	if texture != null:
		draw_texture(texture, at)
