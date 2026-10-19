class_name Keen3SceneScreen
extends GameScreen
## The generic part of Keen 3's game screen ([Keen3View] extends it): what
## [GameScreen] needs before anything is shown, reading the Keen 3 files
## ([Keen3GameData]) and getting the drawing ready, the windows that the
## whole game shows ("Keens Left", GAME OVER), Keen 3's own sounds
## ([Keen3Sounds]) and going back to the start screen.
##
## Planned like Keen 2's chain (docs/keen3/architecture.md): on this class
## [Keen3EndingScreen] has the scenes that are no plain level (Mortimer, the
## border flash, the ending; milestone C7), [Keen3MenuScreen] the title, the
## high scores and the menus (C8), and [Keen3View] plays the game. Generic
## parts are copied from Keen 2's screens, which are not used: they hold
## Keen 2 types and numbers.
##
## Every sound goes through [method _play_game_sound] or
## [method _play_keen3_sound], so that the shared player and Keen 3's own
## speaker sound as the one speaker of the original ([Keen3Sounds]).

const MISSING_DATA_MESSAGE := (
	"Keen 3 data not found. Put the files in game_data/keen3 "
	+ "or start with: -- --data-dir-keen3=PATH"
)
const UNREADABLE_MESSAGE := "The Keen 3 files in %s could not be read."
## The GAMEOVER bitmap (112x24, 14x3 cells of the window), drawn bare over
## the level as the original does (no window around it, seen in js-dos in
## C1). Without it a window says [constant GAME_OVER_TEXT].
const GAME_OVER_BITMAP := "GAMEOVER"
const GAME_OVER_CELLS := Vector2i(14, 3)
const GAME_OVER_TEXT := "GAME OVER"
## How long GAME OVER stays, unless a key is pressed (seen in js-dos: 5.27 s).
const GAME_OVER_SECONDS := 5.27
## "Keens Left": a window of 16x4 cells with the title in row 0 from column
## 3 and a little Keen per life in rows 1-2, two cells apart from column 1
## (seen in js-dos in C1: box x 88-231, text at x 120, Keens from x 104). It
## closes by itself after 0.87 s (seen), or with a button.
const LIVES_TITLE := "Keens Left"
const LIVES_CELLS := Vector2i(16, 4)
const LIVES_TITLE_COLUMN := 3
const LIFE_FIRST_CELL := Vector2i(1, 1)
const LIFE_CELLS := 2
## At most six little Keens (Choco `CVort_show_keens_left`).
const MAX_LIVES_SHOWN := 6
const LIVES_SECONDS := 0.87
## Keen 3's map Keen looking at the player (MAPKEEND1), for each life.
const LIFE_SPRITE := Keen3Hud.KEEN_3_LIFE_SPRITE

## The Keen 3 files. Found with [method Keen3Files.locate] unless they are
## set before the view enters the tree.
var files: GameFiles
var _time_left := 0.0
## Counts down while GAME OVER is shown.
var _game_over_time_left := 0.0
var _keen_3_sounds := Keen3Sounds.new()


func _exit_tree() -> void:
	if _graphics_loader != null:
		_graphics_loader.finish()


## What [GameScreen] needs before anything is shown: the settings, the
## sounds, and the World viewport stretched over the window.
func _set_up_screen() -> void:
	_user_settings = UserSettings.load_from()
	_settings = _user_settings.display
	add_child(_sounds)
	_sounds.enabled = _user_settings.sound_enabled
	add_child(_keen_3_sounds)
	_keen_3_sounds.enabled = _user_settings.sound_enabled
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


## Reads the Keen 3 files and gets the drawing ready. Returns the data, or
## null (and shows why) when they cannot be read. The pictures behind the
## levels are Keen 3's own, for the levels with sky (milestone C9,
## [Keen3BackdropPictures]); Keen 1's and 2's are never shown.
func _load_data() -> Keen3GameData:
	if files == null:
		files = Keen3Files.locate()
	if files == null:
		_show_error(MISSING_DATA_MESSAGE)
		return null
	var data := Keen3GameData.load_from(files)
	if data == null:
		_show_error(UNREADABLE_MESSAGE % files.directory)
		return null
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
	_set_up_hud_icons()
	_backdrop_pictures = Keen3BackdropPictures.for_game(files, _properties, _graphics.tiles)
	_graphics_loader = GraphicsLoader.create(files, _graphics, _finale_image)
	_menus.hd_available = HdPack.exists(files)
	_apply_graphics()
	_sounds.load_sounds(data.sounds)
	_keen_3_sounds.load_sounds(data.sounds)
	return data


## The HUD's pictures of the raygun, the keycards and the ankh: the first
## tile with that behaviour.
func _set_up_hud_icons() -> void:
	_hud.raygun_tile = Keen2Icons.raygun(_properties)
	_hud.keycard_icons = Keen2Icons.keycards(_properties)
	var keen_3_hud := _hud as Keen3Hud
	if keen_3_hud != null:
		keen_3_hud.ankh_tile = Keen2Icons.first_tile_with(_properties, Keen3Behavior.ANKH)


## Plays one of Keen 3's own sounds ([Keen3Sounds]) alone.
func _play_keen3_sound(sound_name: String) -> void:
	if _keen_3_sounds.play(sound_name):
		_sounds.stop()


## Plays a sound of the shared player, unless one of Keen 3's own sounds
## with a higher priority is playing (which it otherwise cuts off).
func _play_game_sound(sound: Sound.Id) -> void:
	if _keen_3_sounds.give_way_to(Sound.FILE_NAMES.get(sound, "")):
		_sounds.play(sound)


## "Keens Left", with a little Keen per life; a button closes it and it
## closes by itself. The game waits meanwhile.
func _show_lives(lives: int) -> void:
	_play_game_sound(Sound.Id.KEENS_LEFT)
	_window.open(LIVES_CELLS)
	_window.put_text(Vector2i(LIVES_TITLE_COLUMN, 0), LIVES_TITLE)
	for life in clampi(lives, 0, MAX_LIVES_SHOWN):
		_window.put_sprite(LIFE_FIRST_CELL + Vector2i(life * LIFE_CELLS, 0), LIFE_SPRITE)
	_window_time_left = LIVES_SECONDS
	_buttons_close_window = true


## The game is over (the last life is gone, or the ending is over): GAME
## OVER over what the screen shows, for [constant GAME_OVER_SECONDS] or
## until a key; [Keen3MenuScreen] then shows the high scores.
func _show_game_over() -> void:
	_actor_layer.clear()
	_play_game_sound(Sound.Id.GAME_OVER)
	if _textures.bitmap(GAME_OVER_BITMAP) != null:
		_window.open(GAME_OVER_CELLS)
		_window.framed = false
		_window.put_bitmap(Vector2i.ZERO, GAME_OVER_BITMAP)
	else:
		_window.show_lines(PackedStringArray([GAME_OVER_TEXT]))
	_mode = Mode.GAME_OVER
	_game_over_time_left = GAME_OVER_SECONDS


## Back to the start screen. Deferred: this runs inside the handling of a
## key or a frame, and changing the scene takes this one out of the tree at
## once.
func _leave() -> void:
	if not is_processing():
		return
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


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
