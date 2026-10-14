extends Control
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
##   game over    the GAMEOVER bitmap, after the last life
##   ending       once Keen has all four ship parts, he flies home
##                ([EndingSequence])
## After game over and after the ending, a good score goes into the high
## score table; then the title returns. The special maps (81, 90) can be
## looked at freely, for testing.
##
## Escape opens the menu ([MenuController]); Enter shows the status screen;
## the statues and the ship show messages. While a menu or such a
## [GameWindow] is open the game is paused. For testing there are cheats:
## Shift+N / Shift+P go to the next or previous map, Shift+I gives every
## item, Shift+G toggles god mode.
##
## Everything is rendered at its original resolution into the World viewport.
## That picture is then stretched to fit the window, see [DisplaySettings].
##
## Command-line options: [code]-- --level=N[/code] starts in level N
## (80 is the world map) instead of at the title; [code]-- --ending[/code]
## shows the ending straight away.

enum Mode { NONE, TITLE, HIGH_SCORES, MAP, LEVEL, GAME_OVER, ENDING, LOOK }

const LEVEL_OPTION := "--level="
const ENDING_OPTION := "--ending"
## Seconds the title and the high scores each stay before the other one
## comes, while nobody presses a key.
const ATTRACT_SECONDS := 8.0
## Seconds the GAMEOVER bitmap stays, unless a key closes it.
const GAME_OVER_SECONDS := 4.0
const GAME_OVER_BITMAP := "GAMEOVER"
## The GAMEOVER bitmap is 112x24 pixels: 14x3 cells of the window.
const GAME_OVER_CELLS := Vector2i(14, 3)
## Seconds a message such as "Level 3 completed!" stays on the screen.
const MESSAGE_SECONDS := 3.0
## Seconds the "Keens Left" window stays open, unless a button closes it.
const LIVES_SECONDS := 3.0
const MISSING_DATA_MESSAGE := (
	"Keen 1 data not found. Put the files in game_data/keen1 "
	+ "(see game_data/README.md) or start with: -- --data-dir=PATH"
)

var _mode := Mode.NONE
var _files: GameFiles
var _graphics: EgaGraphics
var _properties: TileProperties
var _level_numbers := PackedInt32Array()
## The map or level on the screen, and its data.
var _level_number := 0
var _level: LevelData
var _user_settings := UserSettings.new()
var _settings := _user_settings.display
var _progress := GameProgress.new()
var _session: LevelSession
var _map_session: MapSession
var _ending: EndingSequence
var _time_left := 0.0
## Shown below the status for [constant MESSAGE_SECONDS].
var _message := ""
var _message_time_left := 0.0
## Counts down while the "Keens Left" window is open.
var _lives_time_left := 0.0
## Whether jump, pogo or fire close the open window (the map messages);
## otherwise only Enter does.
var _buttons_close_window := false
## The statue messages and the texts of the ending; null when they could
## not be read.
var _hints: HintTexts
var _ending_texts: EndingTexts
var _god_mode := false
var _sounds := SoundPlayer.new()
var _menus := MenuController.new()
var _textures: GraphicsTextures
var _saves := SaveGames.new()
var _high_scores := HighScores.new()
## The words for the places in the high score table; null when not found.
var _score_texts: ScoreTexts
## The place in the high score table that is waiting for a name, or -1.
var _pending_place := -1
## Counts down on the title and high score screens, and after game over.
var _screen_time_left := 0.0
## Whether the line with the keys is shown while playing (F1).
var _show_help := true

@onready var _screen: TextureRect = %Screen
@onready var _world: SubViewport = %World
@onready var _level_map: LevelMap = %LevelMap
@onready var _free_look: FreeLook = %FreeLook
@onready var _keen: Keen = %Keen
@onready var _mark: SpriteView = %Mark
@onready var _actor_layer: ActorLayer = %ActorLayer
@onready var _camera: LevelCamera = %Camera
@onready var _camera_anchor: Node2D = %CameraAnchor
@onready var _pictures: PictureLayer = %Pictures
@onready var _picture: Sprite2D = %Picture
@onready var _window_light: Sprite2D = %WindowLight
@onready var _window: GameWindow = %Window
@onready var _status_label: Label = %StatusLabel
@onready var _help_label: Label = %HelpLabel


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
	resized.connect(_fit_screen)
	_screen.texture = _world.get_texture()
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

	_level_map.tile_set = LevelTileSet.build(_graphics)
	_keen.set_graphics(_graphics)
	_mark.set_graphics(_graphics)
	_actor_layer.set_graphics(_graphics)
	_textures = GraphicsTextures.create(_graphics)
	_window.set_textures(_textures)
	_pictures.set_textures(_textures)
	_load_texts()
	if _files.has_file(GameFiles.SOUNDS):
		_sounds.load_sounds(SoundFile.load_from(_files))
	if OS.get_cmdline_user_args().has(ENDING_OPTION):
		_progress.inventory.ship_parts.fill(true)
		_enter_map(false)
		return
	var level := _requested_level()
	if level > 0:
		_go_to(level)
	else:
		_show_title()


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


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _menus.is_open():
		_update_status()
		return
	_count_down_lives_window(delta)
	_count_down_screen(delta)
	if _mode == Mode.ENDING or (_mode in [Mode.MAP, Mode.LEVEL] and not _window.visible):
		_play(delta)
	_move_camera_anchor()
	_update_status()


