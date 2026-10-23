class_name GalaxyCoopScreen
extends GalaxyMenuScreen
## Two players on one keyboard in a Galaxy episode (made from Keen 4's
## [Keen4CoopScreen], milestone E11; docs/keen4/gameplay.md and
## docs/keen5/gameplay.md, "Two players"), between [GalaxyMenuScreen] and
## [GalaxyJoinedScreen]:
##   - F7, or Configure > Two Players > Add Player 2 in the control panel
##     ([GalaxyCoopMenuController]), lets player 2 join or leave during a
##     game (not in the title loop or a demo); in a level his Keen (the
##     episode's own: [method GalaxyLevelSession._new_keen]) appears where
##     player 1's is, in his own colours (the shared hue shift: a blue
##     helmet), otherwise from the next level on;
##   - each plays with his own keys ([method KeenInput.for_player]); the
##     screen splits as in Keen 1-4 ([GalaxySplitView]);
##   - either Keen leaving the level completes it, either death ends the
##     attempt, the inventory is shared ([GalaxyLevelSession]);
##   - on the world map the one Keen walks with the keys of both and of
##     playing alone (Keen 3's choice, Keen 4's rule); what he rides there
##     (Keen 5's teleporters and elevators) he rides for both; the choice
##     after a death too;
##   - player 2 is not saved; a save in a level he played in holds the
##     level's start, because his frames cannot be played again by one.
## The episode's view calls [method _set_up_coop] after
## [method GalaxyMenuScreen._set_up_panel].

const PLAYER_COLORS_SHADER := TwoPlayerView.PLAYER_COLORS_SHADER
const PLAYER_2_HUE_SHIFT := TwoPlayerView.PLAYER_2_HUE_SHIFT
const PARTNER_KEY := KEY_F7
const JOINED_MESSAGE := "Player 2 joined"
const JOINS_LATER_MESSAGE := "Player 2 joins in the next level"
const LEFT_MESSAGE := "Player 2 left"
## The two covers each draw in one viewport only (canvas cull masks): the
## first in World, the second in World2.
const COVER_1_LAYER := 1 << 1
const COVER_2_LAYER := 1 << 2

## Whether player 2 plays (from the next level on, when not yet in one).
var _partner_wanted := false
## Player 2 played in the level now: a save holds its start.
var _partner_was_in_level := false
## A saved level is being put back: player 2 joins after its frames.
var _resuming := false
var _split := GalaxySplitView.new()
var _cover_2 := GalaxyViewCover.new()
var _partner_material := ShaderMaterial.new()
## Seconds since the views last glided.
var _split_delta := 0.0

@onready var _split_view: TextureRect = %SplitView
@onready var _camera_anchor_2: Node2D = %CameraAnchor2


## After [method GalaxyMenuScreen._set_up_panel]: player 2's colours and
## the second cover.
func _set_up_coop() -> void:
	_partner_material.shader = PLAYER_COLORS_SHADER
	_partner_material.set_shader_parameter("hue_shift", PLAYER_2_HUE_SHIFT)
	_cover.add_sibling(_cover_2)
	_cover.visibility_layer = COVER_1_LAYER
	_cover_2.visibility_layer = COVER_2_LAYER
	_world.canvas_cull_mask &= ~COVER_2_LAYER
	_world_2.canvas_cull_mask &= ~COVER_1_LAYER


## Whether player 2 plays.
func has_partner() -> bool:
	return _partner_wanted


## Player 2's Keen in the level being played, or null.
func partner_keen() -> GalaxyKeenBody:
	return _played.partner if _played != null else null


## The two views when the screen is shared out (tests).
func split_view() -> GalaxySplitView:
	return _split


## Player 2 joins, or leaves (F7, or the control panel).
func toggle_partner() -> void:
	if not _may_toggle_partner():
		return
	_partner_wanted = not _partner_wanted
	if not _partner_wanted:
		_remove_partner()
		_show_message(LEFT_MESSAGE)
	elif _can_join_now():
		_add_partner()
		_show_message(JOINED_MESSAGE)
	else:
		_show_message(JOINS_LATER_MESSAGE)


