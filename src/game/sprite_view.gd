class_name SpriteView
extends Node2D
## Draws one sprite from the game graphics at a position in the level: Keen,
## his ship in the ending, or the "?" and "!" next to it.
##
## [method show_sprite] is called after every tick; [method place] puts the
## sprite on the screen every frame, in between the last two ticks when
## motion is smooth (see [Interpolation]).

var _textures: GraphicsTextures
var _sprite := Sprite2D.new()
var _sprite_index := -1
var _motion := Interpolation.new()


func _init() -> void:
	_sprite.centered = false
	add_child(_sprite)


## Uses [param textures] for drawing.
func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures
	refresh()


## Takes the textures again, after the graphics changed.
func refresh() -> void:
	_sprite.texture = _textures.sprite(_sprite_index) if _textures != null else null


## Shows sprite [param sprite_index] with its top left at [param at], or
## nothing when the index is negative.
func show_sprite(at: Vector2, sprite_index: int) -> void:
	_motion.move_to(at)
	if sprite_index != _sprite_index:
		_sprite_index = sprite_index
		refresh()
	_sprite.visible = _sprite.texture != null
	_sprite.region_enabled = false
	place(1.0, false)


## Puts the sprite where it is [param blend] of the way from the previous
## tick to the last one. Unless [param smooth], on the last one, on a whole
## pixel.
func place(blend: float, smooth: bool) -> void:
	position = _motion.at(blend, smooth)


## Where the sprite is drawn now, without rounding.
func smooth_position() -> Vector2:
	return _motion.last_at


## Forgets the previous position, so that the sprite does not glide to its
## next one (after it moved to another map).
func snap() -> void:
	_motion.snap()
	position = _motion.at(1.0, false)


## Shows only the left [param width] pixels of the sprite.
func clip_width(width: float, height: float) -> void:
	_sprite.visible = _sprite.visible and width >= 1.0
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, floorf(width), height)
