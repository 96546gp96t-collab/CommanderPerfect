class_name GameScreen
extends Control
## What [LevelView] has on the screen, and how it is drawn: the World
## viewport stretched over the window with every game pixel the same size
## ([DisplaySettings]), the graphics (original, xBRZ or HD), full screen or
## a window, the camera's limits, the status line and the [Hud], short
## messages and the [GameWindow]. The keys F1-F6 and F8 change how it
## looks; F8 is the realistic look ([RealisticLook]). In
## widescreen a level with a picture of its own shows it behind it
## ([LevelBackdrop]), when the option is on; in Keen 1 and 2 also a wall
## fixed to the level ([LevelWalls], [LevelWall]).
##
## [LevelView] extends it with what happens in the game; the mode (what is
## shown) and the state that the drawing needs live here.

## What is on the screen; see [LevelView].
enum Mode { NONE, TITLE, HIGH_SCORES, MAP, LEVEL, GAME_OVER, ENDING, LOOK, REMOTE }

## The alien signs' translations are drawn over everything in the world
## but Galaxy's cover ([GalaxyViewCover]).
const ALIEN_LABELS_Z := RenderingServer.CANVAS_ITEM_Z_MAX - 1
## Seconds a message such as "Cheat: god mode on" stays on the screen.
const MESSAGE_SECONDS := 3.0
## The largest number of screen pixels per game pixel that the World
## viewport uses.
const MAX_RENDER_SCALE := 8
const EVEN_PIXELS_SHADER := preload("res://src/graphics/even_pixels.gdshader")
const GRAPHICS_TITLES := StatusLine.GRAPHICS_TITLES
const MISSING_HD_MESSAGE := "No HD graphics yet: make them with tools/make_hd_graphics.sh"
const LIGHTER_MESSAGE := "Realistic lighting: no glow, this computer is too slow for it"

var _mode := Mode.NONE
var _graphics: EgaGraphics
var _properties: TileProperties
## The pictures behind the levels, and the background color left out of the
## tiles for the one shown now (transparent when none is).
var _backdrop_pictures: BackdropPictures
var _backdrop_color := Color.TRANSPARENT
## The walls behind the levels (Keen 1 and 2; null for an episode without),
## and the holes left out of the tiles for the level shown now (null when
## there are none).
var _walls: LevelWalls
var _backdrop_holes: BackdropHoles
## The map or level on the screen, and its data.
var _level_number := 0
var _level: LevelData
var _user_settings := UserSettings.new()
## The translations of the alien signs ([method _add_alien_labels]).
var _alien_labels := AlienSignLabels.new()
var _settings := _user_settings.display
var _progress := GameProgress.new()
var _ending: EndingSequence
## Keen in a level or on the world map; null when he is not there.
var _session: LevelSession
var _map_session: MapSession
## Smoke over the crashed ship, and the cabin inside it ([ShipLevels]).
var _ship_smoke := ShipSmoke.new()
var _ship_interior := ShipInterior.new()
var _screen_note := ScreenNote.new()
## Shown below the status for [constant MESSAGE_SECONDS].
var _message := ""
var _message_time_left := 0.0
## Counts down while a window that closes by itself is open: "Keens Left",
## and online every window of the game.
var _window_time_left := 0.0
## Whether jump, pogo or fire close the open window (the map messages);
## otherwise only Enter does.
var _buttons_close_window := false
var _god_mode := false
var _sounds := SoundPlayer.new()
var _menus := MenuController.new()
var _textures: GraphicsTextures
var _graphics_loader: GraphicsLoader
## The picture of Keen's house; null when FINALE.CK1 could not be read.
var _finale_image: Image
## Whether the line with the keys is shown while playing; hidden until F1
## asks for it.
var _show_help := false
## Whether this player is in someone else's online game.
var _joined_online := false
## The realistic look of the World and World2 viewports; made the first time
## the option is on.
var _realistic_looks: Array[RealisticLook] = []

