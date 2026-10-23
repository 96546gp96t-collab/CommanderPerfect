class_name GalaxyObjectLayer
extends Node2D
## Draws the sprites of a Galaxy level: every object's sprite at its
## position + the sprite's origin (both in global units, 16 per pixel;
## [GalaxySpriteInfo]), where the original draws it ([method pixel_of]), or
## with the shared [Interpolation] between the last two logic frames, at
## the exact place, when motion is smooth. An object that flashes
## ([member GalaxyObject.flash_white]) is drawn all white meanwhile.
##
## The original keeps only a few shifted copies of each sprite (the
## sprite table's shift count: 1, 2 or 4), so it can only draw a sprite at
## x steps of 8 / shifts pixels: its x is rounded down to that step (Omni
## `id_rf.c:RF_AddSpriteDraw`, `id_ca.c:CAL_CacheSprite`; measured on the
## demos in D8). Most sprites have 4 shifts (2-pixel steps); Keen going
## through a door has 1 (8-pixel steps: he jumps up to 7 pixels left).
##
## The original sorts its sprites by priority 0-3 (Omni `id_rf.c`): 0-2 are
## drawn over the tiles but under the foreground tiles that are in front
## ([constant GalaxyLevelMap.FRONT_Z]), 3 over everything. Within one
## priority the sprite placed last is drawn first, so under the others
## (the original puts a new sprite at the head of its list).
##
## The objects themselves ([GalaxyObject], run by [GalaxyWorld]) are shown
## with [method show_objects] after every logic frame; this layer only
## knows what to draw where. An object can be drawn with a material of its
## own ([method tint]: the second player's Keen in his colours, D12).


## One sprite on the layer.
class Item:
	extends RefCounted
	## The sprite (an index into the episode's sprites).
	var sprite := 0
	## The object's position, in units.
	var position := Vector2i.ZERO
	## Where the original draws the sprite, in pixels ([method pixel_of]).
	var pixel := Vector2i.ZERO
	var priority := 1
	var node := Sprite2D.new()
	var motion := Interpolation.new()


## Priorities run from 0 to this.
const TOP_PRIORITY := 3
const UNITS_PER_PIXEL := 16.0
## A byte of a planar EGA row holds 8 pixels; the shifted copies of a
## sprite share them out (Omni CAL_CacheSprite).
const PIXELS_PER_BYTE := 8
## The shift counts the original knows; any other is drawn on whole
## pixels.
const SHIFT_COUNTS: Array[int] = [1, 2, 4]
## Draws a sprite in white where it is not see-through (EGA colour 15).
const WHITE_SHADER := """
shader_type canvas_item;
void fragment() {
	COLOR = vec4(1.0, 1.0, 1.0, texture(TEXTURE, UV).a);
}
"""

## Whether the order of the sprites of one priority follows the original
## all the way (Keen 5, E7): an object that is not drawn (asleep, without a
## sprite) loses its place, and one whose priority changes goes under the
## others of its new priority, as the original's sprite list does (Omni
## RF_RemoveSpriteDraw, RF_AddSpriteDraw). Off: Keen 4's layer as proven,
## where such an object keeps its place.
var original_order := false
var _graphics: GalaxyGraphics
var _scaled: GalaxyScaledGraphics
var _items: Array[Item] = []
var _textures: Dictionary[int, Texture2D] = {}
## The item of every object shown, by object.
var _shown: Dictionary[GalaxyObject, Item] = {}
## The items of the overlays of every object shown ([GalaxyObject.Overlay]).
var _overlays: Dictionary[GalaxyObject, Array] = {}
## The materials objects are drawn with, when not the plain one.
var _tints: Dictionary[GalaxyObject, Material] = {}
## The objects drawn white now ([member GalaxyObject.flash_white]).
var _flashing: Dictionary[GalaxyObject, bool] = {}
var _white: ShaderMaterial


## The z index of a sprite of [param priority]: 0-2 above the tiles and
## under the in-front tiles, 3 above those.
static func z_of(priority: int) -> int:
	if priority >= TOP_PRIORITY:
		return GalaxyLevelMap.FRONT_Z + 1
	return 1 + clampi(priority, 0, TOP_PRIORITY - 1)


## Where the picture of a sprite with [param info] goes for an object at
## [param position] (units), in pixels, as the original draws it: x
## rounded down to [method x_step] pixels, y on its whole pixel.
static func pixel_of(info: GalaxySpriteInfo, position: Vector2i) -> Vector2i:
	var corner := position + info.origin
	# The steps are powers of two: clearing the low bits rounds down.
	return Vector2i((corner.x >> 4) & ~(x_step(info.shifts) - 1), corner.y >> 4)