## The panel with the Two Players card and the online pages.
func _new_panel() -> GalaxyMenuController:
	return GalaxyCoopMenuController.new()


func _coop_panel() -> GalaxyCoopMenuController:
	return _panel as GalaxyCoopMenuController


## Player 2 may join or leave in a game, not in the title loop, a demo or
## the end ([GalaxyOnlineScreen]: not online).
func _may_toggle_partner() -> bool:
	return not _in_title_loop and not _after_game and _front == Front.NONE and _data != null


## Whether player 2 can come in now: in a level, with player 1 alive.
func _can_join_now() -> bool:
	return _played != null and _played.is_playing() and not _played.player.is_dying()


func _add_partner() -> void:
	var keen := _played.add_player()
	_apply_wide_view()
	_objects.tint(keen, _partner_material)
	_partner_was_in_level = true
	_split.reset()
	_objects.show_objects(_played.world.objects)
	_frame_view()


func _remove_partner() -> void:
	var keen := partner_keen()
	if keen != null:
		_objects.tint(keen, null)
		_played.remove_player()
		_objects.show_objects(_played.world.objects)
	_end_split()
	_frame_view()


## Whether a second Keen plays in the levels ([GalaxyOnlineScreen]: also
## the player who joined online).
func _wants_partner() -> bool:
	return _partner_wanted


## Whether two play here on one screen, which splits (not online).
func _split_active() -> bool:
	return partner_keen() != null


## A level of a game starts: player 2 is in it when he plays.
func _play(session: GalaxyLevelSession, map: GalaxyMap) -> void:
	_end_split()
	_partner_was_in_level = false
	super(session, map)
	var game_level := not _in_title_loop and not _after_game and _front == Front.NONE
	if _wants_partner() and game_level and _recording != null and not _resuming:
		_add_partner()


func _play_map(session: GalaxyMapSession) -> void:
	_end_split()
	super(session)


func _resume(game: GalaxySavedGame) -> void:
	_resuming = true
	super(game)
	_resuming = false


## A loaded level is where it was saved: player 2 comes in now.
func _finish_replay() -> void:
	super()
	if _wants_partner() and partner_keen() == null and _can_join_now():
		_add_partner()


## Player 1 plays with his own keys in a level; on the world map every
## key of either player steers the one Keen.
func _frame_input(tics: int) -> KeenInput:
	if not _partner_wanted or _in_title_loop or _front != Front.NONE:
		return super(tics)
	if _played != null:
		return KeenInput.for_player(0)
	return KeenInput.combine([super(tics), KeenInput.for_player(0), KeenInput.for_player(1)])


func _partner_input() -> KeenInput:
	return KeenInput.for_player(1) if _split_active() else null


## The choice after a death: the keys of playing alone, and of both.
func _choice_input() -> KeenInput:
	if not _partner_wanted:
		return super()
	return KeenInput.combine([super(), KeenInput.for_player(0), KeenInput.for_player(1)])


## F7: player 2 joins or leaves.
func _front_input(event: InputEvent) -> bool:
	var key := event as InputEventKey
	var pressed := key != null and key.pressed and not key.echo and not key.shift_pressed
	if pressed and key.keycode == PARTNER_KEY and not _panel.is_open():
		toggle_partner()
		return true
	return super(event)


func _on_panel_chosen(id: StringName, value: int) -> void:
	if id == MenuController.CHOICE_SECOND_PLAYER:
		toggle_partner()
		_play_map_song(_map_number)
		return
	super(id, value)


## The panel offers player 2 in a game.
func _open_panel() -> void:
	_coop_panel().two_players = _partner_wanted
	_coop_panel().offers_partner = _may_toggle_partner() and in_game()
	super()


