class_name Keen2SpaceScreen
extends GameScreen
## What Keen 2's game screen ([Keen2View], which extends this) shows on map
## 81 and around it: the Tantalus Ray (the screen shakes, the Earth explodes
## with [Keen2EarthExplosion], GAME OVER) and the ending ([Keen2Ending]: the
## flights over map 81, the picture of FINALE.CK2 with its pages, the end
## text). Then [method _finish_game] runs: [Keen2View] shows the high
## scores.
##
## [GameScreen] knows Keen 1's ending in two places; they are overridden
## here: [method _show_picture] (no light in the window) and
## [method _move_camera_anchor] (the ending's flights).

## What happens after the Tantalus Ray fired.
enum Doom { NONE, SHAKING, EXPLODING }

## Seconds that GAME OVER stays, unless a key is pressed.
const GAME_OVER_SECONDS := 4.0
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
var _time_left := 0.0
## Counts down while GAME OVER is shown.
var _game_over_time_left := 0.0
var _darkness := Keen2Darkness.new()
## The same darkness over the pictures behind the level, which are on canvas
## layers of their own (one per player's view).
var _backdrop_darkness := Keen2Darkness.new()
var _backdrop_darkness_2 := Keen2Darkness.new()
var _keen_2_sounds := Keen2Sounds.new()
## What the status screen and the ending show, from the files.
var _texts: Keen2GameData
var _doom := Doom.NONE
var _shake_left := 0.0
var _explosion: Keen2EarthExplosion
var _keen2_ending: Keen2Ending
## The ship of the ending's flights, drawn by the [ActorLayer].
var _flight_sprite := Keen2SpaceSprite.new()


## The Tantalus Ray fired: the level stands still, Keen is gone, the lights
## are on, and the screen shakes.
func _on_earth_exploded() -> void:
	_second_player.stop()
	_mode = Mode.NONE
	_doom = Doom.SHAKING
	_shake_left = SHAKE_SECONDS
	_close_window()
	_set_dark(false)
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


## GAME OVER: after the Earth exploded (whatever the lives) or the last life;
## then [method _finish_game].
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
	_game_over_time_left = GAME_OVER_SECONDS


## All eight cities are saved: the ending, on map 81 first.
func _start_ending() -> void:
	var space := LevelData.parse(files.read(files.level_file(Keen2Files.SPACE_LEVEL)))
	var ship_start := Keen2Ending.ship_start_in(space) if space != null else Vector2.ZERO
	_keen2_ending = Keen2Ending.create(_texts.ending_texts, _texts.end_text, ship_start)
	_keen2_ending.changed.connect(_on_ending_changed)
	_close_window()
	_second_player.stop()
	_session = null
	_map_session = null
	_mode = Mode.ENDING
	_time_left = 0.0
	_on_ending_changed()


## Shows the stage of the ending that has just begun, or its next text.
func _on_ending_changed() -> void:
	if _keen2_ending.is_finished():
		_finish_game()
		return
	var space := _keen2_ending.shows_space()
	if space and _level_number != Keen2Files.SPACE_LEVEL:
		_show_space()
	elif not space and _level_number == Keen2Files.SPACE_LEVEL:
		_level_number = 0
		_actor_layer.clear()
		_level_map.clear()
		_level_map.foreground().clear()
	# Hidden, not only cleared: the twinkling stars are animated tiles, which
	# the map keeps drawing.
	_level_map.visible = space
	_keen.visible = false
	_show_picture(_keen2_ending.shows_picture())
	var lines := _keen2_ending.window_lines()
	if lines.is_empty():
		_window.close()
		return
	var end_text := _keen2_ending.stage == Keen2Ending.Stage.END_TEXT
	_window.at_bottom = not end_text
	_window.show_lines(lines, Keen2Ending.TEXT_WIDTH if end_text else 0)


## Map 81, for the flights of the ending; the camera follows its anchor.
func _show_space() -> void:
	var space := LevelData.parse(files.read(files.level_file(Keen2Files.SPACE_LEVEL)))
	if space == null:
		return
	_level = space
	_level_number = Keen2Files.SPACE_LEVEL
	_actor_layer.clear()
	_level_map.show_level(space, _properties)
	_frame_camera()
	_move_camera_anchor()
	_follow(_camera_anchor)


func _run_ending(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	while _time_left >= KeenPhysics.TICK and _mode == Mode.ENDING:
		_time_left -= KeenPhysics.TICK
		var input := KeenInput.from_actions()
		_keen2_ending.step(input.jump or input.pogo or input.fire, input.vertical)
		if _mode == Mode.ENDING and _keen2_ending.shows_space():
			var flight := _keen2_ending.flight
			_flight_sprite.position = flight.position
			_flight_sprite.frames = PackedInt32Array([flight.sprite])
			var sprites: Array[Actor] = [_flight_sprite]
			_actor_layer.show_actors(sprites)
	_place_sprites(_time_left / KeenPhysics.TICK)


## The picture of FINALE.CK2 in the ending; Keen 2 has no light in the window.
func _show_picture(shown: bool) -> void:
	_picture.visible = shown
	_window_light.visible = false
	if not shown:
		return
	_picture.texture = _textures.finale(_finale_image)
	_picture.position.x = floorf((_settings.game_size().x - FinaleImage.SIZE.x) / 2.0)


## In the ending the view looks where [Keen2Ending] says; otherwise as
## [GameScreen] does.
func _move_camera_anchor() -> void:
	if _mode != Mode.ENDING:
		super()
	elif _keen2_ending != null and _keen2_ending.shows_space():
		_camera_anchor.position = _keen2_ending.view_center(Vector2(_settings.game_size()))


## Darkens the level and the picture behind it ([param dark] true), or
## lights them again.
func _set_dark(dark: bool) -> void:
	for darkness in [_darkness, _backdrop_darkness, _backdrop_darkness_2]:
		darkness.set_dark(dark)


## The game is over (GAME OVER or the ending). [Keen2View] shows the high
## scores; here the start screen comes back.
func _finish_game() -> void:
	_leave()


## Back to the start screen. Deferred: this runs inside the handling of a
## key or a frame, and changing the scene takes this one out of the tree at
## once.
func _leave() -> void:
	if not is_processing():
		return
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)
