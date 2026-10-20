class_name GalaxyObjectLayer
extends Node2D
## Draws the sprites of a Galaxy level: every object's sprite at its
## position + the sprite's origin (both in global units, 16 per pixel;
## [GalaxySpriteInfo]), on whole pixels as the original does, or with the
## shared [Interpolation] between the last two logic frames when motion is
## smooth.
##
## The original sorts its sprites by priority 0-3 (Omni `id_rf.c`): 0-2 are
## drawn over the tiles but under the foreground tiles that are in front
## ([constant GalaxyLevelMap.FRONT_Z]), 3 over everything. Within one
## priority the sprite placed last is drawn first, so under the others
## (the original puts a new sprite at the head of its list).
##
## The objects themselves ([GalaxyObject], run by [GalaxyWorld]) are shown
## with [method show_objects] after every logic frame; this layer only
## knows what to draw where.


## One sprite on the layer.
class Item:
	extends RefCounted
	## The sprite (an index into the episode's sprites).
	var sprite := 0
	## The object's position, in units.
	var position := Vector2i.ZERO
	var priority := 1
	var node := Sprite2D.new()
	var motion := Interpolation.new()


## Priorities run from 0 to this.
const TOP_PRIORITY := 3
const UNITS_PER_PIXEL := 16.0

var _graphics: GalaxyGraphics
var _scaled: GalaxyScaledGraphics
var _items: Array[Item] = []
var _textures: Dictionary[int, Texture2D] = {}
## The item of every object shown, by object.
var _shown: Dictionary[GalaxyObject, Item] = {}


## The z index of a sprite of [param priority]: 0-2 above the tiles and
## under the in-front tiles, 3 above those.
static func z_of(priority: int) -> int:
	if priority >= TOP_PRIORITY:
		return GalaxyLevelMap.FRONT_Z + 1
	return 1 + clampi(priority, 0, TOP_PRIORITY - 1)


## Where the picture of a sprite with [param info] goes for an object at
## [param position] (units), in pixels, as the original draws it.
static func pixel_of(info: GalaxySpriteInfo, position: Vector2i) -> Vector2i:
	var corner := position + info.origin
	return Vector2i(corner.x >> 4, corner.y >> 4)


## Draws the sprites of [param graphics] from now on, scaled ones from
## [param scaled] where it has them (xBRZ), otherwise the original ones.
func use_graphics(graphics: GalaxyGraphics, scaled: GalaxyScaledGraphics = null) -> void:
	_graphics = graphics
	_scaled = scaled
	_textures.clear()
	for item in _items:
		item.node.texture = _texture(item.sprite)


## Adds sprite [param sprite] at [param position] (units) with
## [param priority]; returns the item to move later.
func add(sprite: int, position: Vector2i, priority: int) -> Item:
	var item := Item.new()
	item.priority = priority
	item.node.centered = false
	item.node.z_index = z_of(priority)
	add_child(item.node)
	# Under the sprites of the same priority that were placed before it.
	move_child(item.node, 0)
	_items.append(item)
	move(item, sprite, position)
	item.motion.snap()
	return item


## After a logic frame: [param item] shows [param sprite] at
## [param position] (units).
func move(item: Item, sprite: int, position: Vector2i) -> void:
	if sprite != item.sprite or item.node.texture == null:
		item.node.texture = _texture(sprite)
	item.sprite = sprite
	item.position = position
	var info := _info(sprite)
	var corner := Vector2(position + (info.origin if info != null else Vector2i.ZERO))
	item.motion.move_to(corner / UNITS_PER_PIXEL)


func remove(item: Item) -> void:
	_items.erase(item)
	item.node.queue_free()


func clear() -> void:
	for item in _items:
		item.node.queue_free()
	_items.clear()
	_shown.clear()


## After a logic frame: every awake object with a sprite is drawn where it
## is, with its priority; the others are not. Objects that left the world
## lose their item.
func show_objects(objects: Array[GalaxyObject]) -> void:
	var present: Dictionary[GalaxyObject, bool] = {}
	for object in objects:
		present[object] = true
		var shown := GalaxyWorld.is_awake(object) and object.sprite != GalaxyObject.NO_SPRITE
		var item: Item = _shown.get(object)
		if item == null:
			if not shown:
				continue
			item = add(object.sprite, object.position, object.priority)
			_shown[object] = item
		if item.priority != object.priority:
			item.priority = object.priority
			item.node.z_index = z_of(object.priority)
		item.node.visible = shown
		if shown:
			move(item, object.sprite, object.position)
	for object in _shown.keys():
		if not present.has(object):
			remove(_shown[object])
			_shown.erase(object)


func items() -> Array[Item]:
	return _items


## Puts every sprite [param blend] of the way from the previous logic frame
## to the last one when [param smooth]; otherwise on the last one, on a
## whole pixel.
func place(blend: float, smooth: bool) -> void:
	for item in _items:
		item.node.position = item.motion.at(blend, smooth)


func _info(sprite: int) -> GalaxySpriteInfo:
	if _graphics == null or sprite < 0 or sprite >= _graphics.sprite_infos.size():
		return null
	return _graphics.sprite_infos[sprite]


func _texture(sprite: int) -> Texture2D:
	if _graphics == null:
		return null
	if _textures.has(sprite):
		return _textures[sprite]
	var original := _graphics.sprite(sprite)
	var texture: ImageTexture = null
	if original != null:
		var big := _scaled.sprite(sprite) if _scaled != null else null
		texture = ImageTexture.create_from_image(big if big != null else original)
		if big != null:
			texture.set_size_override(original.get_size())
	_textures[sprite] = texture
	return texture
