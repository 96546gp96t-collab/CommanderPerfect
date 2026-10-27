class_name GalaxyPlayScreen
extends GalaxyLevelScreen
## A map of a Galaxy episode being played on the shared [GameScreen] (made
## from Keen 4's [Keen4PlayScreen]; the episode's view adds what comes
## next): a level ([GalaxyLevelSession]) on the original's clock
## ([GalaxyClock], 35 logic frames a second), the view following Keen by
## the original's rules ([GalaxyCamera]), the score box ([GalaxyScoreBox])
## as the HUD, and over the game the queue of boxes and fades
## ([GalaxyScreenQueue]): message boxes that wait for a key; the game
## stands still while it runs. Every box is drawn with the original pixels
## in the middle of the picture (also in widescreen), over everything.
## The world map is played the same way ([GalaxyMapSession], milestone
## E6). A map without a Keen to play is only shown, the keys looking
## around.
##
## The sounds and the music are [GalaxyAudio]'s (milestone E8): every map
## plays its song from its start (Omni CK_PlayLoop's StartMusic), the
## objects play their sounds through their world.
##
## The hooks [method _new_session], [method _new_inventory] and
## [method _hold_frame] are where an episode plugs in; [GalaxyFlowScreen]
## adds the flow of a game between the maps (docs/keen5/architecture.md,
## "The Galaxy game").

## A demo chunk begins with its map's number, 16 bits.
const DEMO_MAP_BYTES := 2

var _clock := GalaxyClock.new()
var _start: GalaxyStart
var _keen_item: GalaxyObjectLayer.Item
## The map shown now (its number, also when it could not be read).
var _map_number := 0
## Where the free-look point was when the view was last placed.
var _looked_at := Vector2.INF
## What Keen carries from level to level.
var _inventory: GalaxyInventory
## The level being played; null where none is.
var _played: GalaxyLevelSession
## The world map being played; null where it is not.
var _on_map: GalaxyMapSession
## The view's top left, in pixels, frame by frame (smooth motion).
var _view_motion := Interpolation.new()
## How far between the last two logic frames the sprites and the view are
## drawn (smooth motion): the clock's blend while the game steps; while the
## clock's frames pass without it (a box) it stays where it was, so nothing
## moves (Keen 4, D13.2).
var _drawn_blend := 1.0
## Whether the clock's last frame ran the game.
var _game_stepped := true
var _difficulty := GalaxyDifficulty.DEFAULT
var _queue := GalaxyScreenQueue.new()
var _window_sprite := Sprite2D.new()
## Whether the next logic frame draws every sprite anew: the original
## draws nothing before a map's first frame, so the sprites of one priority
## take their order from that frame (seen in Keen 5's high-score demo, E7).
var _fresh_sprites := false
var _audio := GalaxyAudio.new()
## The episode's own settings (the quiet AdLib sounds, the score box).
var _galaxy_settings: GalaxySettings

@onready var _score_box: GalaxyScoreBox = %ScoreBox


## After the files are read: the inventory of a new game, the score box,
## the sprite that shows the boxes, the sounds (rendered in the background
## into the episode's cache, [method _first_song_maps] first).
func _set_up_play() -> void:
	add_child(_audio)
	_galaxy_settings = GalaxySettings.load_from(rules.settings_path())
	_audio.quiet_adlib = _galaxy_settings.quiet_adlib
	_audio.load_sounds(_data, rules, _user_settings, _first_song_maps())
	_map_number = rules.first_level
	_inventory = _new_inventory()
	_score_box.use_graphics(_data.graphics, rules.sprites.get(&"SCOREBOX", -1))
	_window_sprite.centered = false
	# The boxes keep the original pixels, also with xBRZ (Keen 4, D11).
	_window_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_window_sprite.visible = false
	_score_box.get_parent().add_child(_window_sprite)
	_objects.original_order = rules.original_sprite_order


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _scaled != null and _scaled.poll():
		_apply_graphics()
	var frames := _clock.advance(delta) if _data != null else 0
	for frame in frames:
		var tics := _clock.run_frame()
		_game_stepped = false
		if _hold_frame(tics):
			continue
		if not _queue.is_empty():
			_waiting(tics)
			if _queue.advance(tics):
				_show_step()
		elif _run_frame(tics):
			break
	if _mode == Mode.LOOK:
		_follow_free_look()
	_objects.place(_blend_to_draw(), _settings.smooth_motion)
	_place_overlays()
	_place_smooth_view()
	_update_backdrops()
	_update_status()