## Runs the ticks for [param delta] seconds and shows the result.
func _play(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	if _session != null:
		var view_size := Vector2(_world.size)
		_session.view_rect = Rect2(
			_camera.get_screen_center_position() - view_size / 2.0, view_size
		)
	var mode := _mode
	while _time_left >= KeenPhysics.TICK and _mode == mode:
		_time_left -= KeenPhysics.TICK
		_tick(KeenInput.from_actions())
	_show_sprites()


## One tick of whatever is going on.
func _tick(input: KeenInput) -> void:
	match _mode:
		Mode.LEVEL:
			_session.step(input)
			if _session.outcome != LevelSession.Outcome.PLAYING:
				_on_level_over(_session.outcome)
		Mode.MAP:
			_map_session.step(input)
			if _map_session.outcome == MapSession.Outcome.ENTER_LEVEL:
				_go_to(_map_session.chosen_level)
		Mode.ENDING:
			_ending.step(input.jump or input.pogo or input.fire, input.vertical)
			if _ending.is_finished():
				_finish_game()


func _show_sprites() -> void:
	_mark.show_sprite(Vector2.ZERO, -1)
	match _mode:
		Mode.LEVEL:
			_keen.show_body(_session.keen)
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


## F1-F3: the help line, widescreen and the shape of the pixels. Returns
## whether [param event] was one of them.
func _handle_display_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("toggle_widescreen"):
		_settings.aspect = (
			DisplaySettings.Aspect.WIDESCREEN
			if _settings.aspect == DisplaySettings.Aspect.ORIGINAL
			else DisplaySettings.Aspect.ORIGINAL
		)
	elif event.is_action_pressed("toggle_pixel_aspect"):
		_settings.correct_pixel_aspect = not _settings.correct_pixel_aspect
	elif event.is_action_pressed("toggle_help"):
		_show_help = not _show_help
		return true
	else:
		return false
	_apply_display_settings()
	_user_settings.save()
	return true


## Keys while the game is being played.
func _handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("status"):
		_on_enter_pressed()
	elif _window.visible and _buttons_close_window and _is_button(event):
		_close_window()
	elif event.is_action_pressed("cheat_items"):
		_progress.inventory.give_everything()
		_show_message("Cheat: all keycards, the pogo stick and a full raygun")
	elif event.is_action_pressed("cheat_god"):
		_god_mode = not _god_mode
		if _session != null:
			_session.keen.invincible = _god_mode
		_show_message("Cheat: god mode " + ("on" if _god_mode else "off"))
	elif event.is_action_pressed("next_level"):
		_go_to(_neighbor_level(1))
	elif event.is_action_pressed("previous_level"):
		_go_to(_neighbor_level(-1))
	else:
		return
	get_viewport().set_input_as_handled()


## A key or button that was just pressed (not held, not the mouse).
static func _is_any_press(event: InputEvent) -> bool:
	return (
		event.is_pressed()
		and not event.is_echo()
		and (event is InputEventKey or event is InputEventJoypadButton)
	)


static func _is_button(event: InputEvent) -> bool:
	return (
		event.is_action_pressed("jump")
		or event.is_action_pressed("pogo")
		or event.is_action_pressed("fire")
	)


## Enter moves on in the ending, closes a window, or opens the status screen.
func _on_enter_pressed() -> void:
	if _mode == Mode.ENDING:
		_ending.confirm()
	elif _window.visible:
		_close_window()
	elif _mode in [Mode.MAP, Mode.LEVEL]:
		StatusScreen.fill(_window, _progress.inventory, _god_mode)


func _close_window() -> void:
	_window.close()
	_lives_time_left = 0.0
	_buttons_close_window = false


func _count_down_lives_window(delta: float) -> void:
	if _lives_time_left <= 0.0:
		return
	_lives_time_left -= delta
	if _lives_time_left <= 0.0:
		_close_window()


func _on_hint_touched() -> void:
	if _hints == null:
		return
	var lines := _hints.for_level(_level_number)
	if lines.is_empty():
		return
	lines.append_array(["", HintTexts.PROMPT])
	_window.show_lines(lines)


func _on_ship_used() -> void:
	if _progress.inventory.has_all_ship_parts():
		_start_ending()
	elif _ending_texts != null:
		MapMessages.show_missing_parts(_window, _ending_texts.missing_parts, _progress.inventory)
		_buttons_close_window = true


## The level asked for on the command line, or 0 to start at the title.
func _requested_level() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(LEVEL_OPTION) and argument.trim_prefix(LEVEL_OPTION).is_valid_int():
			return argument.trim_prefix(LEVEL_OPTION).to_int()
	return 0


func _open_menu() -> void:
	_close_window()
	var in_game := _mode in [Mode.MAP, Mode.LEVEL, Mode.LOOK, Mode.ENDING]
	_menus.open_main(in_game, _can_save())


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


func _load_game(slot: int) -> void:
	var game := _saves.read(slot)
	if game == null:
		_menus.show_message(["That game could not be", "read.  Press a key"])
		return
	_progress = game
	_god_mode = false
	_enter_map(true)


func _on_settings_changed() -> void:
	_sounds.set_enabled(_user_settings.sound_enabled)
	_apply_display_settings()


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
		_menus.open_main(false, false)


## The last life is gone: GAMEOVER, then the high scores.
func _game_over() -> void:
	_sounds.play(Sound.Id.GAME_OVER)
	_mode = Mode.GAME_OVER
	_screen_time_left = GAME_OVER_SECONDS
	_window.open(GAME_OVER_CELLS)
	_window.put_bitmap(Vector2i.ZERO, GAME_OVER_BITMAP)


## The game is over (game over or the ending): a good score asks for a name
## and goes into the table, which is shown.
func _finish_game() -> void:
	_close_window()
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


func _show_error(message: String) -> void:
	_status_label.text = message
	_help_label.visible = false
	push_error(message)


## The map that comes [param offset] places after the current one (for the
## cheats); wraps around.
func _neighbor_level(offset: int) -> int:
	var index := maxi(0, _level_numbers.find(_level_number))
	return _level_numbers[posmod(index + offset, _level_numbers.size())]


## Shows map [param number]: the world map, a level, or a special map.
func _go_to(number: int) -> void:
	if number == GameFiles.WORLD_MAP_LEVEL:
		_enter_map(true)
	elif GameFiles.is_playable_level(number):
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
	_map_session.tile_changed.connect(_level_map.set_tile)
	_map_session.ship_used.connect(_on_ship_used)
	_map_session.sound_played.connect(_sounds.play)
	_mode = Mode.MAP
	_keen.show_on_map(_map_session.keen)
	_follow(_keen)
	if _progress.inventory.has_all_ship_parts():
		_start_ending()
	elif show_lives:
		MapMessages.show_lives(_window, _progress.inventory.lives)
		_sounds.play(Sound.Id.KEENS_LEFT)
		_lives_time_left = LIVES_SECONDS
		_buttons_close_window = true


## Starts an attempt at level [param number].
func _enter_level(number: int) -> void:
	if not _load_map(number):
		return
	_level_map.show_level(_level, _properties)
	var start := _start_cell()
	_session = LevelSession.create(
		_level, _properties, _progress.inventory, Vector2(start * EgaGraphics.TILE_SIZE), number
	)
	_session.tile_changed.connect(_level_map.set_tile)
	_session.hint_touched.connect(_on_hint_touched)
	_session.sound_played.connect(_sounds.play)
	_session.keen.invincible = _god_mode
	_mode = Mode.LEVEL
	_keen.show_body(_session.keen)
	_follow(_keen)


## Shows a special map to look around in.
func _look_at(number: int) -> void:
	if not _load_map(number):
		return
	_level_map.show_level(_level, _properties)
	_mode = Mode.LOOK
	_free_look.move_to((Vector2(_start_cell()) + Vector2(0.5, 0.5)) * EgaGraphics.TILE_SIZE)
	_follow(_free_look)


func _on_level_over(outcome: LevelSession.Outcome) -> void:
	var number := _level_number
	match outcome:
		LevelSession.Outcome.COMPLETED:
			_progress.complete_level(number)
			_show_message("Level %d completed!" % number)
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


func _start_ending() -> void:
	if _ending_texts == null:
		_show_message("The texts of the ending could not be read.")
		return
	_close_window()
	_ending = EndingSequence.create(_ending_texts, _files.read(GameFiles.END_TEXT))
	_ending.changed.connect(_on_ending_changed)
	_mode = Mode.ENDING
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


## Shows or hides the picture of Keen's house, with the light in the
## bedroom window as the conversation asks.
func _show_picture(shown: bool) -> void:
	_picture.visible = shown
	if not shown:
		return
	if _picture.texture == null:
		var image := FinaleImage.load_from(_files)
		if image != null:
			_picture.texture = ImageTexture.create_from_image(image)
	_picture.position.x = floorf((_settings.game_size().x - FinaleImage.SIZE.x) / 2.0)
	var bitmap := _ending.window_bitmap()
	_window_light.visible = not bitmap.is_empty()
	if not bitmap.is_empty():
		_window_light.texture = ImageTexture.create_from_image(_graphics.find_bitmap(bitmap))
		_window_light.position = EndingSequence.WINDOW_POSITION


## Loads map [param number] fresh from its file, so that every item is back.
## With [param area], only those cells of it are kept (see [Backdrops]).
## Returns false (and says why) when it cannot be read.
func _load_map(number: int, area := Rect2i()) -> bool:
	_session = null
	_map_session = null
	_actor_layer.clear()
	_pictures.clear()
	_close_window()
	_picture.visible = false
	_screen.modulate = Color.WHITE
	_level_number = number
	var file_name := GameFiles.level_file_name(number)
	_level = LevelData.parse(_files.read(file_name))
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
	return true


## The cell where Keen starts, or the top left of the map if it has none.
func _start_cell() -> Vector2i:
	var cell := _level.find_info(LevelData.PLAYER_START_INFO)
	if cell.x < 0:
		cell = _level.playable_rect().position
	return cell


## Makes the camera follow [param target]: Keen (or his ship), the
## free-look point, or (for a screen that stands still) its own anchor. The
## others are switched off.
func _follow(target: Node2D) -> void:
	var following_keen := target == _keen
	_keen.visible = following_keen
	_mark.visible = following_keen
	_free_look.set_process(target == _free_look)
	_camera.use_dead_zone(following_keen)
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
			if not _session.keen.is_dead:
				_camera_anchor.position = _session.keen.position + KeenPhysics.SPRITE_SIZE / 2.0
		Mode.MAP:
			_camera_anchor.position = _map_session.keen.center()
		Mode.ENDING:
			var flight := _ending.flight
			if _ending.map_number() == GameFiles.ENDING_LEVEL and flight.scrolling:
				_camera_anchor.position = flight.position
			elif _ending.map_number() == GameFiles.WORLD_MAP_LEVEL and _map_session != null:
				_camera_anchor.position = _map_session.keen.center()


func _apply_display_settings() -> void:
	_world.size = _settings.game_size()
	_window.view_size = _settings.game_size()
	_window.queue_redraw()
	_fit_screen()
	if _level != null:
		_frame_camera()
	if _picture != null and _picture.visible:
		_show_picture(true)


func _frame_camera() -> void:
	var view_size := _settings.game_size()
	var area := LevelMap.playable_pixels(_level)
	_camera.frame(area, view_size)
	_free_look.bounds = LevelCamera.center_range(LevelCamera.limits_for(area, view_size), view_size)
	_free_look.move_to(_free_look.position)


func _fit_screen() -> void:
	var rect := _settings.fit_rect(size)
	_screen.position = rect.position
	_screen.size = rect.size


func _update_status() -> void:
	var playing := _mode in [Mode.MAP, Mode.LEVEL, Mode.LOOK]
	_help_label.visible = _show_help and playing and not _menus.is_open()
	if _level == null:
		return
	if not playing and _mode != Mode.ENDING:
		_status_label.text = _message if _message_time_left > 0.0 else ""
		return
	var game_size := _settings.game_size()
	var lines := PackedStringArray()
	(
		lines
		. append(
			(
				"%s   %s %d x %d, %s pixels"
				% [
					"Ending" if _mode == Mode.ENDING else GameFiles.level_title(_level_number),
					_settings.aspect_name(),
					game_size.x,
					game_size.y,
					"4:3 monitor" if _settings.correct_pixel_aspect else "square",
				]
			)
		)
	)
	if _mode in [Mode.MAP, Mode.LEVEL]:
		lines.append(_inventory_text() + ("   GOD MODE" if _god_mode else ""))
	if _message_time_left > 0.0:
		lines.append(_message)
	_status_label.text = "\n".join(lines)


func _show_message(text: String) -> void:
	_message = text
	_message_time_left = MESSAGE_SECONDS


func _inventory_text() -> String:
	var inventory := _progress.inventory
	var parts := PackedStringArray(
		[
			"Score %d" % inventory.score,
			"Lives %d" % inventory.lives,
			"Ammo %d" % inventory.charges,
		]
	)
	if inventory.has_pogo:
		parts.append("Pogo")
	var cards := PackedStringArray()
	for color: String in TileProperties.KeyColor.keys():
		if inventory.keycards[TileProperties.KeyColor[color]]:
			cards.append(color.capitalize())
	if not cards.is_empty():
		parts.append("Keycards: " + ", ".join(cards))
	var parts_found := inventory.ship_parts.count(true)
	if parts_found > 0:
		parts.append("Ship parts %d/%d" % [parts_found, inventory.ship_parts.size()])
	return "   ".join(parts)
