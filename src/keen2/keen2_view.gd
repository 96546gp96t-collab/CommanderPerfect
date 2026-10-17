class_name Keen2View
extends Keen2OnlineScreen
## The Keen 2 game screen that the start screen opens. [GameScreen] draws it
## as it draws Keen 1: the World viewport, the graphics (original, xBRZ or
## HD, F5), widescreen with the [Hud], the camera that follows Keen, and
## short messages. This plays a game of Keen 2 with [Keen2LevelPlay].
##
## The screen starts on the title (milestone B7, [Keen2MenuScreen]; from the
## start screen with the main menu open), or in the level given with
## [code]-- --level=N[/code] (1-16), after which the map comes. A game
## starts on the world map (map 80) with "Keens Left" (milestone B6). A level
## that is done, or a death, brings Keen back to the map. Enter shows the
## status screen ([Keen2StatusScreen]), Escape the main menu. With all eight
## cities saved the ending runs ([Keen2Ending]); after it, and after GAME
## OVER, the high scores. In widescreen, with the option on, a level can
## show a picture behind it (milestone B8: Keen 2's own pictures in
## [constant BACKGROUNDS_FOLDER] or the player's game_data/keen2/backgrounds,
## never Keen 1's); it darkens with the level.
##
## Milestone B5 added what the switches do: the darkness ([Keen2Darkness]),
## the Vorticon Elders' messages (in a [GameWindow], the game waits until
## Enter closes it), and the Tantalus Ray. What happens on map 81 (the
## Earth exploding, the ending's flights) is in [Keen2SpaceScreen].
##
## [GameScreen] shows Keen 1's ship parts in the HUD on the map; this view
## overrides [method _update_hud] so that it does not.
##
## Cheats for testing, as in Keen 1: Shift+N / Shift+P go to the next or
## previous level, Shift+I gives every item, Shift+G toggles god mode.

const MISSING_DATA_MESSAGE := (
	"Keen 2 data not found. Put the files in game_data/keen2 "
	+ "or start with: -- --data-dir-keen2=PATH"
)
const UNREADABLE_MESSAGE := "The Keen 2 files in %s could not be read."
const NOT_PLAYABLE_MESSAGE := "Keen 2 has no level %d"
const PLAYER_2_LEFT_MESSAGE := "Player 2 left"
const PLAYER_2_JOINED_MESSAGE := "Player 2 joined: player 1 on WASD, player 2 on the arrows"
const PLAYER_2_LATER_MESSAGE := "Player 2 plays along in the levels"
## Keen 2's own pictures behind the levels (Keen 1's are never used).
const BACKGROUNDS_FOLDER := "res://assets/backgrounds/keen2"
## How long "Keens Left" stays open (as Keen 1's), unless a button closes it.
const LIVES_SECONDS := 3.0
## Shown under an Elder's message unless it says so itself.
const ELDER_PROMPT := "Press ENTER:"
const ELDER_PROMPT_WORD := "ENTER"

var _elder_messages: Array[PackedStringArray] = []


func _ready() -> void:
	# Picked on the start screen: straight on to the main menu.
	var wants_menu := GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	var first := Keen2LevelPlay.requested_level(OS.get_cmdline_user_args())
	if first != 0 and not Keen2LevelPlay.is_playable(first):
		_show_message(NOT_PLAYABLE_MESSAGE % first)
		first = 0
	if first != 0:
		_start_level(first)
		return
	_show_title()
	if wants_menu:
		_open_main_menu()


## Player 2 joins or leaves. In a level his Keen appears where player 1's
## is; on the map he plays along from the next level on.
func _toggle_second_player() -> void:
	if _online.is_active():
		_show_message(NOT_ONLINE_MESSAGE)
		return
	_two_players = not _two_players
	if _mode == Mode.LEVEL and _session != null:
		if _two_players:
			var view_center := _camera.get_screen_center_position()
			_second_player.start(_session, _session.keen.position, view_center)
		else:
			_second_player.stop()
	if not _two_players:
		_show_message(PLAYER_2_LEFT_MESSAGE)
	elif _mode == Mode.LEVEL:
		_show_message(PLAYER_2_JOINED_MESSAGE)
	else:
		_show_message(PLAYER_2_LATER_MESSAGE)