## The map that is shown now.
func map_number() -> int:
	return _map_number


## Where Keen starts in the map shown now.
func start() -> GalaxyStart:
	return _start


## The camera rules of the map shown now.
func galaxy_camera() -> GalaxyCamera:
	return _galaxy_camera


## The level being played, or null.
func session() -> GalaxyLevelSession:
	return _played


## The world map being played, or null.
func map_session() -> GalaxyMapSession:
	return _on_map


func inventory() -> GalaxyInventory:
	return _inventory


## The sounds and the music.
func audio() -> GalaxyAudio:
	return _audio


## The maps whose songs are rendered first (each takes several seconds the
## first time): the world map's (a new game), the first demo's map's (the
## first song of the title loop) and the story's.
func _first_song_maps() -> PackedInt32Array:
	var maps := PackedInt32Array([rules.world_map])
	var first_demo := _data.graphics.demo(0)
	if first_demo.size() >= DEMO_MAP_BYTES:
		maps.append(first_demo.decode_u16(0))
	maps.append(rules.story_song)
	return maps


## Whether a box or a fade is on the screen (the game waits).
func shows_message() -> bool:
	return not _queue.is_empty()


## The steps still to show.
func queue() -> GalaxyScreenQueue:
	return _queue


## The inventory of a new game, with the episode's numbers; an episode
## with more to carry gives its own (Keen 5's [Keen5Inventory]).
func _new_inventory() -> GalaxyInventory:
	var carried := GalaxyInventory.new()
	carried.lives = rules.start_lives
	carried.shots = rules.start_shots
	carried.next_life_at = rules.first_extra_life
	carried.charges_per_stunner = rules.stunner_charges
	return carried


## The level of map [param map] (number [param number]) with Keen carrying
## [member _inventory], or null when Keen does not stand in it; an episode
## gives its own session class (Keen 5's [Keen5LevelSession]).
func _new_session(map: GalaxyMap, number: int, random_start: int) -> GalaxyLevelSession:
	return GalaxyLevelSession.start_level(
		_data, rules, map, _inventory, random_start, _difficulty, number
	)


## Plays sound [param sound_name] by the episode's numbers; with
## [param interrupt] whatever plays is stopped first.
func _play_sound(sound_name: StringName, interrupt := false) -> void:
	_audio.play(sound_name, interrupt)


## A sound the world played asks for (its objects, Keen): played as
## [method _play_sound] (online it always goes to the joiner).
func _play_world_sound(sound_name: StringName, interrupt := false) -> void:
	_play_sound(sound_name, interrupt)


## A frame of [param _tics] tics that something over the game takes (the
## status window); returns whether it did, so the game and the boxes wait
## (none by default).
func _hold_frame(_tics: int) -> bool:
	return false


## Starts the song of map [param map] from its beginning (Omni
## StartMusic); a map without one stops the music.
func _play_map_song(map: int) -> void:
	_audio.play_map_song(map)


## Stops the music (Omni StopMusic: a map's play ends, a screen without a
## song).
func _stop_music() -> void:
	_audio.stop_music()


## The play of a map ended (a level done, a death, a map only looked at, a
## demo over): the music stops, unless the episode plays it on through the
## boxes between the maps (Keen 4, [member GalaxyGameRules.music_stops_between_maps]).
func _stop_music_between_maps() -> void:
	if rules.music_stops_between_maps:
		_stop_music()


## Where between the last two logic frames to draw now: the clock's blend
## while the game steps, otherwise the last one drawn.
func _blend_to_draw() -> float:
	if _game_stepped:
		_drawn_blend = _clock.blend()
	return _drawn_blend


