class_name Keen
extends Node2D
## Keen in a level: runs [KeenBody] at a fixed [constant KeenPhysics.TICKS_PER_SECOND]
## ticks per second with the player's input, and draws the matching sprite.
##
## The [LevelCamera] can be a child, so that the view follows Keen. Until
## dying and lives exist (milestone 4), Keen simply starts over at the start
## of the level when he touches something deadly or falls out of the level.

## Emitted after Keen died and was put back at the start.
signal died

var body: KeenBody
var _start := Vector2.ZERO
var _time_left := 0.0
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


## Places Keen at [param start] (top left of the sprite) in a level.
func enter_level(collision: LevelCollision, start: Vector2) -> void:
	_start = start
	body = KeenBody.create(collision, start)
	_time_left = 0.0
	_show_body()


func _process(delta: float) -> void:
	if body == null:
		return
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	while _time_left >= KeenPhysics.TICK:
		_time_left -= KeenPhysics.TICK
		body.step(KeenInput.from_actions())
		if body.is_dead:
			body.reset(_start)
			_show_body()
			died.emit()
	_show_body()


func _show_body() -> void:
	position = body.position.floor()
	_sprite.texture = _texture(body.sprite_index())


func _texture(sprite_index: int) -> ImageTexture:
	if not _textures.has(sprite_index) and sprite_index < _sprites.size():
		_textures[sprite_index] = ImageTexture.create_from_image(_sprites[sprite_index])
	return _textures.get(sprite_index)
