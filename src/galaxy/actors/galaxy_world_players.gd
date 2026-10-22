class_name GalaxyWorldPlayers
extends RefCounted
## The objects of a Galaxy level, its players and their views: what
## [GalaxyWorld] (which runs them) builds on. Alone the player is the
## first object and the view is [member camera], as in the original. Two
## players (ours, milestone D12): the second Keen is [member partner], with
## a view of his own ([member partner_camera]); an object is on the screen
## when it is in either view, and the creatures go after the nearest Keen
## ([method nearest_player]).

## The original's view, in tiles (320 × 208 pixels).
const VIEW_TILES := GalaxyCamera.VIEW_TILES

## Where the view is (for waking up, and for what is on the screen).
var camera: GalaxyCamera
## The second player's Keen and his own view, when two play; null alone.
var partner: GalaxyObject
var partner_camera: GalaxyCamera
var objects: Array[GalaxyObject] = []


## The player: the first object.
func player() -> GalaxyObject:
	return objects[0] if not objects.is_empty() else null


## Every player's Keen: the first object, and the [member partner].
func players() -> Array[GalaxyObject]:
	var found: Array[GalaxyObject] = []
	if player() != null:
		found.append(player())
	if partner != null and not partner.removed:
		found.append(partner)
	return found


## Whether [param object] is a player's Keen.
func is_player(object: GalaxyObject) -> bool:
	return object != null and (object == player() or object == partner)


## The Keen nearest to [param at] (units) that is not dying; alone always
## the first object, as in the original.
func nearest_player(at: Vector2i) -> GalaxyObject:
	var nearest := player()
	if partner == null or partner.removed:
		return nearest
	var best := -1
	for keen in players():
		if keen.has_method(&"is_dying") and keen.call(&"is_dying"):
			continue
		var distance := (keen.position - at).length_squared()
		if best < 0 or distance < best:
			best = distance
			nearest = keen
	return nearest


## Whether [param object]'s box lies (partly) in the view (Omni
## CK_ObjectVisible); with two players in either.
func on_screen(object: GalaxyObject) -> bool:
	if _in_view(object, _view_tiles(camera)):
		return true
	return partner_camera != null and _in_view(object, _view_tiles(partner_camera))


## Player [param keen]'s own view (the second player's when he is the
## [member partner]); null without a view (tests).
func view_of(keen: GalaxyObject) -> GalaxyCamera:
	return partner_camera if keen == partner and partner_camera != null else camera


## Whether player [param keen] is in his own view (his death ends when he
## left it).
func on_own_screen(keen: GalaxyObject) -> bool:
	var view := view_of(keen)
	return _in_view(keen, _view_tiles(view))


static func _in_view(object: GalaxyObject, view: Rect2i) -> bool:
	var box := object.box
	return not (
		box.tile_right < view.position.x
		or box.tile_bottom < view.position.y
		or box.tile_left > view.end.x
		or box.tile_top > view.end.y
	)


## Every player's view as tiles ([method GalaxyCamera.view_tiles]).
func view_rects() -> Array[Rect2i]:
	var views: Array[Rect2i] = [_view_tiles(camera)]
	if partner_camera != null:
		views.append(_view_tiles(partner_camera))
	return views


## The view of [param view] as tiles: its first tile and (as end) the tile
## after its last whole one, as the original counts; widened to what a
## wider view shows ([method GalaxyCamera.view_tiles]).
static func _view_tiles(view: GalaxyCamera) -> Rect2i:
	if view == null:
		return Rect2i(Vector2i.ZERO, VIEW_TILES)
	return view.view_tiles()