## A new game (or [param game], a loaded one) on the world map.
func _start_game(game: Keen2Progress) -> void:
	play.new_game(game)
	# The HUD and the cheats look at GameScreen's progress.
	_progress = play.progress
	_god_mode = false
	if play.start_map():
		_show_lives(play.inventory.lives)
	else:
		_show_error("The world map could not be read from %s." % files.directory)


func _exit_tree() -> void:
	if _graphics_loader != null:
		_graphics_loader.finish()


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _graphics_loader != null and _graphics_loader.poll():
		_apply_graphics()
	# The game stands still while a menu is open, unless two play online.
	if _menus.is_open() and not _online.is_together():
		_update_status()
		return
	_count_down_window(delta)
	_count_down_screen(delta)
	var window_pauses := _window.visible and not _online.is_together()
	if _mode in [Mode.MAP, Mode.LEVEL] and not window_pauses:
		_run_ticks(delta)
	elif _mode == Mode.REMOTE:
		_run_remote(delta)
	elif _mode == Mode.ENDING:
		_run_ending(delta)
	elif _doom == Doom.SHAKING:
		_shake(delta)
	elif _doom == Doom.EXPLODING:
		_run_explosion(delta)
	_second_player.update(delta)
	_move_camera_anchor()
	_update_backdrops()
	_point_arrow()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if play == null:
		return
	if _menus.is_open():
		_menus.handle_input(event)
	elif _handle_display_keys(event):
		pass
	elif _mode in [Mode.TITLE, Mode.HIGH_SCORES, Mode.GAME_OVER]:
		if not _is_any_press(event):
			return
		_on_screen_key()
	elif event.is_action_pressed("menu"):
		_open_main_menu()
	elif event.is_action_pressed("status"):
		_on_enter_pressed()
	elif _handle_joined_input(event):
		pass
	elif event.is_action_pressed("toggle_second_player") and _mode in [Mode.MAP, Mode.LEVEL]:
		_toggle_second_player()
	elif _window.visible and _buttons_close_window and _is_button(event):
		_close_window()
	elif not _handle_cheat_keys(event):
		return
	get_viewport().set_input_as_handled()


## Enter moves on in the ending, closes a window, or opens the status screen.
func _on_enter_pressed() -> void:
	if _mode == Mode.ENDING:
		_keen2_ending.confirm()
	elif _window.visible:
		_close_window()
	elif _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]:
		var progress := _status_progress()
		Keen2StatusScreen.fill(_window, progress, _texts.status_lines, _texts.city_names)
		_buttons_close_window = true


