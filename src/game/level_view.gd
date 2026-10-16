extends GameScreen
## The game screen: the whole of Keen 1, from the title to the end.
##
##   title        the title over Keen's ship; any key opens the main menu.
##                Left alone, it takes turns with the high scores.
##   high scores  the table in its red frame ([Backdrops])
##   map          Keen walks over the world map ([MapSession]) and enters
##                levels
##   level        Keen plays a level ([LevelSession]); afterwards he is back
##                on the map where he entered it, whether he completed it or
##                died
##   ship         with the extra levels on: Keen's crashed ship as a level of
##                its own, outside and inside, where he puts the parts back
##                ([ShipLevels], [ShipRepair])
##   game over    the GAMEOVER bitmap, after the last life
##   ending       once Keen has all four ship parts, he flies home
##                ([EndingSequence]); with the extra levels on, once they
##                are all back in the ship
## After game over and after the ending, a good score goes into the high
## score table; then the title returns. The special maps (81, 90) can be
## looked at freely, for testing.
##
## Two can play on one keyboard: F7 (or the menu) lets a second player join
## or leave at any moment. In the levels both play, each with his own keys
## ([KeyBindings]), sharing the [Inventory]; on the world map player 1 walks
## alone, steered by the keys of both. When the two move apart the screen
## splits in two ([TwoPlayerView]).
##
## Two can also play online ([OnlinePlay], docs/online.md): one hosts, by IP
## or through Steam, and runs the game as always, with the Keen of the
## player who joins as player 2 (next to the host's Keen, on one screen of
## his own). The player who joins sees the host's game in the REMOTE mode:
## the host's map or level, drawn from what the host sends. Online nothing
## pauses: menus and windows are each player's own.
##
## Escape opens the menu ([MenuController]); Enter shows the status screen;
## the statues and the ship show messages. While a menu or such a
## [GameWindow] is open the game is paused. For testing there are cheats:
## Shift+N / Shift+P go to the next or previous map, Shift+I gives every
## item, Shift+G toggles god mode.
##
## Everything is drawn in game pixels into the World viewport. With the
## original picture that viewport has the original resolution; with xBRZ,
## HD graphics or smooth motion it is a whole number of times larger, about
## as large as the window, so that the finer graphics and the positions in
## between pixels can be seen. The picture is then stretched to fit the
## window with every game pixel the same size, see [DisplaySettings] and
## docs/graphics.md. F5 switches the graphics, F6 smooth motion.
##
## What is on the screen and how it is drawn (the picture, the graphics,
## the status line, the HUD and the windows) is in [GameScreen]; this is
## what happens in the game.
##
## Command-line options: [code]-- --level=N[/code] starts in level N
## (80 is the world map) instead of at the title; [code]-- --ending[/code]
## shows the ending straight away.

const LEVEL_OPTION := GameLaunch.LEVEL_OPTION
const ENDING_OPTION := GameLaunch.ENDING_OPTION
## Seconds the title and the high scores each stay before the other one
## comes, while nobody presses a key.
const ATTRACT_SECONDS := 8.0
## Seconds the GAMEOVER bitmap stays, unless a key closes it.
const GAME_OVER_SECONDS := 4.0
const GAME_OVER_BITMAP := "GAMEOVER"
## The GAMEOVER bitmap is 112x24 pixels: 14x3 cells of the window.
const GAME_OVER_CELLS := Vector2i(14, 3)
## Seconds the "Keens Left" window stays open, unless a button closes it.
const LIVES_SECONDS := 3.0
## Online nothing pauses, so the other windows of the game close by
## themselves after this many seconds too (or with a button).
const ONLINE_WINDOW_SECONDS := 6.0
const ONLY_HOST_WALKS_MESSAGE := "Only the host can walk on the world map"
const MISSING_DATA_MESSAGE := (
	"Keen 1 data not found. Put the files in game_data/keen1 "
	+ "(see game_data/README.md) or start with: -- --data-dir=PATH"
)

var _files: GameFiles
var _level_numbers := PackedInt32Array()
var _time_left := 0.0
## The statue messages and the texts of the ending; null when they could
## not be read.
var _hints: HintTexts
var _ending_texts: EndingTexts
var _saves := SaveGames.new()
var _high_scores := HighScores.new()
var _ship := ShipVisit.new()
## The words for the places in the high score table; null when not found.
var _score_texts: ScoreTexts
## The place in the high score table that is waiting for a name, or -1.
var _pending_place := -1
## Counts down on the title and high score screens, and after game over.
var _screen_time_left := 0.0
## Whether a second player plays along in the levels.
var _two_players := false


