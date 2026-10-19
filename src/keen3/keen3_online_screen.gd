class_name Keen3OnlineScreen
extends Keen3MenuScreen
## Two players in Keen 3 (milestone C10), the way Keen 1 and Keen 2 have
## them (docs/two-players.md, docs/online.md): two on one keyboard with the
## split screen, or one hosting and the other joining online through the
## shared [OnlinePlay] and [RemoteGame], with Keen 3's own game id
## ([constant OnlineProtocol.GAME_ID_KEEN_3]) and level files.
##
## On one keyboard, F7 or the menu adds or removes player 2: in a level his
## Keen (blue helmet) plays with his own keys; on the world map there is one
## Keen, which the keys of both steer (also onto Messie, off her, and into a
## teleporter). Each Keen has his own ankh.
##
## Online the host plays as always and tells the player who joined what the
## screen shows ([method _announce_scene]): the map, a level, GAME OVER or
## the ending. Every tick he sends the picture of the level or the map with
## Keen 3's own numbers ([Keen3OnlineState]: the done levels, the ankh time
## of both Keens, Keen 3's own sounds, the map's view and Messie). Tiles,
## the shared sounds, "Keens Left", the ship's message, Mortimer starting
## and ending and the border flash are sent as they happen. The joined
## player's Keen appears next to the host's in a level.
##
## The player who joined draws the host's game with his own Keen 3 files:
## the level with its actors (the halo of an ankh is one), the map with
## Messie and the host's view, Mortimer's boxes and the ending at his own
## pace; on the world map only the host walks. Afterwards he waits at his
## title for the host's next game.

## Online nothing pauses: a window of the game closes by itself after this
## many seconds (as Keen 1's and 2's), or with a key.
const ONLINE_WINDOW_SECONDS := 6.0
const ONLY_HOST_WALKS_MESSAGE := "Only the host can walk on the world map"
const HOSTING_STOPPED_MESSAGE := "Hosting stopped"
const NOT_ONLINE_MESSAGE := "Not while playing online"
const PLAYER_2_LEFT_MESSAGE := "Player 2 left"
const PLAYER_2_JOINED_MESSAGE := "Player 2 joined: player 1 on WASD, player 2 on the arrows"
const PLAYER_2_LATER_MESSAGE := "Player 2 plays along in the levels"
const MOVE_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_up", "move_down", "jump", "pogo", "fire"
]

## (Host) Keen 3's own sounds since the last snapshot.
var _keen3_sounds_to_send := PackedStringArray()
## (Joiner) Keen 3's part of the host's last snapshot; null before one came.
var _remote_state: Keen3OnlineState
## (Joiner) Messie as the host shows her, and the middle of his view of the
## map, at the last two ticks (the view blends between them).
var _remote_messie := MirrorActors.Copy.new()
var _remote_view_from := Vector2.INF
var _remote_view_to := Vector2.INF


## Connects the online play to this screen; call when the screen is set up.
func _connect_online() -> void:
	_menus.offers_online = true
	_online.attach(_menus, _user_settings)
	_online.game_id = OnlineProtocol.GAME_ID_KEEN_3
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


## The files that a player who joins must have too; call once they are read.
func _set_up_online_data() -> void:
	_online.files = files
	_online.fingerprint = LevelFingerprint.of(files)
	_online.set_textures(_textures)


## (Host) what the screen shows now, for the player who joined.
func _announce_scene() -> void:
	if not _online.is_hosting():
		return
	var kind := OnlineMessages.Scene.WAITING
	match _mode:
		Mode.MAP:
			kind = OnlineMessages.Scene.MAP
		Mode.LEVEL:
			kind = OnlineMessages.Scene.LEVEL
		Mode.GAME_OVER:
			kind = OnlineMessages.Scene.GAME_OVER
		Mode.ENDING:
			kind = OnlineMessages.Scene.ENDING
	_online.announce(kind, _level_number, _level)
	if kind == OnlineMessages.Scene.LEVEL and _is_mortimer_speaking():
		_online.send_event(OnlineMessages.Event.MORTIMER, 1)


