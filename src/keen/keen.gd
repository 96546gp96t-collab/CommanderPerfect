class_name Keen
extends Node2D
## Draws Keen: the sprite that [KeenBody] asks for, at its position. The
## logic itself runs in [LevelSession].
##
## The [LevelCamera] can be a child, so that the view follows Keen.

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


## Shows [param body] as it is now.
func show_body(body: KeenBody) -> void:
	position = body.position.floor()
	_sprite.texture = _texture(body.sprite_index())


func _texture(sprite_index: int) -> ImageTexture:
	if not _textures.has(sprite_index) and sprite_index < _sprites.size():
		_textures[sprite_index] = ImageTexture.create_from_image(_sprites[sprite_index])
	return _textures.get(sprite_index)