func _ready() -> void:
	_user_settings = UserSettings.load_from()
	_settings = _user_settings.display
	add_child(_sounds)
	_sounds.enabled = _user_settings.sound_enabled
	_menus.window = _window
	_menus.settings = _user_settings
	_menus.saves = _saves
	_menus.chosen.connect(_on_menu_chosen)
	_menus.settings_changed.connect(_on_settings_changed)
	_menus.name_entered.connect(_on_name_entered)
	add_child(_menus)
	_connect_online()
	_apply_window_mode()
	resized.connect(_fit_screen)
	_ship.note_shown.connect(_show_ship_note)
	_add_ship_drawings()
	_screen.texture = _world.get_texture()
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_screen.material = ShaderMaterial.new()
	_screen.material.shader = EVEN_PIXELS_SHADER
	_apply_display_settings()

	_files = GameFiles.locate()
	if _files == null:
		_show_error(MISSING_DATA_MESSAGE)
		return
	_graphics = EgaGraphics.load_from(_files)
	if _graphics == null:
		_show_error("The game files in %s could not be read." % _files.directory)
		return
	_level_numbers = _files.level_numbers()
	if not _level_numbers.has(GameFiles.WORLD_MAP_LEVEL):
		_show_error("The world map is missing in %s." % _files.directory)
		return
	_properties = TileProperties.load_from(_files, _graphics.tiles.size())
	if _properties == null:
		_show_error("The tile properties in %s could not be read." % GameFiles.EXECUTABLE)
		return

	_textures = GraphicsTextures.create(_graphics)
	_level_map.tile_set = LevelTileSet.build(_graphics, _textures)
	_backdrop_pictures = BackdropPictures.create(_files)
	_keen.set_textures(_textures)
	_second_player.set_textures(_textures)
	_mark.set_textures(_textures)
	_actor_layer.set_textures(_textures)
	_window.set_textures(_textures)
	_pictures.set_textures(_textures)
	_hud.set_textures(_textures)
	_screen_note.set_textures(_textures)
	_online.set_textures(_textures)
	_online.files = _files
	_online.fingerprint = LevelFingerprint.of(_files)
	_load_texts()
	_finale_image = FinaleImage.load_from(_files)
	_graphics_loader = GraphicsLoader.create(_files, _graphics, _finale_image)
	_menus.hd_available = HdPack.exists(_files)
	_apply_graphics()
	if _files.has_file(GameFiles.SOUNDS):
		_sounds.load_sounds(SoundFile.load_from(_files))
	if OS.get_cmdline_user_args().has(ENDING_OPTION):
		_progress.inventory.ship_parts.fill(true)
		_progress.installed_parts.fill(true)
		_enter_map(false)
		return
	var level := _requested_level()
	if level > 0:
		_go_to(level)
	else:
		_show_title()
		# Picked on the start screen: straight on to the main menu.
		if GameLaunch.take_menu_request():
			_open_main_menu(false, false)


## The texts of the game from KEEN1.EXE and the text files. Each one that
## is missing only switches off its own part of the game.
func _load_texts() -> void:
	_hints = HintTexts.load_from(_files)
	_ending_texts = EndingTexts.load_from(_files)
	_score_texts = ScoreTexts.load_from(_files)
	var names := _score_texts.default_names if _score_texts != null else PackedStringArray()
	_high_scores = HighScores.load_from(HighScores.DEFAULT_PATH, names)
	if _files.has_file(GameFiles.STORY_TEXT):
		_menus.story = TextDocument.layout(
			_files.read(GameFiles.STORY_TEXT), MenuController.TEXT_WIDTH
		)


func _exit_tree() -> void:
	if _graphics_loader != null:
		_graphics_loader.finish()
	_online.leave()


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _graphics_loader != null and _graphics_loader.poll():
		_apply_graphics()
	if _menus.is_open() and not _plays_on_behind_menu():
		_update_status()
		return
	_count_down_window(delta)
	_count_down_screen(delta)
	var window_pauses := _window.visible and not _online.is_together()
	if _mode == Mode.ENDING or (_mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE] and not window_pauses):
		_play(delta)
	_second_player.update(delta)
	_move_camera_anchor()
	_update_backdrops()
	_point_arrow()
	_update_status()