@onready var _screen: TextureRect = %Screen
@onready var _world: SubViewport = %World
@onready var _level_map: LevelMap = %LevelMap
@onready var _free_look: FreeLook = %FreeLook
@onready var _keen: Keen = %Keen
@onready var _mark: SpriteView = %Mark
@onready var _actor_layer: ActorLayer = %ActorLayer
@onready var _camera: LevelCamera = %Camera
@onready var _camera_anchor: Node2D = %CameraAnchor
@onready var _world_2: SubViewport = %World2
@onready var _second_player: TwoPlayerView = %TwoPlayers
@onready var _pictures: PictureLayer = %Pictures
@onready var _hud: Hud = %Hud
@onready var _picture: Sprite2D = %Picture
@onready var _window_light: Sprite2D = %WindowLight
@onready var _window: GameWindow = %Window
@onready var _status_label: Label = %StatusLabel
@onready var _help_label: Label = %HelpLabel
@onready var _online: OnlinePlay = %Online
@onready var _remote: RemoteGame = %Remote
@onready var _backdrop: LevelBackdrop = %Backdrop
@onready var _backdrop_2: LevelBackdrop = %Backdrop2
@onready var _camera_2: LevelCamera = %Camera2


## Puts the sprites [param blend] of the way from the previous tick to the
## last one, when motion is smooth; otherwise on the last one.
func _place_sprites(blend: float) -> void:
	var smooth := _settings.smooth_motion
	_keen.place(blend, smooth)
	_second_player.place(blend, smooth)
	_mark.place(blend, smooth)
	_actor_layer.place(blend, smooth)


## What this player sees, in level pixels.
func _own_view() -> Rect2:
	var view_size := Vector2(_settings.game_size())
	return Rect2(_camera.get_screen_center_position() - view_size / 2.0, view_size)


## F1-F6 and F8: the help line, widescreen, the shape of the pixels, full
## screen, the graphics, smooth motion and the realistic look. Returns
## whether [param event] was one of them.
func _handle_display_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("toggle_fullscreen"):
		_user_settings.fullscreen = not _is_fullscreen()
		_apply_window_mode()
	elif event.is_action_pressed("toggle_widescreen"):
		_settings.aspect = (
			DisplaySettings.Aspect.WIDESCREEN
			if _settings.aspect == DisplaySettings.Aspect.ORIGINAL
			else DisplaySettings.Aspect.ORIGINAL
		)
	elif event.is_action_pressed("toggle_pixel_aspect"):
		_settings.correct_pixel_aspect = not _settings.correct_pixel_aspect
	elif event.is_action_pressed("toggle_graphics"):
		_settings.graphics = MenuController.next_graphics(_settings.graphics, _menus.hd_available)
		_show_message(GRAPHICS_TITLES[_settings.graphics])
		_apply_graphics()
	elif event.is_action_pressed("toggle_smooth_motion"):
		_settings.smooth_motion = not _settings.smooth_motion
		_show_message("Smooth motion " + ("on" if _settings.smooth_motion else "off"))
	elif event.is_action_pressed("toggle_realistic"):
		_settings.realistic = not _settings.realistic
		_show_message("Realistic lighting " + ("on" if _settings.realistic else "off"))
	elif event.is_action_pressed("toggle_help"):
		_show_help = not _show_help
		return true
	else:
		return false
	_apply_display_settings()
	_user_settings.save()
	return true


## Switches to the graphics the settings ask for. xBRZ and HD graphics are
## made on a worker thread the first time; until they are ready the current
## graphics stay.
func _apply_graphics() -> void:
	if _textures == null:
		return
	var style := _settings.graphics
	if style == DisplaySettings.Graphics.ORIGINAL:
		_use_graphics(null)
		return
	var scaled := _graphics_loader.fetch(style)
	if scaled != null:
		_use_graphics(scaled)
	elif _graphics_loader.has_failed(style):
		_show_message(MISSING_HD_MESSAGE)
		_settings.graphics = DisplaySettings.Graphics.ORIGINAL
		_use_graphics(null)
	elif _graphics_loader.is_busy():
		_show_message("Preparing %s..." % GRAPHICS_TITLES[style])


