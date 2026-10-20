class_name GalaxyWorld
extends RefCounted
## The objects of a Galaxy level and one logic frame of them, in the
## original's order (Omni `ck_play.c:CK_PlayLoop`, facts only;
## docs/keen4/research.md §3):
##   1. every object, the player first: an asleep one near the view wakes
##      up; an awake one far from the view falls asleep (with a chance of
##      2 × tics in 256 a frame), or is removed when it only lives on the
##      screen; then its action runs ([method _run_action]): think, move,
##      tile collision;
##   2. the player rides the object he stands on (a platform, a Bounder):
##      [method GalaxyWorld.player]'s [code]_ride_platform[/code];
##   3. every pair of awake objects whose boxes overlap: **both** contact
##      functions run;
##   4. the player's own tile checks (items, deadly tiles, gem holders):
##      [method GalaxyWorld.player]'s [code]_touch_tiles[/code];
##   5. an object at the map's last row is removed (the player dies);
##   6. every object that moved or changed reacts (its [code]react[/code]).
## The camera follows afterwards ([GalaxyCamera], by the level session).
## The player is the first object; the original keeps at most 100.

enum LevelState { PLAYING, DIED, COMPLETED }

## Objects wake up within this many tiles of the view (Omni).
const WAKE_MARGIN := 1
## Awake objects fall asleep beyond this many tiles (Omni
## DEFAULT_ACTIVE_LIMIT).
const SLEEP_MARGIN := 4
## The chance to fall asleep is (2 × tics) in this.
const RANDOM_RANGE := 256
const SLEEP_CHANCE_PER_TIC := 2
const RANDOM_MASK := 0xFF
## The original's view, in tiles (320 × 208 pixels).
const VIEW_TILES := GalaxyCamera.VIEW_TILES

var map: GalaxyMap
var tile_info: GalaxyTileInfo
var sprite_infos: Array[GalaxySpriteInfo] = []
var clip: GalaxyClip
## Where the view is (for waking up, and for what is on the screen).
var camera: GalaxyCamera
var objects: Array[GalaxyObject] = []
## The tics of the frame being run, and the absolute tic it ends on (it
## covers [code]tic - tics[/code] … [code]tic - 1[/code]).
var tics := GalaxyClock.NORMAL_TICS
var tic := 0
var state := LevelState.PLAYING
## How a completed level was left, when not by walking out of it: the name
## an object gave (Keen 4: [code]&"foot"[/code], the Foot carries Keen off;
## [code]&"council"[/code], an elder rescued; [code]&"wetsuit"[/code]).
var ending := &""
## A message an object asks to show after this frame (Keen 4: Lindsey's,
## the janitor's); the view shows it and clears it ([method ask]).
var conversation := &""
## Which map of the episode this is (some objects act differently in one
## level: Keen 4's janitor, the elder under water); -1 unknown.
var map_number := -1
## The fixed table of random numbers ([method random]).
var random_table := PackedByteArray()
var random_index := 0
## Called as (cell, tile) instead of writing the foreground plane, so the
## view draws the change too ([GalaxyLevelMap.set_tile]).
var tile_writer: Callable
## The first frame after a level starts puts everything far from the view
## to sleep at once (the original's screen is still faded in).
var _starting := true


static func create(
	level_map: GalaxyMap, info: GalaxyTileInfo, infos: Array[GalaxySpriteInfo]
) -> GalaxyWorld:
	var world := GalaxyWorld.new()
	world.map = level_map
	world.tile_info = info
	world.sprite_infos = infos
	world.clip = GalaxyClip.create(level_map, info)
	return world


## The player: the first object.
func player() -> GalaxyObject:
	return objects[0] if not objects.is_empty() else null


## Puts [param object] in the world (after the others); returns it.
func add(object: GalaxyObject) -> GalaxyObject:
	object.world = self
	objects.append(object)
	return object


## The level ends now, as [param how] says ([member ending]).
func complete(how: StringName) -> void:
	state = LevelState.COMPLETED
	ending = how


## Asks for message [param name] to be shown after this frame.
func ask(name: StringName) -> void:
	conversation = name