## Online nothing pauses: the game goes on behind a menu.
func _plays_on_behind_menu() -> bool:
	return _online.is_together() and _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]


## Runs the ticks for [param delta] seconds and shows the result.
func _play(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	if _session != null:
		_session.view_rects = _view_rects()
	var mode := _mode
	while _time_left >= KeenPhysics.TICK and _mode == mode:
		_time_left -= KeenPhysics.TICK
		_tick()
		_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


## What the players see in the level, for waking up the enemies.
func _view_rects() -> Array[Rect2]:
	if _second_player.is_split_screen():
		return _second_player.view_rects()
	var rects: Array[Rect2] = [_own_view()]
	var partner_view := _online.partner_view()
	if partner_view.has_area():
		rects.append(partner_view)
	return rects


## One tick of whatever is going on.
func _tick() -> void:
	match _mode:
		Mode.LEVEL:
			if _second_player.is_split_screen():
				_session.step_players([KeenInput.for_player(0), KeenInput.for_player(1)])
			elif _second_player.is_active():
				_session.step_players([_local_input(), _online.partner_input()])
			else:
				_session.step(_local_input())
			_ship.step(_session)
			_online.send_level(_session, _progress.inventory)
			if _session.outcome != LevelSession.Outcome.PLAYING:
				_on_level_over(_session.outcome)
			elif _ship.is_ready_to_fly():
				# Back on the map with every part in: the ending starts there.
				_enter_map(false)
		Mode.MAP:
			_map_session.extra_levels = _user_settings.extra_levels
			_map_session.step(_map_input())
			_online.send_map(_map_session.keen, _progress.inventory)
			if _map_session.outcome == MapSession.Outcome.ENTER_LEVEL:
				_go_to(_map_session.chosen_level)
		Mode.ENDING:
			var input := _map_input()
			_ending.step(input.jump or input.pogo or input.fire, input.vertical)
			if _ending.is_finished():
				_finish_game()
		Mode.REMOTE:
			var snapshot := _online.client_tick(_local_input(), _own_view())
			if snapshot != null:
				_show_remote(snapshot)


## The buttons of this player, playing alone or online. Online the game
## goes on behind a menu; the keys are the menu's then.
func _local_input() -> KeenInput:
	if _menus.is_open():
		return KeenInput.new()
	return KeenInput.from_actions()


## The buttons for the world map and the ending, where player 1 is alone:
## when two play, the keys of both steer him.
func _map_input() -> KeenInput:
	var input := _local_input()
	if _two_players:
		input = KeenInput.combine([input, KeenInput.for_player(0), KeenInput.for_player(1)])
	return input


func _show_sprites() -> void:
	_mark.show_sprite(Vector2.ZERO, -1)
	match _mode:
		Mode.LEVEL:
			_keen.show_body(_session.keen)
			_second_player.show_body()
			_actor_layer.show_actors(_session.actors)
		Mode.MAP:
			_keen.show_on_map(_map_session.keen)
		Mode.ENDING:
			if _ending.flight != null and _ending.map_number() == GameFiles.ENDING_LEVEL:
				var flight := _ending.flight
				_keen.show_sprite(flight.position, flight.sprite)
				_mark.show_sprite(flight.mark_position(), flight.mark)
				var brightness := 1.0 - flight.fade
				_screen.modulate = Color(brightness, brightness, brightness)
			elif _map_session != null:
				_keen.show_on_map(_map_session.keen)


func _unhandled_input(event: InputEvent) -> void:
	if _level_numbers.is_empty() or _properties == null:
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
		_open_menu()
	else:
		_handle_game_input(event)
		return
	get_viewport().set_input_as_handled()


## Keys while the game is being played.
func _handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("status"):
		_on_enter_pressed()
	elif _window.visible and _buttons_close_window and _is_button(event):
		_close_window()
	elif _mode == Mode.REMOTE or _joined_online:
		_handle_joined_input(event)
		return
	elif event.is_action_pressed("cheat_items"):
		_progress.inventory.give_everything()
		_show_message("Cheat: all keycards, the pogo stick and a full raygun")
	elif event.is_action_pressed("toggle_second_player"):
		if _online.is_active():
			_show_message("Not while playing online")
		else:
			_toggle_second_player()
	elif event.is_action_pressed("cheat_god"):
		_god_mode = not _god_mode
		if _session != null:
			_session.set_invincible(_god_mode)
		_show_message("Cheat: god mode " + ("on" if _god_mode else "off"))
	elif event.is_action_pressed("next_level"):
		_go_to(_neighbor_level(1))
	elif event.is_action_pressed("previous_level"):
		_go_to(_neighbor_level(-1))
	else:
		return
	get_viewport().set_input_as_handled()


## Keys of the player who joined someone's game: no cheats, and on the
## world map only the host walks.
func _handle_joined_input(event: InputEvent) -> void:
	if _mode != Mode.REMOTE or _remote.kind != OnlineMessages.Scene.MAP:
		return
	for action in ["move_left", "move_right", "move_up", "move_down", "jump", "pogo", "fire"]:
		if event.is_action_pressed(action):
			_show_message(ONLY_HOST_WALKS_MESSAGE)
			get_viewport().set_input_as_handled()
			return


## A key or button that was just pressed (not held, not the mouse).
static func _is_any_press(event: InputEvent) -> bool:
	return (
		event.is_pressed()
		and not event.is_echo()
		and (event is InputEventKey or event is InputEventJoypadButton)
	)


## Jump, pogo or fire, of one player or of either of two.
static func _is_button(event: InputEvent) -> bool:
	for prefix in ["", "p1_", "p2_"]:
		for button in ["jump", "pogo", "fire"]:
			if event.is_action_pressed(prefix + button):
				return true
	return false


## Enter moves on in the ending, closes a window, or opens the status screen.
func _on_enter_pressed() -> void:
	if _mode == Mode.ENDING:
		_ending.confirm()
	elif _window.visible:
		_close_window()
	elif _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]:
		StatusScreen.fill(_window, _progress.inventory, _god_mode)


