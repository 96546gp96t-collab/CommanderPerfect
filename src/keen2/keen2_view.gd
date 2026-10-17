class_name Keen2View
extends GameScreen
## The Keen 2 game screen that the start screen opens. [GameScreen] draws it
## as it draws Keen 1: the World viewport, the graphics (original, xBRZ or
## HD, F5), widescreen with the [Hud], the camera that follows Keen, and
## short messages. This plays Keen 2's levels with [Keen2LevelPlay].
##
## For now (milestone B3) there is no title, menu or world map: the game
## starts in level 1, or in the level given with [code]-- --level=N[/code]
## (1-16). The exit leads to the next level; after level 16, and after the
## last life, the start screen comes back. Escape goes back to it at once.
## The pictures behind the levels come in milestone B8: no
## [BackdropPictures] are made, so [method GameScreen._apply_backdrop] shows
## none, also not Keen 1's.
##
## Milestone B5 adds what the switches do: the darkness ([Keen2Darkness]),
## the Vorticon Elders' messages (in a [GameWindow], the game waits until
## Enter closes it), and the Tantalus Ray: the screen shakes, then the
## Earth explodes on map 81 ([Keen2EarthExplosion]), then GAME OVER, and
## back to the start screen (milestones B6/B7 add the high scores).
##
## Cheats for testing, as in Keen 1: Shift+N / Shift+P go to the next or
## previous level, Shift+I gives every item, Shift+G toggles god mode.

## What happens after the Tantalus Ray fired.
enum Doom { NONE, SHAKING, EXPLODING }

const MISSING_DATA_MESSAGE := (
	"Keen 2 data not found. Put the files in game_data/keen2 "
	+ "or start with: -- --data-dir-keen2=PATH"
)
const UNREADABLE_MESSAGE := "The Keen 2 files in %s could not be read."
const NOT_PLAYABLE_MESSAGE := "Level %d cannot be played yet: here is level %d"
const LIVES_MESSAGE := "Keens left: %d"
const GAME_OVER_MESSAGE := "Game over"
const FINISHED_MESSAGE := "That was the last level"
## Seconds after game over or the last level before the start screen comes
## back, unless a key is pressed.
const LEAVE_SECONDS := 4.0
## Shown under an Elder's message unless it says so itself.
const ELDER_PROMPT := "Press ENTER:"
const ELDER_PROMPT_WORD := "ENTER"
## How long the screen shakes when the Tantalus Ray fires (Commander Genius:
## 2 seconds), and how far, in game pixels.
const SHAKE_SECONDS := 2.0  # estimate
const SHAKE_PIXELS := 2.0  # estimate
## The GAMEOVER bitmap is 112x24 pixels: 14x3 cells of the window. Without
## it the window says [constant GAME_OVER_TEXT].
const GAME_OVER_BITMAP := "GAMEOVER"
const GAME_OVER_CELLS := Vector2i(14, 3)
const GAME_OVER_TEXT := "GAME OVER"

## The Keen 2 files. Found with [method Keen2Files.locate] unless they are
## set before the view enters the tree (the tests use stand-in files).
var files: GameFiles
## The levels being played; null when the files could not be read.
var play: Keen2LevelPlay
var _time_left := 0.0
var _leave_time_left := 0.0
var _darkness := Keen2Darkness.new()
var _keen_2_sounds := Keen2Sounds.new()
var _elder_messages: Array[PackedStringArray] = []
var _doom := Doom.NONE
var _shake_left := 0.0
var _explosion: Keen2EarthExplosion


func _ready() -> void:
	# The start screen asks every game to open its main menu; Keen 2 has
	# none yet (milestone B7).
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	var first := Keen2LevelPlay.requested_level(OS.get_cmdline_user_args())
	if first != 0 and not Keen2LevelPlay.is_playable(first):
		_show_message(NOT_PLAYABLE_MESSAGE % [first, Keen2Files.FIRST_LEVEL])
		first = 0
	_start_level(first if first != 0 else Keen2Files.FIRST_LEVEL)


func _exit_tree() -> void:
	if _graphics_loader != null:
		_graphics_loader.finish()


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _graphics_loader != null and _graphics_loader.poll():
		_apply_graphics()
	if _mode == Mode.LEVEL and not _window.visible:
		_run_ticks(delta)
	elif _doom == Doom.SHAKING:
		_shake(delta)
	elif _doom == Doom.EXPLODING:
		_run_explosion(delta)
	elif _mode == Mode.GAME_OVER:
		_leave_time_left -= delta
		if _leave_time_left <= 0.0:
			_leave()
	_move_camera_anchor()
	_update_backdrops()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_display_keys(event):
		pass
	elif event.is_action_pressed("menu"):
		_leave()
	elif _mode == Mode.GAME_OVER and _is_any_press(event):
		_leave()
	elif _window.visible and _mode == Mode.LEVEL and event.is_action_pressed("status"):
		_close_window()
	elif _mode != Mode.LEVEL or not _handle_cheat_keys(event):
		return
	get_viewport().set_input_as_handled()