## Runs the ticks for [param delta] seconds and shows the result.
func _run_ticks(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	if _session != null:
		_session.view_rects = _view_rects()
	var mode := _mode
	while _time_left >= KeenPhysics.TICK and _mode == mode:
		_time_left -= KeenPhysics.TICK
		play.step_players(_inputs())
		if _mode == mode:
			_send_tick()
		_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


## The buttons of this tick: one player's, or with two players each one's
## own keys (in a level), and on the map the keys of both and of playing
## alone, which all steer the one Keen there.
func _inputs() -> Array[KeenInput]:
	# Online the game goes on behind a menu; the keys are the menu's then.
	var own := KeenInput.new() if _menus.is_open() else KeenInput.from_actions()
	if _second_player.is_active() and not _second_player.is_split_screen():
		return [own, _online.partner_input()]
	if not _two_players:
		return [own]
	if _second_player.is_split_screen():
		return [KeenInput.for_player(0), KeenInput.for_player(1)]
	return [KeenInput.from_actions(), KeenInput.for_player(0), KeenInput.for_player(1)]


## What the players see, for waking up the enemies.
func _view_rects() -> Array[Rect2]:
	if _second_player.is_split_screen():
		return _second_player.view_rects()
	var rects: Array[Rect2] = [_own_view()]
	var partner_view := _online.partner_view()
	if partner_view.has_area():
		rects.append(partner_view)
	return rects


func _show_sprites() -> void:
	if _mode == Mode.LEVEL:
		_keen.show_body(_session.keen)
		_second_player.show_body()
		_actor_layer.show_actors(_session.actors)
	elif _mode == Mode.MAP:
		_keen.show_on_map(_map_session.keen)


## What [GameScreen] needs before anything is shown: the settings, the
## sounds, and the World viewport stretched over the window.
func _set_up_screen() -> void:
	_user_settings = UserSettings.load_from()
	_settings = _user_settings.display
	add_child(_sounds)
	_sounds.enabled = _user_settings.sound_enabled
	add_child(_keen_2_sounds)
	_keen_2_sounds.enabled = _user_settings.sound_enabled
	_world.add_child(_darkness)
	_backdrop.add_child(_backdrop_darkness)
	_backdrop_2.add_child(_backdrop_darkness_2)
	_menus.window = _window
	_menus.settings = _user_settings
	add_child(_menus)
	_set_up_menus()
	_connect_online()
	# GameScreen's drawings of Keen 1's ship stay empty here; in the tree
	# they are freed with the scene.
	_add_ship_drawings()
	_apply_window_mode()
	resized.connect(_fit_screen)
	_screen.texture = _world.get_texture()
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_screen.material = ShaderMaterial.new()
	_screen.material.shader = EVEN_PIXELS_SHADER
	_apply_display_settings()


## Reads the Keen 2 files and gets the drawing ready. Returns false (and
## shows why) when they cannot be read.
func _load_data() -> bool:
	if files == null:
		files = Keen2Files.locate()
	if files == null:
		_show_error(MISSING_DATA_MESSAGE)
		return false
	var data := Keen2GameData.load_from(files)
	if data == null:
		_show_error(UNREADABLE_MESSAGE % files.directory)
		return false
	_graphics = data.graphics
	_properties = data.properties
	_finale_image = data.finale
	_textures = GraphicsTextures.create(_graphics)
	_level_map.tile_set = LevelTileSet.build(_graphics, _textures)
	_keen.set_textures(_textures)
	_second_player.set_textures(_textures)
	_mark.set_textures(_textures)
	_actor_layer.set_textures(_textures)
	_window.set_textures(_textures)
	_hud.set_textures(_textures)
	_hud.raygun_tile = Keen2Icons.raygun(_properties)
	_hud.keycard_icons = Keen2Icons.keycards(_properties)
	_backdrop_pictures = _make_backdrop_pictures()
	_graphics_loader = GraphicsLoader.create(files, _graphics, _finale_image)
	_menus.hd_available = HdPack.exists(files)
	_apply_graphics()
	_sounds.load_sounds(data.sounds)
	_keen_2_sounds.load_sounds(data.sounds)
	_elder_messages = data.elder_messages
	_texts = data
	_set_up_texts()
	_set_up_online_data()
	play = Keen2LevelPlay.create(files, _properties)
	_progress = play.progress
	play.level_started.connect(_on_level_started)
	play.map_started.connect(_on_map_started)
	play.life_lost.connect(_show_lives)
	play.game_over.connect(_on_game_over)
	play.won.connect(_start_ending)
	play.earth_exploded.connect(_on_earth_exploded)
	return true


## The pictures behind the levels, for the levels they suit
## ([Keen2BackdropPictures]).
func _make_backdrop_pictures() -> Keen2BackdropPictures:
	var levels: Dictionary[int, LevelData] = {}
	for number in range(Keen2Files.FIRST_LEVEL, Keen2Files.LAST_LEVEL + 1):
		var level := LevelData.parse(files.read(files.level_file(number)))
		if level != null:
			levels[number] = level
	return Keen2BackdropPictures.for_levels(
		files, BACKGROUNDS_FOLDER, levels, _properties, _graphics.tiles
	)


func _start_level(number: int) -> void:
	if not play.start(number):
		_show_error("Level %d could not be read from %s." % [number, files.directory])


## Shows the level that [member play] has just started.
func _on_level_started(number: int) -> void:
	_clear_screen()
	_level_number = number
	_level = play.level
	_map_session = null
	_session = play.session
	_session.tile_changed.connect(_on_game_tile_changed)
	_session.sound_played.connect(_play_game_sound)
	_session.lights_changed.connect(_on_lights_changed)
	_session.elder_message_touched.connect(_on_elder_message)
	_session.set_invincible(_god_mode)
	_set_dark(_session.is_dark())
	_level_map.show_level(_level, _properties)
	_mode = Mode.LEVEL
	_frame_camera()
	_apply_backdrop()
	_keen.show_body(_session.keen)
	_follow(_keen)
	_announce_scene()
	if _two_players:
		_second_player.start(_session, _session.keen.position, _camera_anchor.position)
	elif _online.has_partner():
		_add_online_partner()


## Shows the world map that [member play] has just started: the done levels
## have their sign already.
func _on_map_started() -> void:
	_clear_screen()
	_level_number = Keen2Files.WORLD_MAP_LEVEL
	_level = play.level
	_session = null
	_map_session = play.map_session
	_map_session.tile_changed.connect(_on_game_tile_changed)
	_map_session.sound_played.connect(_play_game_sound)
	_set_dark(false)
	_level_map.show_level(_level, _properties)
	_mode = Mode.MAP
	_frame_camera()
	_apply_backdrop()
	_keen.show_on_map(_map_session.keen)
	_follow(_keen)
	_announce_scene()


## "Keens Left", with a little Keen per life, on the map; a button closes it
## and it closes by itself.
func _show_lives(lives: int) -> void:
	_sounds.play(Sound.Id.KEENS_LEFT)
	_send_event(OnlineMessages.Event.KEENS_LEFT, lives)
	MapMessages.show_lives(_window, lives)
	_window_time_left = LIVES_SECONDS
	_buttons_close_window = true


## The last life is gone: GAME OVER, then the high scores.
func _on_game_over() -> void:
	_clear_screen()
	_show_game_over()


## A Vorticon Elder speaks: its message, until Enter closes it (online it
## closes by itself), for the other player too.
func _on_elder_message() -> void:
	_send_event(OnlineMessages.Event.HINT, _level_number)
	_show_elder_message(_level_number)


## The message of the Elder in level [param number]. An Elder whose message
## was not found in KEEN2.EXE stays silent.
func _show_elder_message(number: int) -> void:
	var index := Keen2LevelPlay.elder_message_index(number)
	if index >= _elder_messages.size() or _elder_messages[index].is_empty():
		return
	var lines := _elder_messages[index].duplicate()
	if not "\n".join(lines).to_upper().contains(ELDER_PROMPT_WORD):
		lines.append_array(["", ELDER_PROMPT])
	_window.show_lines(lines)
	_close_by_itself_online()


## The HUD as [GameScreen] shows it, but never with Keen 1's ship parts.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]
		and not _menus.is_open()
	)
	if _hud.visible:
		_hud.show_inventory(_progress.inventory)