func _on_hint_touched() -> void:
	if _hints == null:
		return
	var lines := _hints.for_level(_level_number)
	if lines.is_empty():
		return
	_online.send_event(OnlineMessages.Event.HINT, _level_number)
	if _menus.is_open():
		return
	lines.append_array(["", HintTexts.PROMPT])
	_window.show_lines(lines)
	_close_by_itself_online()


## Online nothing pauses, so a window of the game closes by itself (or
## with a button).
func _close_by_itself_online() -> void:
	if _online.is_together():
		_window_time_left = ONLINE_WINDOW_SECONDS
		_buttons_close_window = true


func _on_ship_used() -> void:
	if _progress.inventory.has_all_ship_parts():
		_start_ending()
	elif _ending_texts != null:
		_online.send_event(OnlineMessages.Event.SHIP_MISSING, 0)
		_show_missing_parts()


func _show_missing_parts() -> void:
	if _ending_texts == null or _menus.is_open():
		return
	MapMessages.show_missing_parts(_window, _ending_texts.missing_parts, _progress.inventory)
	_buttons_close_window = true
	_close_by_itself_online()


## The level asked for on the command line, or 0 to start at the title.
func _requested_level() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(LEVEL_OPTION) and argument.trim_prefix(LEVEL_OPTION).is_valid_int():
			return argument.trim_prefix(LEVEL_OPTION).to_int()
	return 0


func _open_menu() -> void:
	_close_window()
	var in_game := _mode in [Mode.MAP, Mode.LEVEL, Mode.LOOK, Mode.ENDING, Mode.REMOTE]
	_open_main_menu(in_game, _can_save())


func _open_main_menu(in_game: bool, can_save: bool) -> void:
	_user_settings.fullscreen = _is_fullscreen()
	_menus.online = _online.menu_info()
	_menus.open_main(in_game, can_save, _two_players)


## Saving is only possible while Keen stands still on the world map.
func _can_save() -> bool:
	return (
		_mode == Mode.MAP
		and not _map_session.is_teleporting()
		and _map_session.outcome == MapSession.Outcome.PLAYING
	)


func _on_menu_chosen(id: StringName, slot: int) -> void:
	match id:
		MenuController.CHOICE_NEW_GAME:
			_start_new_game("")
		MenuController.CHOICE_SECOND_PLAYER:
			_toggle_second_player()
		MenuController.CHOICE_LOAD:
			_load_game(slot)
		MenuController.CHOICE_SAVE:
			_progress.map_position = _map_session.keen.position
			if not _saves.write(slot, _progress):
				_show_message("The game could not be saved.")
		MenuController.CHOICE_HIGH_SCORES:
			_show_high_scores()
		MenuController.CHOICE_TITLE:
			_show_title()
		MenuController.CHOICE_QUIT:
			get_tree().quit()
		MenuController.CHOICE_CHOOSE_GAME:
			# Deferred: this runs inside the handling of a key, and changing the
			# scene takes this one out of the tree at once.
			get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)
		MenuController.CHOICE_LEAVE_ONLINE:
			_leave_online()
		_:
			if id == MenuController.CHOICE_HOST and _two_players:
				_toggle_second_player()
			_online.handle_choice(id, slot)