## One logic frame of what is played; returns whether it ended (or a box
## stopped it).
func _run_frame(tics: int) -> bool:
	if _played != null:
		_played.run_frame(_frame_input(tics), tics, _clock.tic, _partner_input())
	elif _on_map != null:
		_on_map.run_frame(_frame_input(tics), tics, _clock.tic)
	else:
		return false
	_game_stepped = true
	_galaxy_map.animate(tics)
	if _fresh_sprites:
		_fresh_sprites = false
		_objects.clear()
	_objects.show_objects(_played_world().objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_update_score_box()
	return _after_frame()


## What Keen is steered by in a frame of [param _tics] tics: the keys.
func _frame_input(_tics: int) -> KeenInput:
	return KeenInput.from_actions()


## What player 2 holds in a level, when he plays; null alone.
func _partner_input() -> KeenInput:
	return null


## What follows a frame (the episode's view); returns whether the frames
## stop.
func _after_frame() -> bool:
	return not _queue.is_empty()


## Called every frame while the queue waits.
func _waiting(_tics: int) -> void:
	pass


## The map shown now, whose alien signs can be read; null when none is.
func _alien_level() -> Object:
	var world := _played_world()
	return world.map if world != null and _mode in [Mode.LEVEL, Mode.MAP] else null


## The alien signs of the map shown now, in both its layers
## ([method _alien_sign_tables]).
func _alien_signs() -> Array[AlienSigns.Sign]:
	var world := _played_world()
	var found: Array[AlienSigns.Sign] = []
	if world == null:
		return found
	var map := world.map
	var tables := _alien_sign_tables()
	for layer in [GalaxyMap.Layer.BACKGROUND, GalaxyMap.Layer.FOREGROUND]:
		if layer >= tables.size():
			continue
		found.append_array(
			AlienSigns.find(
				Vector2i(map.width, map.height),
				func(cell: Vector2i) -> int: return map.tile(layer, cell.x, cell.y),
				tables[layer].groups,
				tables[layer].letters
			)
		)
	return found


## This episode's alien signs: the background's table, then the
## foreground's ([AlienSignTables]); none by default.
func _alien_sign_tables() -> Array[AlienSignTables.Table]:
	return []


## The middles of the players' Keens, in level pixels.
func _alien_readers() -> Array[Vector2]:
	var found: Array[Vector2] = []
	var world := _played_world()
	if world == null:
		return found
	for keen in world.players():
		var box := keen.box
		var middle := Vector2((box.left + box.right) / 2.0, (box.top + box.bottom) / 2.0)
		found.append(middle / GalaxyUnits.PER_PIXEL)
	return found


## A plate for the translation of an alien sign, in the window font.
func _alien_plate(lines: PackedStringArray) -> Image:
	return AlienSignPlates.galaxy(_data.graphics.font(rules.menu_font), lines)


## The world being played.
func _played_world() -> GalaxyWorld:
	if _played != null:
		return _played.world
	return _on_map.world if _on_map != null else null


## Plays [param session] in [param map].
func _play(session: GalaxyLevelSession, map: GalaxyMap) -> void:
	_played = session
	_on_map = null
	_played.player.god_mode = _god_mode
	_start_playing(map, _played.camera, _played.world)


## Plays the world map [param session].
func _play_map(session: GalaxyMapSession) -> void:
	_on_map = session
	_played = null
	_start_playing(session.map, session.camera, session.world)


func _start_playing(map: GalaxyMap, camera: GalaxyCamera, world: GalaxyWorld) -> void:
	_mode = Mode.LEVEL
	_clock.start_level()
	_galaxy_camera = camera
	_apply_wide_view()
	_show_map(map, rules.level_sprites())
	world.tile_writer = func(cell: Vector2i, tile: int) -> void:
		_place_tile(GalaxyMap.Layer.FOREGROUND, cell, tile)
	world.back_tile_writer = func(cell: Vector2i, tile: int) -> void:
		_place_tile(GalaxyMap.Layer.BACKGROUND, cell, tile)
	world.sound_player = _play_world_sound
	_play_map_song(_map_number)
	_objects.show_objects(world.objects)
	_fresh_sprites = rules.original_sprite_order
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_view_motion.snap()
	_score_box.visible = true
	_free_look.set_process(false)
	_update_score_box()


## Objects wake up and fall asleep around what the view shows: in
## widescreen around the wider view, the original's margins around it, so
## nothing on the screen sleeps (ours, Keen 4's D13.2). In 4:3 everything
## is as the original's.
func _apply_wide_view() -> void:
	if _on_map != null:
		_on_map.camera.wide_width = _wide_view_width()
	if _played == null:
		return
	var width := _wide_view_width()
	var changed := _played.camera.wide_width != width
	_played.set_wide_width(width)
	if _played.camera_2 != null:
		_played.camera_2.wide_width = _partner_view_width(width)
	if changed:
		_wide_view_changed(width)


## How wide the view is drawn when wider than the original's; 0 otherwise.
func _wide_view_width() -> int:
	var width := _settings.game_size().x
	return width if width > GalaxyCamera.VIEW_PIXELS.x else 0


## The width player 2's view counts with, when the view is [param width]
## wide.
func _partner_view_width(width: int) -> int:
	return width


## The view's width changed in a level.
func _wide_view_changed(_width: int) -> void:
	pass


func _apply_display_settings() -> void:
	super()
	_apply_wide_view()


## The lights of the realistic look near [param camera]'s view: the
## game's lit tiles in both layers ([method _realistic_light_tiles] for the
## foreground, [method _realistic_back_light_tiles] for the background) and
## the shots of Keen's stunner (brighter where one hit) and of the
## creatures.
func _realistic_lights(camera: Camera2D) -> RealisticLights:
	var world := _played_world()
	if world == null or _mode not in [Mode.LEVEL, Mode.MAP]:
		return null
	var lights := RealisticLights.create(_realistic_view(camera))
	var map := world.map
	var size := Vector2i(map.width, map.height)
	lights.add_tile_grid(
		size,
		func(cell: Vector2i) -> int: return map.tile(GalaxyMap.Layer.BACKGROUND, cell.x, cell.y),
		_realistic_back_light_tiles()
	)
	lights.add_tile_grid(
		size,
		func(cell: Vector2i) -> int: return map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y),
		_realistic_light_tiles()
	)
	for object in world.objects:
		var place := Vector2(object.position) / GalaxyUnits.PER_PIXEL
		if object is GalaxyStunnerShot:
			lights.add_shot(place, (object as GalaxyStunnerShot).spent)
		elif object is GalaxyEnemyShot:
			lights.add_shot(place, false)
	return lights


