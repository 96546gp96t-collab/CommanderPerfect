class_name ActorLayer
extends Node2D
## Draws the [Actor]s of a [LevelSession]: one Sprite2D per actor, created
## when the actor appears and freed when it is gone.

var _graphics: EgaGraphics
var _sprite_textures: Dictionary[int, ImageTexture] = {}
var _sprites: Dictionary[Actor, Sprite2D] = {}


## Uses the sprites and tiles in [param graphics] for drawing.
func set_graphics(graphics: EgaGraphics) -> void:
	_graphics = graphics
	_sprite_textures.clear()


## Removes every sprite, for example when a level starts.
func clear() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()


## Shows [param actors] as they are now.
func show_actors(actors: Array[Actor]) -> void:
	for actor in _sprites.keys():
		if actor.removed or not actors.has(actor):
			_sprites[actor].queue_free()
			_sprites.erase(actor)
	for actor in actors:
		var sprite: Sprite2D = _sprites.get(actor)
		if sprite == null:
			sprite = _create_sprite(actor)
			_sprites[actor] = sprite
		_update_sprite(sprite, actor)


func _create_sprite(actor: Actor) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	if actor is OpeningDoor:
		sprite.texture = _door_texture(actor.tiles)
		sprite.region_enabled = true
	add_child(sprite)
	return sprite


func _update_sprite(sprite: Sprite2D, actor: Actor) -> void:
	sprite.position = actor.position.floor()
	if actor is OpeningDoor:
		# The door sinks into the floor: only its top part is still visible.
		sprite.region_rect = Rect2(0, 0, EgaGraphics.TILE_SIZE, actor.visible_height)
		return
	var index := actor.sprite_index()
	sprite.visible = index >= 0
	if index >= 0:
		sprite.texture = _sprite_texture(index)


func _sprite_texture(index: int) -> ImageTexture:
	if not _sprite_textures.has(index) and index < _graphics.sprites.size():
		_sprite_textures[index] = ImageTexture.create_from_image(_graphics.sprites[index])
	return _sprite_textures.get(index)


## The door tiles stacked on top of each other in one picture.
func _door_texture(tiles: PackedInt32Array) -> ImageTexture:
	var size := EgaGraphics.TILE_SIZE
	var image := Image.create_empty(size, size * tiles.size(), false, Image.FORMAT_RGBA8)
	for i in tiles.size():
		var tile := _graphics.tiles[tiles[i]]
		image.blit_rect(tile, Rect2i(0, 0, size, size), Vector2i(0, i * size))
	return ImageTexture.create_from_image(image)