func _load_game(slot: int) -> void:
	var game := _saves.read(slot)
	if game == null:
		_menus.show_message(["That game could not be", "read.  Press a key"])
		return
	_progress = game
	_god_mode = false
	_enter_map(true)


## Shows the title over Keen's ship.
func _show_title() -> void:
	if _show_backdrop(Mode.TITLE, Backdrops.TITLE_SCREEN):
		Backdrops.show_title(_pictures)


## Shows the high score table.
func _show_high_scores() -> void:
	if _show_backdrop(Mode.HIGH_SCORES, Backdrops.HIGH_SCORE_SCREEN):
		Backdrops.show_high_scores(_pictures, _high_scores)


## Shows the screen [param area] of map 90 and switches to [param mode].
## Returns false when the map cannot be read.
func _show_backdrop(mode: Mode, area: Rect2i) -> bool:
	if not _load_map(GameFiles.BACKDROPS_LEVEL, area):
		return false
	_level_map.show_level(_level, _properties)
	_mode = mode
	_screen_time_left = ATTRACT_SECONDS
	_announce_scene()
	_follow(_camera_anchor)
	# The screens are a little taller than the view: show their top.
	var area_pixels := LevelMap.playable_pixels(_level)
	_camera_anchor.position = Vector2(
		area_pixels.get_center().x, area_pixels.position.y + _settings.game_size().y / 2.0
	)
	_camera.reset_smoothing()
	return true


## Counts down the time on the title, the high scores and game over.
func _count_down_screen(delta: float) -> void:
	if not _mode in [Mode.TITLE, Mode.HIGH_SCORES, Mode.GAME_OVER]:
		return
	_screen_time_left -= delta
	if _screen_time_left > 0.0:
		return
	match _mode:
		Mode.TITLE:
			_show_high_scores()
		Mode.HIGH_SCORES:
			_show_title()
		Mode.GAME_OVER:
			_finish_game()


## A key on the title or the high scores opens the main menu; after game
## over it moves on.
func _on_screen_key() -> void:
	if _mode == Mode.GAME_OVER:
		_finish_game()
	else:
		_open_main_menu(false, false)


## The last life is gone: GAMEOVER, then the high scores.
func _game_over() -> void:
	_sounds.play(Sound.Id.GAME_OVER)
	_mode = Mode.GAME_OVER
	_screen_time_left = GAME_OVER_SECONDS
	_window.open(GAME_OVER_CELLS)
	_window.put_bitmap(Vector2i.ZERO, GAME_OVER_BITMAP)
	_announce_scene()


## The game is over (game over or the ending): a good score asks for a name
## and goes into the table, which is shown.
func _finish_game() -> void:
	_close_window()
	if _joined_online:
		# The host's table, not ours; wait for the host's next game.
		_progress = GameProgress.new()
		_show_title()
		return
	_show_high_scores()
	_pending_place = _high_scores.place_for(_progress.inventory.score)
	if _pending_place < 0:
		_progress = GameProgress.new()
		return
	_sounds.play(Sound.Id.HIGH_SCORE)
	var words := _score_texts.place_names if _score_texts != null else PackedStringArray()
	_menus.ask_name(words[_pending_place] if _pending_place < words.size() else "a")


func _on_name_entered(player_name: String) -> void:
	if _pending_place < 0:
		return
	var inventory := _progress.inventory
	_high_scores.insert(_pending_place, player_name, inventory.score, inventory.ship_parts)
	_high_scores.save()
	_pending_place = -1
	_progress = GameProgress.new()
	_show_high_scores()


## The map that comes [param offset] places after the current one (for the
## cheats); wraps around.
func _neighbor_level(offset: int) -> int:
	var index := maxi(0, _level_numbers.find(_level_number))
	return _level_numbers[posmod(index + offset, _level_numbers.size())]