## Runs the ticks for [param delta] seconds and shows the result.
func _run_ticks(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	var views: Array[Rect2] = [_own_view()]
	_session.view_rects = views
	while _time_left >= KeenPhysics.TICK and _mode == Mode.LEVEL:
		_time_left -= KeenPhysics.TICK
		play.step(KeenInput.from_actions())
		_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


func _show_sprites() -> void:
	_keen.show_body(_session.keen)
	_actor_layer.show_actors(_session.actors)


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
	_progress.inventory = Keen2Inventory.new()
	play = Keen2LevelPlay.create(files, _properties, _progress.inventory)
	play.level_started.connect(_on_level_started)
	play.life_lost.connect(_on_life_lost)
	play.game_over.connect(_on_game_over)
	play.finished.connect(_leave_after.bind(FINISHED_MESSAGE))
	play.earth_exploded.connect(_on_earth_exploded)
	return true


func _start_level(number: int) -> void:
	if not play.start(number):
		_show_error("Level %d could not be read from %s." % [number, files.directory])


## Shows the level that [member play] has just started.
func _on_level_started(number: int) -> void:
	_actor_layer.clear()
	_close_window()
	_time_left = 0.0
	_level_number = number
	_level = play.level
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


func _on_life_lost(lives: int) -> void:
	_sounds.play(Sound.Id.KEENS_LEFT)
	_show_message(LIVES_MESSAGE % lives)


func _on_game_over() -> void:
	_sounds.play(Sound.Id.GAME_OVER)
	_leave_after(GAME_OVER_MESSAGE)


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


## The Tantalus Ray fired: the level stands still, Keen is gone, the lights
## are on, and the screen shakes.
func _on_earth_exploded() -> void:
	_mode = Mode.NONE
	_doom = Doom.SHAKING
	_shake_left = SHAKE_SECONDS
	_close_window()
	_darkness.set_dark(false)
	_keen.visible = false


func _shake(delta: float) -> void:
	_shake_left -= delta
	if _shake_left > 0.0:
		var pixel := _screen.size.y / _settings.game_size().y
		var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		_screen.position = _settings.fit_rect(size).position + jitter * SHAKE_PIXELS * pixel
		return
	_fit_screen()
	_start_explosion()


## Map 81: the beam flies to the Earth and it explodes.
func _start_explosion() -> void:
	var space := LevelData.parse(files.read(files.level_file(Keen2Files.SPACE_LEVEL)))
	if space == null:
		_show_game_over()
		return
	_doom = Doom.EXPLODING
	_time_left = 0.0
	_explosion = Keen2EarthExplosion.create(space)
	_explosion.tile_changed.connect(_level_map.set_tile)
	_explosion.sound_played.connect(_sounds.play)
	_explosion.earth_hit.connect(_on_earth_hit)
	_session = null
	_level = space
	_level_number = Keen2Files.SPACE_LEVEL
	_actor_layer.clear()
	_level_map.show_level(space, _properties)
	_frame_camera()
	_camera_anchor.position = _explosion.view_center()
	_follow(_camera_anchor)


func _run_explosion(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	while _time_left >= KeenPhysics.TICK and not _explosion.finished:
		_time_left -= KeenPhysics.TICK
		_explosion.step()
		_actor_layer.show_actors(_explosion.actors)
	_place_sprites(_time_left / KeenPhysics.TICK)
	_camera_anchor.position = _explosion.view_center()
	if _explosion.finished:
		_show_game_over()


## EARTHPOW, alone on the speaker.
func _on_earth_hit() -> void:
	if _keen_2_sounds.has_earth_pow():
		_sounds.stop()
		_keen_2_sounds.play_earth_pow()


## GAME OVER after the Earth exploded, whatever the lives; then the start
## screen.
func _show_game_over() -> void:
	_doom = Doom.NONE
	_actor_layer.clear()
	_sounds.play(Sound.Id.GAME_OVER)
	if _textures.bitmap(GAME_OVER_BITMAP) != null:
		_window.open(GAME_OVER_CELLS)
		_window.put_bitmap(Vector2i.ZERO, GAME_OVER_BITMAP)
	else:
		_window.show_lines(PackedStringArray([GAME_OVER_TEXT]))
	_mode = Mode.GAME_OVER
	_leave_time_left = LEAVE_SECONDS


## Shows [param message] for a while, then goes back to the start screen.
func _leave_after(message: String) -> void:
	_mode = Mode.GAME_OVER
	_show_message(message)
	_leave_time_left = LEAVE_SECONDS


## Back to the start screen. Deferred: this runs inside the handling of a
## key or a frame, and changing the scene takes this one out of the tree at
## once.
func _leave() -> void:
	if not is_processing():
		return
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


## The cheats; returns whether [param event] was one.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("cheat_items"):
		_progress.inventory.give_everything()
		_show_message("Cheat: all keycards and a full raygun")
	elif event.is_action_pressed("cheat_god"):
		_god_mode = not _god_mode
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
func _neighbor_level(offset: int) -> int:
	var count := Keen2Files.LAST_LEVEL - Keen2Files.FIRST_LEVEL + 1
	return Keen2Files.FIRST_LEVEL + posmod(_level_number - Keen2Files.FIRST_LEVEL + offset, count)


## A key or button that was just pressed (not held, not the mouse).
static func _is_any_press(event: InputEvent) -> bool:
	return (
		event.is_pressed()
		and not event.is_echo()
		and (event is InputEventKey or event is InputEventJoypadButton)
	)
