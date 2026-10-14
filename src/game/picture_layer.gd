class_name PictureLayer
extends Node2D
## Draws bitmaps and text in the game font on top of a map, at positions in
## map pixels: the title over Keen's ship, and the high score table in its
## red frame. Both are screens of map 90.

var _textures: GraphicsTextures
var _bitmaps: Array[Dictionary] = []
var _texts: Array[Dictionary] = []
var _tiles: Array[Dictionary] = []


func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures
	queue_redraw()


func clear() -> void:
	_bitmaps.clear()
	_texts.clear()
	_tiles.clear()
	queue_redraw()


## Draws bitmap [param bitmap_name] with its top left at [param at].
func put_bitmap(at: Vector2, bitmap_name: String) -> void:
	_bitmaps.append({"at": at, "name": bitmap_name})
	queue_redraw()


## Writes [param text] with the top left of its first character at [param at].
func put_text(at: Vector2, text: String) -> void:
	_texts.append({"at": at, "text": text})
	queue_redraw()


## Draws tile [param tile] with its top left at [param at].
func put_tile(at: Vector2, tile: int) -> void:
	_tiles.append({"at": at, "tile": tile})
	queue_redraw()


## Width in pixels of [param bitmap_name], or 0 when there is no such bitmap.
func bitmap_width(bitmap_name: String) -> int:
	var texture := _textures.bitmap(bitmap_name) if _textures != null else null
	return texture.get_width() if texture != null else 0


func _draw() -> void:
	if _textures == null:
		return
	for item in _bitmaps:
		var texture := _textures.bitmap(item.name)
		if texture != null:
			draw_texture(texture, item.at)
	for item in _tiles:
		var texture := _textures.tile(item.tile)
		if texture != null:
			draw_texture(texture, item.at)
	for item in _texts:
		_textures.draw_text(self, item.at, item.text, true)