## Shows map [param number]: the world map, a level, or a special map.
func _go_to(number: int) -> void:
	if number == GameFiles.WORLD_MAP_LEVEL:
		_enter_map(true)
	elif GameFiles.is_playable_level(number) or ShipLevels.is_ship_level(number):
		_enter_level(number)
	else:
		_look_at(number)


func _start_new_game(message: String) -> void:
	_progress = GameProgress.new()
	_god_mode = false
	if not message.is_empty():
		_show_message(message)
	_enter_map(true)


## Puts Keen on the world map, where he entered the last level. With
## [param show_lives] the "Keens Left" window opens, as at the start of the
## game and after dying.
func _enter_map(show_lives: bool) -> void:
	if not _load_map(GameFiles.WORLD_MAP_LEVEL):
		return
	_map_session = MapSession.create(_level, _properties, _progress)
	_level_map.show_level(_level, _properties)
	_map_session.tile_changed.connect(_on_tile_changed)
	_map_session.ship_used.connect(_on_ship_used)
	_map_session.sound_played.connect(_play_game_sound)
	_mode = Mode.MAP
	_announce_scene()
	_keen.show_on_map(_map_session.keen)
	_follow(_keen)
	if _ship_can_fly():
		_start_ending()
	elif show_lives:
		_online.send_event(OnlineMessages.Event.KEENS_LEFT, _progress.inventory.lives)
		_show_lives(_progress.inventory.lives)


## Whether Keen can fly home: he has every ship part, and with the extra
## levels on they are also all back in the ship.
func _ship_can_fly() -> bool:
	if not _progress.inventory.has_all_ship_parts():
		return false
	return not _user_settings.extra_levels or _progress.all_parts_installed()


func _show_lives(lives: int) -> void:
	_sounds.play(Sound.Id.KEENS_LEFT)
	if _menus.is_open():
		return
	MapMessages.show_lives(_window, lives)
	_window_time_left = LIVES_SECONDS
	_buttons_close_window = true


## Starts an attempt at level [param number].
func _enter_level(number: int) -> void:
	if not _load_map(number):
		return
	_level_map.show_level(_level, _properties)
	var start := _ship.start_cell(_level, number, _start_cell())
	_session = LevelSession.create(
		_level, _properties, _progress.inventory, Vector2(start * EgaGraphics.TILE_SIZE), number
	)
	# Playing a level again (the pogo level) gives no points.
	_session.scores_points = not _progress.is_completed(number)
	_ship.set_up(_session, number, _progress)
	_session.tile_changed.connect(_on_tile_changed)
	_session.hint_touched.connect(_on_hint_touched)
	_session.sound_played.connect(_play_game_sound)
	_session.set_invincible(_god_mode)
	_mode = Mode.LEVEL
	_announce_scene()
	_keen.show_body(_session.keen)
	_follow(_keen)
	if _two_players:
		_second_player.start(_session, _session.keen.position, _camera_anchor.position)
	elif _online.has_partner():
		_add_online_partner()


## A note of the ship in the middle of the view; the other player sees it in
## his status line.
func _show_ship_note(text: String) -> void:
	_screen_note.show_text(text)
	_online.send_event(OnlineMessages.Event.MESSAGE, text)


## A tile of the level changed: draw it, and let the other player know.
func _on_tile_changed(cell: Vector2i, tile: int) -> void:
	_level_map.set_tile(cell, tile)
	_online.send_tile(cell, tile)


## A sound of the game: play it, and let the other player hear it too.
func _play_game_sound(sound: Sound.Id) -> void:
	_sounds.play(sound)
	_online.send_sound(sound)


## The player who joined online plays along in this level: his Keen
## appears next to the host's.
func _add_online_partner() -> void:
	var at := OnlineSpawn.beside(_session, _session.keen)
	_second_player.start(_session, at, _camera.get_screen_center_position(), false)


## A second player joins, or leaves. In a level his Keen appears at player
## 1's, or disappears; on the map he joins from the next level on.
func _toggle_second_player() -> void:
	_two_players = not _two_players
	if _mode == Mode.LEVEL and _session != null:
		if _two_players:
			var view_center := _camera.get_screen_center_position()
			_second_player.start(_session, _session.keen.position, view_center)
		else:
			_second_player.stop()
	if not _two_players:
		_show_message("Player 2 left")
	elif _mode == Mode.LEVEL:
		_show_message("Player 2 joined: player 1 on WASD, player 2 on the arrows")
	else:
		_show_message("Player 2 plays along in the levels")