## The background tiles of this game that give light; none by default.
func _realistic_back_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return {}


## A map where Keen does not play: he stands, the keys look around.
func _look_at(map: GalaxyMap) -> void:
	_played = null
	_on_map = null
	_stop_music_between_maps()
	_mode = Mode.LOOK
	_clock.reset()
	_galaxy_camera = GalaxyCamera.for_map(
		Vector2i(map.width, map.height),
		GalaxyCamera.blocks_in(map, rules.column_block_info, true),
		GalaxyCamera.blocks_in(map, rules.row_block_info, false)
	)
	var sprites := PackedInt32Array()
	if _start.kind != GalaxyStart.Kind.NONE:
		sprites.append(_start.sprite)
	_show_map(map, sprites)
	if _start.kind != GalaxyStart.Kind.NONE:
		_keen_item = _objects.add(_start.sprite, _start.position, GalaxyStart.PRIORITY)
	_centre_view()
	_score_box.visible = false
	_free_look.set_process(true)


## Shows [param screens] one by one, each until a key is pressed; then
## [param then] (when valid).
func _show_screens(screens: Array[Image], then: Callable) -> void:
	for screen in screens:
		_queue.add_box(screen)
	_after_queue(then)


## Runs [param then] once the queue is done (at once when it is empty).
func _after_queue(then: Callable) -> void:
	if _queue.is_empty():
		if then.is_valid():
			then.call()
		return
	_queue.then = then
	_show_step()