func _use_graphics(scaled: ScaledGraphics) -> void:
	if _textures.scaled == scaled:
		return
	_textures.use_scaled(scaled)
	_level_map.use_tile_set(_level_tile_set())
	_keen.refresh()
	_second_player.refresh()
	_mark.refresh()
	_actor_layer.refresh()
	_window.queue_redraw()
	_hud.queue_redraw()
	_pictures.queue_redraw()
	if _picture.visible:
		_show_picture(true)
	_fit_screen()


## Full screen or a window, as the settings say.
func _apply_window_mode() -> void:
	if _user_settings.fullscreen == _is_fullscreen():
		return
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if _user_settings.fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)


## Whether the window fills the screen now. The player can also change that
## with the green button of the Mac window.
static func _is_fullscreen() -> bool:
	return (
		DisplayServer.window_get_mode()
		in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	)


## Shows or hides the picture of Keen's house, with the light in the
## bedroom window as the conversation asks.
func _show_picture(shown: bool) -> void:
	_picture.visible = shown
	if not shown:
		return
	_picture.texture = _textures.finale(_finale_image)
	_picture.position.x = floorf((_settings.game_size().x - FinaleImage.SIZE.x) / 2.0)
	var bitmap := _ending.window_bitmap()
	_window_light.visible = not bitmap.is_empty()
	if not bitmap.is_empty():
		_window_light.texture = _textures.bitmap(bitmap)
		_window_light.position = EndingSequence.WINDOW_POSITION


func _apply_display_settings() -> void:
	_online.set_view_size(_settings.game_size())
	_window.view_size = _settings.game_size()
	_hud.view_size = _settings.game_size()
	_screen_note.view_size = _settings.game_size()
	_hud.queue_redraw()
	_window.queue_redraw()
	_fit_screen()
	if _level != null:
		_frame_camera()
	if _picture != null and _picture.visible:
		_show_picture(true)
	_apply_backdrop()


## Shows the picture behind the level on the screen, when it has one and
## the settings want it, and leaves the level's own background out of its
## tiles; otherwise the level looks as in the original.
func _apply_backdrop() -> void:
	if _walls != null:
		_apply_walls()
		return
	var picture: Texture2D = null
	var color := Color.TRANSPARENT
	var picture_level := ShipLevels.picture_level(_level_number)
	if (
		_backdrop_pictures != null
		and _level != null
		and _settings.shows_backgrounds()
		and GameFiles.is_playable_level(picture_level)
	):
		picture = _backdrop_pictures.picture(picture_level)
	if picture != null:
		var tile := BackdropPictures.background_tile(_level, _properties, _graphics.tiles)
		if tile >= 0:
			color = BackdropPictures.color_of(_graphics.tiles[tile])
		else:
			picture = null
	if _level_number == ShipLevels.INSIDE_LEVEL and _graphics != null:
		# The cabin is drawn behind the tiles: their background goes.
		color = BackdropPictures.color_of(_graphics.tiles[ShipLevels.BACKGROUND_TILE])
	var area := Rect2(LevelMap.playable_pixels(_level)) if _level != null else Rect2()
	_backdrop.show_picture(picture, area)
	_backdrop_2.show_picture(picture, area)
	_update_backdrops()
	if color != _backdrop_color:
		_backdrop_color = color
		if _textures != null:
			_level_map.use_tile_set(_level_tile_set())