## The x step, in pixels, of a sprite with [param shifts] shifted copies:
## 8 for 1, 4 for 2, 2 for 4 (whole pixels for a count the original does
## not know).
static func x_step(shifts: int) -> int:
	if not SHIFT_COUNTS.has(shifts):
		return 1
	return PIXELS_PER_BYTE / shifts


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
	if info == null:
		info = GalaxySpriteInfo.new()
	item.motion.move_to(Vector2(position + info.origin) / UNITS_PER_PIXEL)
	item.pixel = pixel_of(info, position)


func remove(item: Item) -> void:
	_items.erase(item)
	item.node.queue_free()


func clear() -> void:
	for item in _items:
		item.node.queue_free()
	_items.clear()
	_shown.clear()
	_overlays.clear()
	_flashing.clear()


## After a logic frame: every awake object with a sprite is drawn where it
## is (plus its draw offset), with its priority, and its overlays with it;
## the others are not. Objects that left the world lose their items.
func show_objects(objects: Array[GalaxyObject]) -> void:
	var present: Dictionary[GalaxyObject, bool] = {}
	for object in objects:
		present[object] = true
		var shown := (
			GalaxyWorld.is_awake(object)
			and object.sprite != GalaxyObject.NO_SPRITE
			and not object.hidden
		)
		var item: Item = _shown.get(object)
		if item != null and not shown and original_order:
			remove(item)
			_shown.erase(object)
			item = null
		if item == null:
			if not shown:
				continue
			item = add(object.sprite, object.position + object.draw_offset, object.priority)
			item.node.material = _tints.get(object)
			_shown[object] = item
		_show(item, shown, object.sprite, object.position + object.draw_offset, object.priority)
		_show_flash(object, item)
		_show_overlays(object, shown)
	for object in _shown.keys():
		if not present.has(object):
			remove(_shown[object])
			_shown.erase(object)
			_show_overlays(object, false)
	for object in _tints.keys():
		if not present.has(object):
			_tints.erase(object)
	for object in _flashing.keys():
		if not present.has(object):
			_flashing.erase(object)


func items() -> Array[Item]:
	return _items


## Draws [param object] with [param material] from now on (null: plainly).
func tint(object: GalaxyObject, material: Material) -> void:
	if material == null:
		_tints.erase(object)
	else:
		_tints[object] = material
	var item: Item = _shown.get(object)
	if item != null:
		item.node.material = material


## Puts every sprite [param blend] of the way from the previous logic frame
## to the last one when [param smooth] (at its exact place, as before
## D8.1); otherwise on the last one, where the original draws it.
func place(blend: float, smooth: bool) -> void:
	for item in _items:
		item.node.position = item.motion.at(blend, true) if smooth else Vector2(item.pixel)


## [param object]'s [param item] in white while it flashes, then with its
## own material again; nothing changes for an object that never flashes.
func _show_flash(object: GalaxyObject, item: Item) -> void:
	if object.flash_white == _flashing.has(object):
		return
	if object.flash_white:
		_flashing[object] = true
		item.node.material = _white_material()
	else:
		_flashing.erase(object)
		item.node.material = _tints.get(object)


## Every pixel of the sprite that is not see-through in EGA white.
func _white_material() -> ShaderMaterial:
	if _white == null:
		var shader := Shader.new()
		shader.code = WHITE_SHADER
		_white = ShaderMaterial.new()
		_white.shader = shader
	return _white


func _show(item: Item, shown: bool, sprite: int, position: Vector2i, priority: int) -> void:
	if item.priority != priority:
		item.priority = priority
		item.node.z_index = z_of(priority)
		if original_order:
			move_child(item.node, 0)
	item.node.visible = shown
	if shown:
		move(item, sprite, position)


## The overlays of [param object] as items: one per overlay, removed when
## it has fewer (or none, or [param shown] is false).
func _show_overlays(object: GalaxyObject, shown: bool) -> void:
	var items: Array = _overlays.get(object, [])
	var wanted := object.overlays.size() if shown else 0
	while items.size() > wanted:
		remove(items.pop_back())
	for index in wanted:
		var overlay := object.overlays[index]
		var at := object.position + overlay.offset
		if index == items.size():
			items.append(add(overlay.sprite, at, overlay.priority))
		var visible := overlay.sprite != GalaxyObject.NO_SPRITE
		_show(items[index], visible, overlay.sprite, at, overlay.priority)
	if items.is_empty():
		_overlays.erase(object)
	else:
		_overlays[object] = items


func _info(sprite: int) -> GalaxySpriteInfo:
	if _graphics == null or sprite < 0 or sprite >= _graphics.sprite_infos.size():
		return null
	return _graphics.sprite_infos[sprite]


func _texture(sprite: int) -> Texture2D:
	if _graphics == null or sprite < 0:
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
