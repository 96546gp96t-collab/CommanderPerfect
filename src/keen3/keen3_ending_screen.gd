class_name Keen3EndingScreen
extends Keen3SceneScreen
## The scenes of Keen 3's game screen that are no plain level (milestone
## C7); [Keen3View] extends it and plays the game.
##   Mortimer   when level 16 starts, MORTIMER plays and his nine boxes are
##              typed ([Keen3Mortimer]) before Keen can move; Escape or a
##              button skips them
##   flash      a destroyed spark or heart flashes a thin frame around the
##              picture ([Keen3BorderFlash], the original's EGA border)
##   ending     after level 16 ([Keen3Ending]): map 81 with a Vorticon and
##              Keen, the four pages, the camera flashes, FINALE.CK3 with
##              its box, the end text (keensleft to its end, then
##              MORTIMER, as Choco `CVort3_draw_win`); then GAME OVER and
##              the high scores ([Keen3MenuScreen], milestone C8)
## As Keen 2's [Keen2SpaceScreen], it overrides the two places where
## [GameScreen] knows Keen 1's ending: [method _show_picture] and
## [method _move_camera_anchor]. Map 81 is narrower than a widescreen view:
## black bars show, never its border (the camera keeps to the playable
## area); the picture is hidden behind the map layer, which is hidden while
## the picture shows.

## What the files hold for the screens (texts, Mortimer, the ending).
var _data: Keen3GameData
var _mortimer: Keen3Mortimer
var _keen3_ending: Keen3Ending
var _border_flash := Keen3BorderFlash.new()
var _fade := Keen3ScreenTint.create(false)
var _camera_flash := Keen3ScreenTint.create(true)
## The Vorticon and Keen in the hall of the ending.
var _hall_sprites: Array[Actor] = []
## The box and the number of letters on the screen, so that a typed box is
## only drawn again when it changes.
var _shown_box: Keen3TypedBoxes.Box
var _shown_letters := -1
## Seconds until MORTIMER starts under the end text; negative when it does
## not wait.
var _mortimer_sound_in := -1.0


## Puts the border flash over the screen (under the messages) and the fade
## and the camera flash over everything the game draws.
func _set_up_effects() -> void:
	add_child(_border_flash)
	move_child(_border_flash, _screen.get_index() + 1)
	var ui := _window.get_parent()
	ui.add_child(_fade)
	ui.add_child(_camera_flash)
	_fade.visible = false
	_camera_flash.visible = false


## Keeps the effects on the picture, every frame.
func _update_effects() -> void:
	_border_flash.picture_rect = Rect2(_screen.position, _screen.size)
	for tint: Keen3ScreenTint in [_fade, _camera_flash]:
		tint.view_size = _settings.game_size()
	var ending := _keen3_ending if _mode == Mode.ENDING else null
	var darkness := 1.0 - ending.brightness() if ending != null else 0.0
	_fade.show_color(Color(0, 0, 0, darkness))
	var lit := ending != null and ending.flashing
	_camera_flash.show_color(Keen3ScreenTint.FLASH_LIGHT if lit else Color.TRANSPARENT)


## The border blinks: a spark or the heart was shot.
func _flash_border() -> void:
	_border_flash.flash()


## Level 16 has started: Mortimer speaks first.
func _start_mortimer() -> void:
	var sound_seconds := _keen_3_sounds.seconds(Keen3Sounds.MORTIMER)
	_mortimer = Keen3Mortimer.create(_data.mortimer_messages, sound_seconds)
	_play_keen3_sound(Keen3Sounds.MORTIMER)


## Whether Mortimer is still speaking (the level waits).
func _is_mortimer_speaking() -> bool:
	return _mortimer != null


func _run_mortimer(delta: float) -> void:
	_mortimer.advance(delta)
	if _mortimer.is_finished():
		_end_mortimer()
	else:
		_show_typed_box(_mortimer.current_box(), _mortimer.boxes)


## Escape, Space or a button: the rest of Mortimer's boxes are skipped.
func _skip_mortimer() -> void:
	_mortimer.skip()
	_end_mortimer()


func _end_mortimer() -> void:
	_mortimer = null
	_show_typed_box(null, null)


## Draws [param box] of [param boxes] as far as it is typed, when that
## changed; no box closes the window.
func _show_typed_box(box: Keen3TypedBoxes.Box, boxes: Keen3TypedBoxes) -> void:
	var letters := boxes.typed if box != null else -1
	if box == _shown_box and letters == _shown_letters:
		return
	_shown_box = box
	_shown_letters = letters
	var window := _window as Keen3Window
	if box == null or window == null:
		_window.close()
		return
	window.open_at(box.cell, box.size)
	var lines := boxes.visible_lines()
	for row in lines.size():
		window.put_text(Vector2i(0, row), lines[row])