## The cheats, on the map and in a level; returns whether [param event] was
## one.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if _mode not in [Mode.MAP, Mode.LEVEL] or _joined_online:
		return false
	if event.is_action_pressed("cheat_items"):
		_progress.inventory.give_everything()
		_show_message("Cheat: all keycards and a full raygun")
	elif event.is_action_pressed("cheat_god"):
		_god_mode = not _god_mode
		if _session != null:
			_session.set_invincible(_god_mode)
		_show_message("Cheat: god mode " + ("on" if _god_mode else "off"))
	elif event.is_action_pressed("next_level"):
		_start_level(_neighbor_level(1))
	elif event.is_action_pressed("previous_level"):
		_start_level(_neighbor_level(-1))
	else:
		return false
	return true


## The level [param offset] places after the current one; wraps around.
## From the map, the next level is level 1 and the previous one level 16.
func _neighbor_level(offset: int) -> int:
	if _mode != Mode.LEVEL:
		return Keen2Files.FIRST_LEVEL if offset > 0 else Keen2Files.LAST_LEVEL
	var count := Keen2Files.LAST_LEVEL - Keen2Files.FIRST_LEVEL + 1
	return Keen2Files.FIRST_LEVEL + posmod(_level_number - Keen2Files.FIRST_LEVEL + offset, count)


## Jump, pogo or fire.
static func _is_button(event: InputEvent) -> bool:
	for button in ["jump", "pogo", "fire"]:
		if event.is_action_pressed(button):
			return true
	return false


## A key or button that was just pressed (not held, not the mouse).
static func _is_any_press(event: InputEvent) -> bool:
	return (
		event.is_pressed()
		and not event.is_echo()
		and (event is InputEventKey or event is InputEventJoypadButton)
	)