## [method _apply_backdrop] for an episode with walls ([member _walls]):
## the sky's picture where the level has sky, the wall's texture behind it
## where it has a wall, and the tiles with holes for both.
func _apply_walls() -> void:
	var number := ShipLevels.picture_level(_level_number)
	var shown := (
		_level != null and _settings.shows_backgrounds() and GameFiles.is_playable_level(number)
	)
	var picture := _backdrop_pictures.picture(number) if shown and _backdrop_pictures else null
	var wall := _walls.texture(number) if shown else null
	var sky := Color.TRANSPARENT
	if picture != null:
		var tile := BackdropPictures.background_tile(_level, _properties, _graphics.tiles)
		sky = BackdropPictures.color_of(_graphics.tiles[tile]) if tile >= 0 else sky
		picture = picture if tile >= 0 else null
	var holes := _walls.holes(_level, sky, wall != null) if _level != null else null
	if _level_number == ShipLevels.OUTSIDE_LEVEL and _walls is Keen1Walls:
		ShipLevels.open_sky_under_ship(holes, _graphics.tiles)
	if _level_number == ShipLevels.INSIDE_LEVEL and _graphics != null:
		# The cabin is drawn behind the tiles: their background goes.
		holes = BackdropHoles.create(
			BackdropPictures.color_of(_graphics.tiles[ShipLevels.BACKGROUND_TILE])
		)
	var area := Rect2(LevelMap.playable_pixels(_level)) if _level != null else Rect2()
	_backdrop.show_picture(picture, area)
	_backdrop_2.show_picture(picture, area)
	_update_backdrops()
	var changed := (
		(holes.key() if holes else "") != (_backdrop_holes.key() if _backdrop_holes else "")
	)
	_backdrop_holes = holes
	if changed and _textures != null:
		_level_map.use_tile_set(_level_tile_set())
	var masks: TileSet = null
	if wall != null and holes != null and holes.has_wall() and _textures != null:
		masks = LevelTileSet.build_wall_masks(_textures, holes)
	var kept: Dictionary[Vector2i, bool] = {}
	if holes != null and picture != null:
		kept = _walls.sky_kept_cells(_level, holes)
	_level_map.use_wall(masks, wall, kept)


## Puts the pictures behind the level where the cameras look.
func _update_backdrops() -> void:
	if not _backdrop.is_showing():
		return
	var view_size := Vector2(_settings.game_size())
	_backdrop.follow(_camera.get_screen_center_position(), view_size)
	_backdrop_2.follow(_camera_2.get_screen_center_position(), view_size)


## The tiles of the level, without its background when a picture is behind
## it (or with the holes for the sky and the wall, in an episode with walls).
func _level_tile_set() -> TileSet:
	if _backdrop_holes != null:
		return LevelTileSet.build_with_holes(_graphics, _textures, _backdrop_holes)
	return LevelTileSet.build(_graphics, _textures, _backdrop_color)


func _frame_camera() -> void:
	var view_size := _settings.game_size()
	var area := LevelMap.playable_pixels(_level)
	_camera.frame(area, view_size)
	_second_player.frame(area, view_size)
	_free_look.bounds = LevelCamera.center_range(LevelCamera.limits_for(area, view_size), view_size)
	_free_look.move_to(_free_look.position)


func _fit_screen() -> void:
	var rect := _settings.fit_rect(size)
	_screen.position = rect.position
	_screen.size = rect.size
	var game_size := _settings.game_size()
	var render_scale := 1
	if not _settings.is_original_picture():
		render_scale = clampi(ceili(rect.size.y / game_size.y), 2, MAX_RENDER_SCALE)
	var smooth_textures := _textures != null and _textures.scaled != null
	for viewport: SubViewport in [_world, _world_2]:
		DisplaySettings.set_up_viewport(viewport, game_size, render_scale, smooth_textures)
	_apply_realistic(render_scale)


## Shows or hides the realistic look in both viewports, as the settings say.
func _apply_realistic(render_scale: int) -> void:
	if not _settings.realistic:
		for look in _realistic_looks:
			look.hide_look()
		return
	if _realistic_looks.is_empty():
		_realistic_looks = [
			RealisticLook.add_to(_world, _world.get_node_or_null(^"Ui")),
			RealisticLook.add_to(_world_2),
		]
		_realistic_looks[0].made_lighter.connect(_show_message.bind(LIGHTER_MESSAGE))
		_realistic_looks[0].lights_source = _realistic_lights.bind(_camera)
		_realistic_looks[1].lights_source = _realistic_lights.bind(_camera_2)
	var grade := _realistic_grade()
	for look in _realistic_looks:
		look.show_look(grade, _settings.game_size(), render_scale)


## The colours of the realistic look in this game; each game has its own.
func _realistic_grade() -> RealisticGrade:
	return RealisticGrade.neutral()