## Shows a special map to look around in.
func _look_at(number: int) -> void:
	if not _load_map(number):
		return
	_level_map.show_level(_level, _properties)
	_mode = Mode.LOOK
	_announce_scene()
	_free_look.move_to((Vector2(_start_cell()) + Vector2(0.5, 0.5)) * EgaGraphics.TILE_SIZE)
	_follow(_free_look)


func _on_level_over(outcome: LevelSession.Outcome) -> void:
	var number := _level_number
	if ShipLevels.is_ship_level(number) and outcome != LevelSession.Outcome.DIED:
		_on_ship_level_over(number, outcome)
		return
	match outcome:
		LevelSession.Outcome.COMPLETED:
			# As in the original: back on the map, where the level shows "done".
			_progress.complete_level(number)
			_enter_map(false)
		LevelSession.Outcome.TELEPORTED:
			_enter_map(false)
			if _mode == Mode.MAP:
				_map_session.teleport_to_secret_place()
		LevelSession.Outcome.DIED:
			if _progress.inventory.is_game_over():
				_game_over()
			else:
				_enter_map(true)


## Keen went through the door of the ship (in or out), or walked away from
## it to the map.
func _on_ship_level_over(number: int, outcome: LevelSession.Outcome) -> void:
	var next := _ship.next_level(number, outcome)
	if next == ShipVisit.TO_MAP:
		_enter_map(false)
	else:
		_enter_level(next)


func _start_ending() -> void:
	if _ending_texts == null:
		_show_message("The texts of the ending could not be read.")
		return
	_close_window()
	_ending = EndingSequence.create(_ending_texts, _files.read(GameFiles.END_TEXT))
	_ending.changed.connect(_on_ending_changed)
	_mode = Mode.ENDING
	_announce_scene()
	_on_ending_changed()


## Shows the stage of the ending that has just begun, or its next message.
func _on_ending_changed() -> void:
	var map_number := _ending.map_number()
	if map_number != 0 and map_number != _level_number:
		if not _load_map(map_number):
			return
		_level_map.show_level(_level, _properties)
	elif map_number == 0:
		_level_map.clear()
		_level_map.foreground().clear()
	_screen.modulate = Color.WHITE
	if _ending.stage == EndingSequence.Stage.AT_SHIP and _map_session != null:
		_map_session.place_next_to_ship()
	_follow(_keen)
	# Keen and his ship are only seen on a map.
	_keen.visible = map_number != 0
	_mark.visible = map_number != 0
	_show_picture(_ending.stage == EndingSequence.Stage.AT_HOME)

	var lines := _ending.window_lines()
	if lines.is_empty():
		_window.close()
		return
	var at_end_text := _ending.stage == EndingSequence.Stage.END_TEXT
	_window.at_bottom = _ending.stage == EndingSequence.Stage.AT_HOME
	_window.show_lines(lines, EndingSequence.TEXT_WIDTH if at_end_text else 0)


## Loads map [param number] fresh from its file, so that every item is back.
## With [param area], only those cells of it are kept (see [Backdrops]).
## Returns false (and says why) when it cannot be read.
func _load_map(number: int, area := Rect2i()) -> bool:
	_second_player.stop()
	_session = null
	_map_session = null
	_ship.leave()
	_actor_layer.clear()
	_pictures.clear()
	_close_window()
	_picture.visible = false
	_screen.modulate = Color.WHITE
	_level_number = number
	var file_name := GameFiles.level_file_name(number)
	if ShipLevels.is_ship_level(number):
		file_name = ShipLevels.title(number)
		_level = ShipLevels.build(number, _progress.installed_parts)
	else:
		_level = LevelData.parse(_files.read(file_name))
	_show_ship_drawings()
	if _level == null:
		_mode = Mode.NONE
		_level_map.clear()
		_follow(_free_look)
		_show_message("%s could not be read." % file_name)
		return false
	if area.has_area():
		_level = _level.crop(area)
	_time_left = 0.0
	_frame_camera()
	_apply_backdrop()
	return true


## The cell where Keen starts, or the top left of the map if it has none.
func _start_cell() -> Vector2i:
	var cell := _level.find_info(LevelData.PLAYER_START_INFO)
	if cell.x < 0:
		cell = _level.playable_rect().position
	return cell