## Takes [param object] out at the end of the frame.
func remove(object: GalaxyObject) -> void:
	object.removed = true


## Runs one logic frame of [param frame_tics] tics that ends on absolute
## tic [param end_tic] (see the class description).
func run_frame(frame_tics: int, end_tic: int) -> void:
	tics = frame_tics
	tic = end_tic
	var index := 0
	while index < objects.size():
		var object := objects[index]
		index += 1
		if not object.removed and _wake_or_sleep(object):
			_run_action(object)
	_starting = false
	var keen := player()
	if keen != null and keen.has_method(&"_ride_platform"):
		keen.call(&"_ride_platform")
	_contacts()
	if keen != null and keen.has_method(&"_touch_tiles"):
		keen.call(&"_touch_tiles")
	_leave_at_bottom()
	_react()
	objects = objects.filter(func(object: GalaxyObject) -> bool: return not object.removed)


## The next number of the original's random table (Omni US_RndT).
func random() -> int:
	if random_table.is_empty():
		return randi() & RANDOM_MASK
	random_index = (random_index + 1) & RANDOM_MASK
	return random_table[random_index % random_table.size()]


## Whether [param object] is in the world and awake.
static func is_awake(object: GalaxyObject) -> bool:
	return not object.removed and object.activity != GalaxyObject.Activity.INACTIVE


## The sprite table entry of [param sprite], or null.
func sprite_info(sprite: int) -> GalaxySpriteInfo:
	if sprite < 0 or sprite >= sprite_infos.size():
		return null
	return sprite_infos[sprite]


func fore_tile(x: int, y: int) -> int:
	return map.tile(GalaxyMap.Layer.FOREGROUND, x, y)


func info_at(x: int, y: int) -> int:
	return map.tile(GalaxyMap.Layer.INFO, x, y)


## What foreground tile [param tile] is (TILEINFO misc without the in-front
## bit).
func misc_of(tile: int) -> int:
	return tile_info.misc_kind(tile)


## Puts foreground [param tile] in [param cell] (through [member
## tile_writer] when the view draws the map).
func set_fore_tile(cell: Vector2i, tile: int) -> void:
	if tile_writer.is_valid():
		tile_writer.call(cell, tile)
	else:
		map.planes[GalaxyMap.Layer.FOREGROUND][cell.y * map.width + cell.x] = tile


func set_info(cell: Vector2i, value: int) -> void:
	map.planes[GalaxyMap.Layer.INFO][cell.y * map.width + cell.x] = value


## Whether [param object]'s box lies (partly) in the view (Omni
## CK_ObjectVisible).
func on_screen(object: GalaxyObject) -> bool:
	var view := _view_tiles()
	var box := object.box
	return not (
		box.tile_right < view.position.x
		or box.tile_bottom < view.position.y
		or box.tile_left > view.end.x
		or box.tile_top > view.end.y
	)


## The view as tiles: its first tile and (as end) the tile after its
## last whole one, as the original counts.
func _view_tiles() -> Rect2i:
	var scroll := camera.scroll if camera != null else Vector2i.ZERO
	var first := Vector2i(GalaxyUnits.to_tile(scroll.x), GalaxyUnits.to_tile(scroll.y))
	return Rect2i(first, VIEW_TILES)


## Wakes [param object] up near the view, puts it to sleep far from it;
## returns whether it runs this frame.
func _wake_or_sleep(object: GalaxyObject) -> bool:
	var view := _view_tiles()
	var box := object.box
	if object.activity == GalaxyObject.Activity.INACTIVE:
		var near := (
			box.tile_right >= view.position.x - WAKE_MARGIN
			and box.tile_left <= view.end.x + WAKE_MARGIN
			and box.tile_top <= view.end.y + WAKE_MARGIN
			and box.tile_bottom >= view.position.y - WAKE_MARGIN
		)
		if not near:
			return false
		object.activity = GalaxyObject.Activity.ACTIVE
		object.needs_react = true
	var far := (
		box.tile_right < maxi(view.position.x - SLEEP_MARGIN, 0)
		or box.tile_left > view.end.x + SLEEP_MARGIN
		or box.tile_top > view.end.y + SLEEP_MARGIN
		or box.tile_bottom < maxi(view.position.y - SLEEP_MARGIN, 0)
	)
	if far:
		match object.activity:
			GalaxyObject.Activity.ON_SCREEN_ONLY:
				remove(object)
				return false
			GalaxyObject.Activity.ACTIVE:
				if _starting or random() < SLEEP_CHANCE_PER_TIC * tics:
					object.activity = GalaxyObject.Activity.INACTIVE
					return false
	return true