## The lights near what [param camera] shows: the game's lit tiles
## ([method _realistic_light_tiles]) and the shots in a level. Null when no
## level or map is shown.
func _realistic_lights(camera: Camera2D) -> RealisticLights:
	if _level == null or _mode in [Mode.NONE, Mode.TITLE, Mode.HIGH_SCORES]:
		return null
	var lights := RealisticLights.create(_realistic_view(camera))
	lights.add_tiles(_level, _realistic_light_tiles())
	if _mode == Mode.LEVEL and _session != null:
		lights.add_shots(_session.actors)
	return lights


## What [param camera] shows, in level pixels.
func _realistic_view(camera: Camera2D) -> Rect2:
	var view_size := Vector2(_settings.game_size())
	return Rect2(camera.get_screen_center_position() - view_size / 2.0, view_size)


## The tiles of this game that give light, by tile number; none by default.
func _realistic_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return {}


func _show_message(text: String) -> void:
	_message = text
	_message_time_left = MESSAGE_SECONDS


func _show_error(message: String) -> void:
	_status_label.text = message
	_help_label.visible = false
	push_error(message)


func _on_settings_changed() -> void:
	_sounds.set_enabled(_user_settings.sound_enabled)
	_online.sound_enabled = _user_settings.sound_enabled
	_apply_window_mode()
	_apply_graphics()
	_apply_display_settings()


func _close_window() -> void:
	# Online the game goes on behind a menu, which has the window then.
	if _menus.is_open():
		return
	_window.close()
	_window_time_left = 0.0
	_buttons_close_window = false


func _count_down_window(delta: float) -> void:
	if _window_time_left <= 0.0:
		return
	_window_time_left -= delta
	if _window_time_left <= 0.0:
		_close_window()


func _update_status() -> void:
	var playing := _mode in [Mode.MAP, Mode.LEVEL, Mode.LOOK, Mode.REMOTE]
	_help_label.visible = _show_help and playing and not _menus.is_open()
	_update_hud()
	if _level == null:
		return
	# A menu has the screen to itself.
	if _menus.is_open():
		_status_label.text = ""
		return
	# The line with the level, the picture and the inventory is a help for
	# testing: only with the help (F1), and not next to the HUD. Otherwise
	# only messages are shown, in the middle, as the original has no such line.
	var info_line := _show_help and not _hud.visible and (playing or _mode == Mode.ENDING)
	_status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if info_line else HORIZONTAL_ALIGNMENT_CENTER
	)
	if not info_line:
		var notes := PackedStringArray()
		if playing and _god_mode:
			notes.append("GOD MODE")
		if _joined_online and _mode in [Mode.TITLE, Mode.HIGH_SCORES]:
			notes.append("Waiting for %s to start a game" % _online.partner_name())
		if _message_time_left > 0.0:
			notes.append(_message)
		_status_label.text = "\n".join(notes)
		return
	var title := "Ending" if _mode == Mode.ENDING else ShipLevels.title(_level_number)
	var lines := PackedStringArray([StatusLine.picture_text(title, _settings)])
	if _mode in [Mode.MAP, Mode.LEVEL]:
		var inventory := StatusLine.inventory_text(_progress.inventory)
		lines.append(inventory + ("   GOD MODE" if _god_mode else ""))
	if _message_time_left > 0.0:
		lines.append(_message)
	_status_label.text = "\n".join(lines)


## The HUD is for widescreen, while Keen is on the map or in a level.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]
		and not _menus.is_open()
	)
	if _hud.visible:
		var with_parts := _mode == Mode.MAP or ShipLevels.is_ship_level(_level_number)
		_hud.show_inventory(_progress.inventory, with_parts)


## Makes the camera follow [param target]: Keen (or his ship), the
## free-look point, or (for a screen that stands still) its own anchor. The
## others are switched off.
func _follow(target: Node2D) -> void:
	var following_keen := target == _keen
	_keen.visible = following_keen
	_second_player.set_keen_visible(following_keen)
	_mark.visible = following_keen
	_free_look.set_process(target == _free_look)
	_camera.use_dead_zone(following_keen)
	_keen.snap()
	_mark.snap()
	_move_camera_anchor()
	_camera.reset_smoothing()


