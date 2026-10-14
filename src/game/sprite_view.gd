class_name SpriteView
extends Node2D
## Draws one sprite from the game graphics at a position in the level: Keen,
## his ship in the ending, or the "?" and "!" next to it.

var _sprites: Array[Image] = []
var _textures: Dictionary[int, ImageTexture] = {}
var _sprite := Sprite2D.new()


func _init() -> void:
	_sprite.centered = false
	add_child(_sprite)


## Uses the sprites in [param graphics] for drawing.
func set_graphics(graphics: EgaGraphics) -> void:
	_sprites = graphics.sprites
	_textures.clear()


## Shows sprite [param sprite_index] with its top left at [param at], or
## nothing when the index is negative.
func show_sprite(at: Vector2, sprite_index: int) -> void:
	position = at.floor()
	_sprite.texture = _texture(sprite_index)
	_sprite.visible = _sprite.texture != null
	_sprite.region_enabled = false


## Shows only the left [param width] pixels of the sprite.
func clip_width(width: float, height: float) -> void:
	_sprite.visible = _sprite.visible and width >= 1.0
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, floorf(width), height)


func _texture(sprite_index: int) -> ImageTexture:
	if sprite_index < 0 or sprite_index >= _sprites.size():
		return null
	if not _textures.has(sprite_index):
		_textures[sprite_index] = ImageTexture.create_from_image(_sprites[sprite_index])
	return _textures[sprite_index]