## Runs [param object]'s action for the frame's tics (Omni CK_RunAction):
## steps through actions while tics are left, then moves it by its step
## with the tile collision when it moved or changed its sprite.
func _run_action(object: GalaxyObject) -> void:
	var old_sprite := object.sprite
	object.moved = Vector2i.ZERO
	object.step = Vector2i.ZERO
	var running := object.action
	var left := _advance(object, tics)
	if object.action != running:
		object.action_timer = 0
		running = object.action
	while left > 0 and running != null:
		if running.protect or running.timer > left:
			left = _advance(object, left)
		else:
			# Without protection a frame never ends the action it reached
			# with leftover tics: the tics beyond are lost.
			left = _advance(object, running.timer - 1)
		if object.action != running:
			object.action_timer = 0
			running = object.action
	if running == null:
		remove(object)
		return
	object.sprite = running.sprite_facing(object.direction.x, object.sprite)
	var on_platform := object.top_hit == GalaxyObject.ON_PLATFORM
	if object.sprite != old_sprite or object.step != Vector2i.ZERO or on_platform:
		if object.clip == GalaxyObject.Clip.SIMPLE:
			clip.update_simple_box(object)
		else:
			clip.update_normal(object)


## Lets [param available] tics of [param object]'s action pass (Omni
## CK_ActionThink); returns the tics left over when the action ended.
func _advance(object: GalaxyObject, available: int) -> int:
	var action := object.action
	if action == null:
		return 0
	if action.type == GalaxyAction.Type.THINK:
		_think(object, action)
		return 0
	var elapsed := available + object.action_timer
	if action.timer == 0 or action.timer > elapsed:
		object.action_timer = elapsed
		if action.slides():
			_move(object, action, available)
		if action.thinks_every_frame():
			_think(object, action)
		return 0
	var used := action.timer - object.action_timer
	object.action_timer = 0
	if action.slides():
		_move(object, action, used)
	else:
		_move(object, action, 1)
	_think(object, action)
	if object.action == action:
		object.action = action.next
	elif object.action == null:
		return 0
	return elapsed - action.timer


## Adds [param times] × the action's velocity, in the object's directions.
static func _move(object: GalaxyObject, action: GalaxyAction, times: int) -> void:
	object.step.x += action.velocity.x * times * object.direction.x
	object.step.y += action.velocity.y * times * object.direction.y


static func _think(object: GalaxyObject, action: GalaxyAction) -> void:
	if action.think.is_empty():
		return
	if object.think_delay > 0:
		object.think_delay -= 1
	else:
		object.call(action.think)


func _contacts() -> void:
	for first in objects.size():
		var one := objects[first]
		if not is_awake(one):
			continue
		for second in range(first + 1, objects.size()):
			var other := objects[second]
			if not is_awake(other) or not one.box.overlaps(other.box):
				continue
			if one.action != null and not one.action.contact.is_empty():
				one.call(one.action.contact, other)
			if other.action != null and not other.action.contact.is_empty():
				other.call(other.action.contact, one)


## An object at the last row of the map is gone; the player dies there.
func _leave_at_bottom() -> void:
	var keen := player()
	for object in objects:
		if not is_awake(object) or object.box.tile_bottom < map.height - 1:
			continue
		if object == keen:
			state = LevelState.DIED
		else:
			remove(object)


func _react() -> void:
	for object in objects:
		if not is_awake(object) or not object.needs_react or object.action == null:
			continue
		object.needs_react = false
		if not object.action.react.is_empty():
			object.call(object.action.react)