## Puts the camera anchor on what the view follows. The camera itself never
## changes parent: while it is out of the tree, the view would jump to the
## top left of the level for a frame.
func _move_camera_anchor() -> void:
	match _mode:
		Mode.LOOK:
			_camera_anchor.position = _free_look.position
		Mode.LEVEL:
			# When Keen dies the camera stays put, so that he flies off the screen.
			# With two Keens the split screen moves the cameras.
			if not _session.keen.is_dead and not _second_player.is_split_screen():
				_camera_anchor.position = _keen.smooth_position() + KeenPhysics.SPRITE_SIZE / 2.0
		Mode.MAP:
			_camera_anchor.position = _map_keen_center()
		Mode.REMOTE:
			_camera_anchor.position = _remote.camera_target(_camera_anchor.position)
		Mode.ENDING:
			var flight := _ending.flight
			if _ending.map_number() == GameFiles.ENDING_LEVEL and flight.scrolling:
				_camera_anchor.position = _keen.smooth_position()
			elif _ending.map_number() == GameFiles.WORLD_MAP_LEVEL and _map_session != null:
				_camera_anchor.position = _map_keen_center()


## The middle of Keen on the world map, where he is drawn now.
func _map_keen_center() -> Vector2:
	var map_keen := _map_session.keen
	return _keen.smooth_position() + map_keen.center() - map_keen.position


## Puts the drawings of the ship into the world: the cabin behind the
## tiles, the smoke over them and under the sprites; and the translations
## of the alien signs over everything ([method _add_alien_labels]).
func _add_ship_drawings() -> void:
	_add_alien_labels()
	_world.add_child(_ship_interior)
	_world.move_child(_ship_interior, _level_map.get_index())
	_world.add_child(_ship_smoke)
	_world.move_child(_ship_smoke, _actor_layer.get_index())
	# With the HUD, so that the camera does not move it.
	_hud.get_parent().add_child(_screen_note)


## The translations of the alien signs, over everything in the world
## (under Galaxy's cover of what lies past the edge of the level).
func _add_alien_labels() -> void:
	_alien_labels.z_index = ALIEN_LABELS_Z
	_world.add_child(_alien_labels)
	_alien_labels.is_on = func() -> bool: return _user_settings.alien_text
	_alien_labels.level = _alien_level
	_alien_labels.find_signs = _alien_signs
	_alien_labels.readers = _alien_readers
	_alien_labels.make_plate = _alien_plate


## The level or world map shown now, whose alien signs can be read; null
## when none is.
func _alien_level() -> Object:
	if _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]:
		return _level
	return null


## The alien signs of the level shown now, by the game's table
## ([method _alien_sign_table]).
func _alien_signs() -> Array[AlienSigns.Sign]:
	var table := _alien_sign_table()
	if _level == null or table == null:
		return []
	var level := _level
	return AlienSigns.find(
		Vector2i(level.width, level.height), level.tile_at, table.groups, table.letters
	)


## This game's alien signs ([AlienSignTables]): Keen 1's, the game this
## screen was first made for; the others give their own.
func _alien_sign_table() -> AlienSignTables.Table:
	return AlienSignTables.keen1()


## The middles of the players' Keens that are shown, in level pixels.
func _alien_readers() -> Array[Vector2]:
	var found: Array[Vector2] = []
	if _keen.visible:
		var middle := (
			_map_keen_center()
			if _mode == Mode.MAP and _map_session != null
			else _keen.smooth_position() + KeenPhysics.SPRITE_SIZE / 2.0
		)
		found.append(middle)
	if _second_player.is_keen_shown():
		found.append(_second_player.keen_center())
	return found


## A plate for the translation of an alien sign: a window of the game.
func _alien_plate(lines: PackedStringArray) -> Image:
	if _graphics == null:
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	return AlienSignPlates.keen(_graphics.font_chars, lines)


## Shows the drawings of the ship level that is shown now; nothing for
## another level.
func _show_ship_drawings() -> void:
	_ship_smoke.start(ShipLevels.smoke_sources(_level_number))
	_screen_note.clear()
	_ship_interior.show_level(_level if _level_number == ShipLevels.INSIDE_LEVEL else null)