## Level 16 is won (or --ending): the ending, in the hall of map 81 first.
func _start_ending() -> void:
	_mortimer = null
	_close_window()
	_session = null
	_map_session = null
	_mode = Mode.ENDING
	_keen3_ending = Keen3Ending.create(_data.ending_pages, _data.the_end, _data.end_text)
	_keen3_ending.changed.connect(_on_ending_changed)
	_keen3_ending.tile_changed.connect(_set_hall_tile)
	_keen3_ending.flashed.connect(_play_game_sound.bind(Sound.Id.CLICK))
	_keen3_ending.end_text_started.connect(_start_end_text_sounds)
	_show_hall()
	_on_ending_changed()


## Map 81 with the view's corner at tile (2,2), the Vorticon and Keen.
func _show_hall() -> void:
	_actor_layer.clear()
	_hall_sprites.clear()
	var hall := LevelData.parse(files.read(files.level_file(Keen3Files.ENDING_LEVEL)))
	if hall == null:
		push_error("Map %d could not be read." % Keen3Files.ENDING_LEVEL)
		return
	_level = hall
	_level_number = Keen3Files.ENDING_LEVEL
	_level_map.show_level(hall, _properties)
	_level_map.visible = true
	_apply_backdrop()
	_frame_camera()
	_follow(_camera_anchor)
	_camera.follow_exactly(true)
	_move_camera_anchor()
	_camera.reset_smoothing()
	var tile := float(EgaGraphics.TILE_SIZE)
	for sprite in [
		[Keen3Ending.VORTICON_CELL, Keen3Ending.VORTICON_SPRITE],
		[Keen3Ending.KEEN_CELL, Keen3Ending.KEEN_SPRITE],
	]:
		_hall_sprites.append(
			Keen2SpaceSprite.flying(sprite[0] * tile, PackedInt32Array([sprite[1]]), 1)
		)
	_actor_layer.show_actors(_hall_sprites)
	_place_sprites(1.0)


## A camera flash changes a tile of the hall.
func _set_hall_tile(cell: Vector2i, tile: int) -> void:
	if _level == null or _level_number != Keen3Files.ENDING_LEVEL:
		return
	_level.set_tile(cell, tile)
	_level_map.set_tile(cell, tile)


func _run_ending(delta: float) -> void:
	_keen3_ending.advance(delta, KeenInput.from_actions().vertical)
	if _mortimer_sound_in < 0.0:
		return
	_mortimer_sound_in -= delta
	if _mortimer_sound_in <= 0.0:
		_mortimer_sound_in = -1.0
		_play_keen3_sound(Keen3Sounds.MORTIMER)


## The end text begins: keensleft plays to its end, then MORTIMER (Choco
## `CVort3_draw_win`; the original shows the text meanwhile).
func _start_end_text_sounds() -> void:
	var keens_left := Sound.FILE_NAMES[Sound.Id.KEENS_LEFT]
	_play_game_sound(Sound.Id.KEENS_LEFT)
	_mortimer_sound_in = _keen_3_sounds.seconds_of(keens_left)


## Shows the stage of the ending that has just begun, or its text.
func _on_ending_changed() -> void:
	if _keen3_ending.is_finished():
		_after_ending()
		return
	var hall := _keen3_ending.shows_hall()
	# Hidden, not only covered: the picture lies behind the map's tiles.
	_level_map.visible = hall
	if not hall:
		_actor_layer.clear()
	_show_picture(_keen3_ending.shows_picture())
	if _keen3_ending.stage == Keen3Ending.Stage.END_TEXT:
		_shown_box = null
		_window.show_lines(_keen3_ending.end_text_lines(), Keen3Ending.TEXT_WIDTH)
		return
	var typing := (
		_keen3_ending.stage in [Keen3Ending.Stage.HALL_BOXES, Keen3Ending.Stage.PICTURE_BOX]
	)
	var boxes := _keen3_ending.boxes
	_show_typed_box(boxes.current() if typing else null, boxes)


## The ending is over: GAME OVER on a black screen, then the high scores.
func _after_ending() -> void:
	_keen3_ending = null
	_mortimer_sound_in = -1.0
	_level_map.visible = false
	_actor_layer.clear()
	_show_picture(false)
	_show_typed_box(null, null)
	_show_game_over()


## The picture of FINALE.CK3; Keen 3 has no light in a window.
func _show_picture(shown: bool) -> void:
	_picture.visible = shown
	_window_light.visible = false
	if not shown:
		return
	_picture.texture = _textures.finale(_finale_image)
	_picture.position.x = floorf((_settings.game_size().x - FinaleImage.SIZE.x) / 2.0)


## In the ending the view stands with its corner at tile (2,2) of map 81;
## otherwise as [GameScreen] has it.
func _move_camera_anchor() -> void:
	if _mode != Mode.ENDING:
		super()
		return
	var corner := Vector2(Keen3Ending.VIEW_CORNER * EgaGraphics.TILE_SIZE)
	_camera_anchor.position = corner + Vector2(_settings.game_size()) / 2.0