## Player 2 is not saved: a level he played in is saved as it began.
func _save_game(slot: int) -> void:
	if _played == null or _recording == null or not _partner_was_in_level:
		super(slot)
		return
	var frames := _recording.frames
	_recording.frames = PackedByteArray()
	super(slot)
	_recording.frames = frames


func _process(delta: float) -> void:
	_split_delta += delta
	super(delta)
	if _split_active():
		_place_split()


func _frame_view() -> void:
	if _split_active():
		_place_split()
	else:
		super()


## While the views are shared out the smooth view is theirs.
func _place_smooth_view() -> void:
	if not _split_active():
		super()


## Puts both cameras where [member _split] says, with their covers and the
## line between the halves.
func _place_split() -> void:
	if _galaxy_camera == null:
		return
	var size := _settings.game_size()
	var exact := _settings.smooth_motion
	var keens: Array[GalaxyKeenBody] = [_played.player, _played.partner]
	var positions: Array[Vector2] = []
	var alive: Array[bool] = []
	for keen in keens:
		var box := keen.box
		var middle := Vector2(box.left + box.right, box.top + box.bottom) / 2.0
		positions.append(middle / GalaxyUnits.PER_PIXEL)
		alive.append(not keen.is_dying())
	var cameras: Array[GalaxyCamera] = [_played.camera, _played.camera_2]
	var areas: Array[Rect2i] = []
	var starts: Array[Vector2] = []
	var looks: Array[float] = []
	for camera in cameras:
		areas.append(camera.area_pixels())
		var left := camera.wide_view_left(size.x, exact)
		starts.append(Vector2(left, camera.view_pixels().y) + Vector2(size) / 2.0)
		looks.append(float(camera.look_pixels()))
	# While the game stands still (a box, the status window) the views do
	# not glide either (Keen 4, D13.2).
	var delta := _split_delta if _game_stepped else 0.0
	_split.update(positions, alive, areas, size, delta, not exact, starts, looks)
	_split_delta = 0.0
	var anchors: Array[Node2D] = [_camera_anchor, _camera_anchor_2]
	var covers: Array[GalaxyViewCover] = [_cover, _cover_2]
	for player in GalaxySplitView.PLAYERS:
		var view := _split.views[player]
		anchors[player].position = Vector2(view.position) + Vector2(size) / 2.0
		_cover_view(covers[player], areas[player], view)
		# What each half shows wakes objects up too (Keen 4, D13.2).
		cameras[player].shown = view
	_camera.reset_smoothing()
	_camera_2.reset_smoothing()
	_show_split(_split.is_split(), size)
	_update_backdrops()


## The second half on the screen, or not, and the line between them.
func _show_split(is_split: bool, size: Vector2i) -> void:
	_split_view.visible = is_split
	_split_view.size = Vector2(size)
	_world_2.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if is_split else SubViewport.UPDATE_DISABLED
	)
	var material := _split_view.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("view_size", Vector2(size))
		material.set_shader_parameter("normal", _split.line_normal)
		material.set_shader_parameter("line_strength", _split.split.line_strength())


## [param cover] covers what [param view] shows beyond [param area].
func _cover_view(cover: GalaxyViewCover, area: Rect2i, view: Rect2i) -> void:
	var picture_rect := Rect2()
	if _backdrop_picture != null:
		picture_rect = LevelBackdrop.picture_rect(
			_backdrop_picture.get_size(),
			_playable_pixels(),
			Vector2(view.position) + Vector2(view.size) / 2.0,
			Vector2(view.size)
		)
		picture_rect.position += Vector2(view.position)
	cover.cover(area, view, _backdrop_picture, picture_rect)


## Back to one view.
func _end_split() -> void:
	if _split_view == null:
		return
	_split_view.visible = false
	_world_2.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_cover_2.cover(Rect2i(), Rect2i())
	_split.reset()
	if _played != null:
		_played.camera.shown = Rect2i()
		if _played.camera_2 != null:
			_played.camera_2.shown = Rect2i()