## The queue's step on the screen: its picture and brightness.
func _show_step() -> void:
	var step := _queue.current()
	var image: Image = step.image if step != null else null
	_window_sprite.visible = image != null
	if image != null:
		_window_sprite.texture = ImageTexture.create_from_image(image)
	_screen.modulate = Color(1, 1, 1) * (step.brightness if step != null else 1.0)
	_screen.modulate.a = 1.0
	_place_overlays()


## The boxes in the middle of the picture, also after F2.
func _place_overlays() -> void:
	var left := (_settings.game_size().x - GalaxyWindow.SCREEN_SIZE.x) / 2.0
	_window_sprite.position = Vector2(left, 0)


## A key or button just pressed (the original waits for a new press).
static func _is_new_press(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	var button := event as InputEventJoypadButton
	return button != null and button.pressed


func _update_score_box() -> void:
	_score_box.show_numbers(_inventory.score, _inventory.lives, _inventory.shots)


## With smooth motion the view moves between the logic frames too.
func _place_smooth_view() -> void:
	if (_played == null and _on_map == null) or not _settings.smooth_motion:
		return
	_camera_anchor.position = _view_motion.at(_drawn_blend, true)
	_camera.reset_smoothing()


## The view on Keen, as the original puts it when a level starts (Omni
## CK_CentreCamera); the free-look point goes where he is.
func _centre_view() -> void:
	var x := _start.position.x
	var feet := _start.position.y
	if _keen_item != null:
		var info := _data.graphics.sprite_infos[_start.sprite]
		feet += info.box_bottom
	_galaxy_camera.centre_on(x, feet, _start.is_world_map(), _start.position.y)
	_free_look.bounds = _look_bounds()
	_free_look.move_to(_view_centre())
	_looked_at = _free_look.position
	_frame_view()


## Places the view on the free-look point once it has moved.
func _follow_free_look() -> void:
	if _galaxy_camera == null or _free_look.position == _looked_at:
		return
	_looked_at = _free_look.position
	var half := Vector2(GalaxyCamera.VIEW_PIXELS) / 2.0
	var top_left := ((_looked_at - half) * GalaxyCamera.UNITS_PER_PIXEL).floor()
	_galaxy_camera.reposition(Vector2i(top_left))
	_frame_view()


## The middle of the original's view now, in pixels.
func _view_centre() -> Vector2:
	return Vector2(_galaxy_camera.view_pixels()) + Vector2(GalaxyCamera.VIEW_PIXELS) / 2.0


## Where the free-look point may go: the middle of every view inside the
## map's border.
func _look_bounds() -> Rect2:
	var border := GalaxyCamera.BORDER_TILES * GalaxyCamera.TILE_PIXELS
	var size := Vector2(_map.width, _map.height) * GalaxyCamera.TILE_PIXELS
	var view := Vector2(GalaxyCamera.VIEW_TILES * GalaxyCamera.TILE_PIXELS)
	var half := Vector2(GalaxyCamera.VIEW_PIXELS) / 2.0
	return Rect2(Vector2(border, border) + half, size - 2.0 * Vector2(border, border) - view)


## Messages in the middle; with the help (F1) the map's name and the
## graphics above them.
func _update_status() -> void:
	_help_label.visible = _show_help
	if _data == null:
		return
	var lines := PackedStringArray()
	if _show_help:
		lines.append(StatusLine.picture_text(_map_title(), _settings))
	if _message_time_left > 0.0:
		lines.append(_message)
	_status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if _show_help else HORIZONTAL_ALIGNMENT_CENTER
	)
	_status_label.text = "\n".join(lines)


func _map_title() -> String:
	var names := _data.executable.level_names()
	if _map_number >= 0 and _map_number < names.size():
		return "Map %d: %s" % [_map_number, GalaxyExeTexts.one_line(names[_map_number])]
	return "Map %d" % _map_number