## (Host) the picture of the tick that just ran, with Keen 3's own numbers.
func _send_tick() -> void:
	if not _online.has_partner():
		return
	var state: Keen3OnlineState = null
	if _mode == Mode.LEVEL:
		state = Keen3OnlineState.of_level(_session, play.progress, _keen3_sounds_to_send)
	elif _mode == Mode.MAP:
		state = Keen3OnlineState.of_map(play.map_session, play.progress, _keen3_sounds_to_send)
	if state == null:
		return
	_keen3_sounds_to_send = PackedStringArray()
	_online.extra = state.to_numbers()
	if _mode == Mode.LEVEL:
		_online.send_level(_session, play.inventory)
	else:
		_online.send_map(_map_session.keen, play.inventory)


## (Host) a message of the game that the other player sees too.
func _send_event(kind: OnlineMessages.Event, value: Variant) -> void:
	if _online.is_hosting():
		_online.send_event(kind, value)


## A tile of the map or level changed: draw it, and let the other player know.
func _on_game_tile_changed(cell: Vector2i, tile: int) -> void:
	_level_map.set_tile(cell, tile)
	_online.send_tile(cell, tile)


## A sound of the game: play it, and let the other player hear it too.
func _play_game_sound(sound: Sound.Id) -> void:
	super(sound)
	_online.send_sound(sound)


## One of Keen 3's own sounds in a level: play it, and send it with the next
## snapshot.
func _on_keen3_sound(sound_name: String) -> void:
	_play_keen3_sound(sound_name)
	if _online.has_partner():
		_keen3_sounds_to_send.append(sound_name)


## A spark or the heart was shot: the border flashes here and for the other
## player.
func _on_border_flashed() -> void:
	_flash_border()
	_send_event(OnlineMessages.Event.BORDER_FLASH, 0)


## "Keens Left", for the other player too.
func _show_lives(lives: int) -> void:
	_send_event(OnlineMessages.Event.KEENS_LEFT, lives)
	super(lives)


func _show_game_over() -> void:
	super()
	_announce_scene()


## Level 16 is won: the ending, without player 2 (one Keen in the hall).
func _start_ending() -> void:
	if _second_player != null:
		_second_player.stop()
	super()
	_announce_scene()


func _start_mortimer() -> void:
	super()
	_send_event(OnlineMessages.Event.MORTIMER, 1)


## While Mortimer speaks the level stands still; the host keeps sending its
## picture, so that the player who joined sees the Keens under the boxes.
func _run_mortimer(delta: float) -> void:
	super(delta)
	if _mode == Mode.LEVEL:
		_send_tick()


func _end_mortimer() -> void:
	super()
	_send_event(OnlineMessages.Event.MORTIMER, 0)


func _show_screen(mode: Mode, area: Rect2i) -> bool:
	var shown := super(mode, area)
	_announce_scene()
	return shown


## Online nothing pauses, so a window of the game closes by itself (or with
## a key).
func _close_by_itself_online() -> void:
	if _online.is_together():
		_window_time_left = ONLINE_WINDOW_SECONDS


func _open_main_menu() -> void:
	_menus.online = _online.menu_info()
	super()


func _on_menu_chosen(id: StringName, slot: int) -> void:
	match id:
		MenuController.CHOICE_LEAVE_ONLINE:
			_leave_online()
		MenuController.CHOICE_HOST, MenuController.CHOICE_JOIN_IP, MenuController.CHOICE_JOIN_STEAM:
			if _two_players:
				_toggle_second_player()
			_online.handle_choice(id, slot)
		_:
			if not _online.handle_choice(id, slot):
				super(id, slot)


## Player 2 joins or leaves on the keyboard. In a level his Keen appears
## where player 1's is; on the map he plays along from the next level on.
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


