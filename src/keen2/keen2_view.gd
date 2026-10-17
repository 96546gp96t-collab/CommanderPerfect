class_name Keen2View
extends Keen2MenuScreen
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
## OVER, the high scores. The pictures behind the levels come in milestone
## B8: no [BackdropPictures] are made, so [method GameScreen._apply_backdrop]
## shows none, also not Keen 1's.
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
	# The game stands still while a menu is open.
	if _menus.is_open():
		_update_status()
		return
	_count_down_window(delta)
	_count_down_screen(delta)
	if _mode in [Mode.MAP, Mode.LEVEL] and not _window.visible:
		_run_ticks(delta)
	elif _mode == Mode.ENDING:
		_run_ending(delta)
	elif _doom == Doom.SHAKING:
		_shake(delta)
	elif _doom == Doom.EXPLODING:
		_run_explosion(delta)
	_move_camera_anchor()
	_update_backdrops()
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
	elif _mode in [Mode.MAP, Mode.LEVEL]:
		Keen2StatusScreen.fill(_window, play.progress, _texts.status_lines, _texts.city_names)
		_buttons_close_window = true


## Runs the ticks for [param delta] seconds and shows the result.
func _run_ticks(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	if _session != null:
		var views: Array[Rect2] = [_own_view()]
		_session.view_rects = views
	while (
		_time_left >= KeenPhysics.TICK and _mode in [Mode.MAP, Mode.LEVEL] and not _window.visible
	):
		_time_left -= KeenPhysics.TICK
		play.step(KeenInput.from_actions())
		_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


func _show_sprites() -> void:
	if _mode == Mode.LEVEL:
		_keen.show_body(_session.keen)
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
	_menus.window = _window
	_menus.settings = _user_settings
	add_child(_menus)
	_set_up_menus()
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
	_graphics_loader = GraphicsLoader.create(files, _graphics, _finale_image)
	_menus.hd_available = HdPack.exists(files)
	_apply_graphics()
	_sounds.load_sounds(data.sounds)
	_keen_2_sounds.load_sounds(data.sounds)
	_elder_messages = data.elder_messages
	_texts = data
	_set_up_texts()
	play = Keen2LevelPlay.create(files, _properties)
	_progress = play.progress
	play.level_started.connect(_on_level_started)
	play.map_started.connect(_on_map_started)
	play.life_lost.connect(_show_lives)
	play.game_over.connect(_on_game_over)
	play.won.connect(_start_ending)
	play.earth_exploded.connect(_on_earth_exploded)
	return true


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
	_session.tile_changed.connect(_level_map.set_tile)
	_session.sound_played.connect(_sounds.play)
	_session.lights_changed.connect(_darkness.set_dark)
	_session.elder_message_touched.connect(_on_elder_message)
	_session.set_invincible(_god_mode)
	_darkness.set_dark(_session.is_dark())
	_level_map.show_level(_level, _properties)
	_mode = Mode.LEVEL
	_frame_camera()
	_apply_backdrop()
	_keen.show_body(_session.keen)
	_follow(_keen)


## Shows the world map that [member play] has just started: the done levels
## have their sign already.
func _on_map_started() -> void:
	_clear_screen()
	_level_number = Keen2Files.WORLD_MAP_LEVEL
	_level = play.level
	_session = null
	_map_session = play.map_session
	_map_session.tile_changed.connect(_level_map.set_tile)
	_map_session.sound_played.connect(_sounds.play)
	_darkness.set_dark(false)
	_level_map.show_level(_level, _properties)
	_mode = Mode.MAP
	_frame_camera()
	_apply_backdrop()
	_keen.show_on_map(_map_session.keen)
	_follow(_keen)


## "Keens Left", with a little Keen per life, on the map; a button closes it
## and it closes by itself.
func _show_lives(lives: int) -> void:
	_sounds.play(Sound.Id.KEENS_LEFT)
	MapMessages.show_lives(_window, lives)
	_window_time_left = LIVES_SECONDS
	_buttons_close_window = true


## The last life is gone: GAME OVER, then the high scores.
func _on_game_over() -> void:
	_clear_screen()
	_show_game_over()


## A Vorticon Elder speaks: its message, until Enter closes it. An Elder
## whose message was not found in KEEN2.EXE stays silent.
func _on_elder_message() -> void:
	var index := Keen2LevelPlay.elder_message_index(_level_number)
	if index >= _elder_messages.size() or _elder_messages[index].is_empty():
		return
	var lines := _elder_messages[index].duplicate()
	if not "\n".join(lines).to_upper().contains(ELDER_PROMPT_WORD):
		lines.append_array(["", ELDER_PROMPT])
	_window.show_lines(lines)


## The HUD as [GameScreen] shows it, but never with Keen 1's ship parts.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode in [Mode.MAP, Mode.LEVEL]
		and not _menus.is_open()
	)
	if _hud.visible:
		_hud.show_inventory(_progress.inventory)


## The cheats, on the map and in a level; returns whether [param event] was
## one.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if _mode not in [Mode.MAP, Mode.LEVEL]:
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
