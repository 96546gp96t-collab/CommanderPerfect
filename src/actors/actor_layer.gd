class_name ActorLayer
extends Node2D
## Draws the [Actor]s of a [LevelSession]: one Sprite2D per actor, created
## when the actor appears and freed when it is gone.
##
## [method show_actors] is called after every tick; [method place] puts the
## sprites on the screen every frame (see [Interpolation]).

var _textures: GraphicsTextures
var _sprites: Dictionary[Actor, Sprite2D] = {}
var _motions: Dictionary[Actor, Interpolation] = {}


## Uses the sprites and tiles in [param textures] for drawing.
func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures
	refresh()


## Takes the textures again, after the graphics changed.
func refresh() -> void:
	for actor in _sprites:
		var sprite := _sprites[actor]
		if actor is OpeningDoor:
			sprite.texture = _textures.door(actor.tiles)
		else:
			sprite.texture = null
			_update_sprite(sprite, actor)


## Removes every sprite, for example when a level starts.
func clear() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()
	_motions.clear()


## Shows [param actors] as they are now.
func show_actors(actors: Array[Actor]) -> void:
	for actor in _sprites.keys():
		if actor.removed or not actors.has(actor):
			_sprites[actor].queue_free()
			_sprites.erase(actor)
			_motions.erase(actor)
	for actor in actors:
		var sprite: Sprite2D = _sprites.get(actor)
		if sprite == null:
			sprite = _create_sprite(actor)
			_sprites[actor] = sprite
			_motions[actor] = Interpolation.new()
		_motions[actor].move_to(actor.position)
		_update_sprite(sprite, actor)
	place(1.0, false)


## Puts every sprite [param blend] of the way from the previous tick to the
## last one; see [method Interpolation.at].
func place(blend: float, smooth: bool) -> void:
	for actor in _sprites:
		_sprites[actor].position = _motions[actor].at(blend, smooth)


func _create_sprite(actor: Actor) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	if actor is OpeningDoor:
		sprite.texture = _textures.door(actor.tiles)
		sprite.region_enabled = true
	add_child(sprite)
	return sprite


func _update_sprite(sprite: Sprite2D, actor: Actor) -> void:
	if actor is OpeningDoor:
		# The door sinks into the floor: only its top part is still visible.
		sprite.region_rect = Rect2(0, 0, EgaGraphics.TILE_SIZE, actor.visible_height)
		return
	var index := actor.sprite_index()
	sprite.visible = index >= 0
	if index >= 0:
		sprite.texture = _textures.sprite(index)