## A level has started: player 2 on the keyboard, or the one online, plays
## along.
func _add_second_keen() -> void:
	if _two_players:
		_second_player.start(_session, _session.keen.position, _camera_anchor.position)
	elif _online.has_partner():
		_add_online_partner()


## The buttons of this tick: one player's, or with two players each one's
## own keys (in a level), and on the map the keys of both and of playing
## alone, which all steer the one Keen there. Online the other player's
## buttons arrive over the network.
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


## (Host) hosting has begun: the other player needs a game to join, so from
## the title a new one starts.
func _on_hosting_started() -> void:
	if _mode in [Mode.MAP, Mode.LEVEL, Mode.ENDING]:
		_announce_scene()
	else:
		_start_game(null)


## Stops hosting, or leaves the host's game.
func _leave_online() -> void:
	_online.leave()
	_on_online_stopped()
	if _mode != Mode.TITLE:
		_show_message(HOSTING_STOPPED_MESSAGE)


## (Host) the other player joined: in a level his Keen appears at once, and
## while Mortimer speaks he hears him too.
func _on_partner_joined(_player_name: String) -> void:
	if _mode != Mode.LEVEL or _session == null:
		return
	if not _second_player.is_active():
		_add_online_partner()
	if _is_mortimer_speaking():
		_send_event(OnlineMessages.Event.MORTIMER, 1)


## (Host) the player who joined plays along in this level: his Keen appears
## next to the host's.
func _add_online_partner() -> void:
	var at := OnlineSpawn.beside(_session, _session.keen)
	_second_player.start(_session, at, _camera.get_screen_center_position(), false)


func _drop_online_partner(_player_name := "") -> void:
	if _second_player.is_active() and not _second_player.is_split_screen():
		_second_player.stop()


## (Joiner) the host let us in: our own game makes way for his.
func _on_joined_online(_host_name: String) -> void:
	if _two_players:
		_toggle_second_player()
	_joined_online = true
	_progress = Keen3Progress.new()
	_remote_state = null
	_god_mode = false
	_show_title()


## The online game is over (or never began): a player who had joined is
## back at his own title.
func _on_online_stopped() -> void:
	_drop_online_partner()
	if _joined_online:
		_joined_online = false
		_remote_state = null
		_progress = play.progress
		_show_title()


## (Joiner) the host shows another scene. While the joined player watches
## the ending at his own pace, the host's GAME OVER and title after it do
## not cut it short: his own ending ends at his title.
func _on_remote_scene(kind: OnlineMessages.Scene, number: int, tiles: PackedInt32Array) -> void:
	var after_ending := kind in [OnlineMessages.Scene.GAME_OVER, OnlineMessages.Scene.WAITING]
	if _mode == Mode.ENDING and after_ending:
		return
	match kind:
		OnlineMessages.Scene.MAP, OnlineMessages.Scene.LEVEL:
			_show_remote_map(kind, number, tiles)
		OnlineMessages.Scene.GAME_OVER:
			_clear_screen()
			_show_game_over()
		OnlineMessages.Scene.ENDING:
			# Each player watches the ending at his own pace.
			_clear_screen()
			_start_ending()
		_:
			_show_title()


## (Joiner) the host's map or level [param number], from our own files,
## with the [param tiles] that changed at the host.
func _show_remote_map(kind: OnlineMessages.Scene, number: int, tiles: PackedInt32Array) -> void:
	var level := LevelData.parse(files.read(files.level_file(number)))
	if level == null:
		_show_message("%s could not be read." % files.level_file(number))
		return
	_clear_screen()
	_level = level
	_level_number = number
	_remote_view_from = Vector2.INF
	_remote_view_to = Vector2.INF
	_frame_camera()
	_apply_backdrop()
	_remote.begin(kind, _level, _properties, tiles)
	_mode = Mode.REMOTE
	_follow(_keen)
	# On the map the camera shows the host's view exactly, as his own does.
	_camera.follow_exactly(kind == OnlineMessages.Scene.MAP)