func _connect_online() -> void:
	_online.attach(_menus, _user_settings)
	_online.sound_enabled = _user_settings.sound_enabled
	_remote.sounds = _sounds
	_online.hosting_started.connect(_on_hosting_started)
	_online.joined.connect(_on_joined_online)
	_online.stopped.connect(_on_online_stopped)
	_online.partner_joined.connect(_on_partner_joined)
	_online.partner_left.connect(_drop_online_partner)
	_online.scene_changed.connect(_on_remote_scene)
	_online.tile_changed.connect(
		func(cell: Vector2i, tile: int) -> void: _remote.change_tile(_level, cell, tile)
	)
	_online.event_shown.connect(_on_remote_event)


## (Host) tells the player who joined what the screen shows now.
func _announce_scene() -> void:
	if not _online.is_hosting():
		return
	var kinds := {
		Mode.MAP: OnlineMessages.Scene.MAP,
		Mode.LEVEL: OnlineMessages.Scene.LEVEL,
		Mode.GAME_OVER: OnlineMessages.Scene.GAME_OVER,
		Mode.ENDING: OnlineMessages.Scene.ENDING,
	}
	_online.announce(kinds.get(_mode, OnlineMessages.Scene.WAITING), _level_number, _level)


## Hosting has begun: the other player needs a game to join, so from the
## title a new one starts.
func _on_hosting_started() -> void:
	if _mode in [Mode.MAP, Mode.LEVEL, Mode.LOOK, Mode.ENDING]:
		_announce_scene()
	else:
		_start_new_game("")


## Stops hosting, or leaves the host's game.
func _leave_online() -> void:
	_online.leave()
	_on_online_stopped()
	if _mode != Mode.TITLE:
		_show_message("Hosting stopped")


func _on_partner_joined(_player_name: String) -> void:
	if _mode == Mode.LEVEL and _session != null and not _second_player.is_active():
		_add_online_partner()


func _drop_online_partner(_player_name := "") -> void:
	if _second_player.is_active() and not _second_player.is_split_screen():
		_second_player.stop()


## (Joiner) the host let us in: our own game makes way for his.
func _on_joined_online(_host_name: String) -> void:
	if _two_players:
		_toggle_second_player()
	_joined_online = true
	_progress = GameProgress.new()
	_god_mode = false
	_show_title()


## The online game is over (or never began): a player who had joined is
## back at his own title.
func _on_online_stopped() -> void:
	_drop_online_partner()
	if _joined_online:
		_joined_online = false
		_progress = GameProgress.new()
		_show_title()


## (Joiner) the host shows another scene.
func _on_remote_scene(kind: OnlineMessages.Scene, number: int, tiles: PackedInt32Array) -> void:
	match kind:
		OnlineMessages.Scene.MAP, OnlineMessages.Scene.LEVEL:
			if not _load_map(number):
				return
			_remote.begin(kind, _level, _properties, tiles)
			_mode = Mode.REMOTE
			_follow(_keen)
		OnlineMessages.Scene.GAME_OVER:
			_game_over()
		OnlineMessages.Scene.ENDING:
			# Each player watches the ending at his own pace.
			_progress.map_position = _remote.map_position
			_progress.inventory.ship_parts.fill(true)
			_progress.installed_parts.fill(true)
			_enter_map(false)
		_:
			_show_title()


## (Joiner) a message of the host's game.
func _on_remote_event(kind: OnlineMessages.Event, value: Variant) -> void:
	if _mode != Mode.REMOTE:
		return
	match kind:
		OnlineMessages.Event.HINT:
			_on_hint_touched()
		OnlineMessages.Event.KEENS_LEFT:
			_show_lives(value)
		OnlineMessages.Event.SHIP_MISSING:
			_show_missing_parts()
		OnlineMessages.Event.MESSAGE:
			_show_message(value)


## (Joiner) one tick of the host's game.
func _show_remote(snapshot: Snapshot) -> void:
	_progress.inventory = snapshot.inventory
	if _remote.show(snapshot):
		_follow(_keen)


## Online, in a level: the arrow toward the other player when he is out of
## sight.
func _point_arrow() -> void:
	var to_partner := _mode == Mode.LEVEL and _online.has_partner() and _second_player.is_active()
	var to_host := _mode == Mode.REMOTE and _remote.kind == OnlineMessages.Scene.LEVEL
	var shown := not _menus.is_open()
	_remote.point_arrow(_own_view(), to_partner and shown, to_host and shown)