## (Joiner) a message of the host's game.
func _on_remote_event(kind: OnlineMessages.Event, value: Variant) -> void:
	if _mode != Mode.REMOTE:
		return
	match kind:
		OnlineMessages.Event.KEENS_LEFT:
			_show_lives(value)
		OnlineMessages.Event.MESSAGE:
			_show_message(value)
		OnlineMessages.Event.SHIP_MESSAGE:
			_show_ship_message(value)
		OnlineMessages.Event.MORTIMER:
			if value != 0 and not _is_mortimer_speaking():
				_start_mortimer()
			elif value == 0 and _is_mortimer_speaking():
				_end_mortimer()
		OnlineMessages.Event.BORDER_FLASH:
			_flash_border()


## (Joiner) runs the ticks for [param delta] seconds: sends our buttons and
## shows the host's picture.
func _run_remote(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	var input := KeenInput.new() if _menus.is_open() else KeenInput.from_actions()
	while _time_left >= KeenPhysics.TICK and _mode == Mode.REMOTE:
		_time_left -= KeenPhysics.TICK
		var snapshot := _online.client_tick(input, _own_view())
		if snapshot == null:
			continue
		_progress.inventory = snapshot.inventory
		_show_remote_state(Keen3OnlineState.from_numbers(snapshot.extra))
		if _remote.show(snapshot):
			_follow(_keen)
			_camera.follow_exactly(_remote.kind == OnlineMessages.Scene.MAP)
	_place_sprites(_time_left / KeenPhysics.TICK)


## (Joiner) Keen 3's part of a snapshot: the done levels, Keen 3's own
## sounds, and on the map Messie and the host's view.
func _show_remote_state(state: Keen3OnlineState) -> void:
	if state == null:
		return
	_remote_state = state
	for number in state.completed_levels():
		_progress.complete_level(number)
	for sound_name in state.sounds:
		_play_keen3_sound(sound_name)
	if _remote.kind != OnlineMessages.Scene.MAP:
		return
	_remote_view_from = _remote_view_to if _remote_view_to.is_finite() else state.view_center
	_remote_view_to = state.view_center
	var shown: Array[Actor] = []
	if state.messie_sprite >= 0:
		_remote_messie.position = state.messie_position
		_remote_messie.sprite = state.messie_sprite
		shown.append(_remote_messie)
	_actor_layer.show_actors(shown)


## (Joiner) where the host's view of the map is now, [param blend] of the way
## from the last tick but one to the last; INF before the host sent it.
func _remote_view_center(blend: float) -> Vector2:
	if not _remote_view_to.is_finite():
		return Vector2.INF
	return _remote_view_from.lerp(_remote_view_to, blend)


## (Joiner) the time of his own Keen's ankh (player 2's at the host), or -1
## when it does not run.
func _remote_ankh_seconds() -> int:
	if _remote_state == null or _remote_state.ankh_ticks[1] <= 0:
		return -1
	return _remote_state.ankh_seconds(1)


## (Joiner) keys while watching the host's world map: only the host walks.
## Returns whether [param event] was one.
func _handle_joined_input(event: InputEvent) -> bool:
	if _mode != Mode.REMOTE or _remote.kind != OnlineMessages.Scene.MAP:
		return false
	for action in MOVE_ACTIONS:
		if event.is_action_pressed(action):
			_show_message(ONLY_HOST_WALKS_MESSAGE)
			return true
	return false


## Online, in a level: the arrow toward the other player when he is out of
## sight.
func _point_arrow() -> void:
	var to_partner := _mode == Mode.LEVEL and _online.has_partner() and _second_player.is_active()
	var to_host := _mode == Mode.REMOTE and _remote.kind == OnlineMessages.Scene.LEVEL
	var shown := not _menus.is_open()
	_remote.point_arrow(_own_view(), to_partner and shown, to_host and shown)


## One of the ship's four messages, [param index]; [Keen3View] shows it.
func _show_ship_message(_index: int) -> void:
	pass
