class_name Keen2OnlineScreen
extends Keen2MenuScreen
## Playing Keen 2 online (milestone B9), the way Keen 1 does
## (docs/online.md): one hosts, the other joins, through the shared
## [OnlinePlay] and [RemoteGame]. Keen 2 has its own game id
## ([constant OnlineProtocol.GAME_ID_KEEN_2]), so a Keen 1 host and a Keen 2
## player never meet, and its own level files in the fingerprint.
##
## The host plays as always and tells the player who joined what the screen
## shows ([method _announce_scene]): the map, a level, GAME OVER, the ending,
## or the Earth exploding (Keen 2's own scene). Every tick he sends the
## picture of the level or the map, with the saved cities as the progress
## bits; tiles, sounds, the "Keens Left" window, an Elder's message and the
## lights going off or on are sent as they happen. The joined player's Keen
## appears next to the host's in a level and plays with the joiner's buttons.
##
## The player who joined draws the host's game with his own Keen 2 files:
## the map or level with the changed tiles, the Keens and actors of every
## tick, the darkness, the windows. On the world map only the host walks.
## The Earth exploding and the ending run on his own screen; afterwards he
## waits at his title for the host's next game.

## Online nothing pauses: a window of the game closes by itself after this
## many seconds (as Keen 1's), or with a button.
const ONLINE_WINDOW_SECONDS := 6.0
const ONLY_HOST_WALKS_MESSAGE := "Only the host can walk on the world map"
const HOSTING_STOPPED_MESSAGE := "Hosting stopped"
const NOT_ONLINE_MESSAGE := "Not while playing online"
const MOVE_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_up", "move_down", "jump", "pogo", "fire"
]

## (Joiner) the cities the host has saved, as the progress bits he sends.
var _remote_cities := 0


## Connects the online play to this screen; call when the screen is set up.
func _connect_online() -> void:
	_online.attach(_menus, _user_settings)
	_online.game_id = OnlineProtocol.GAME_ID_KEEN_2
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
		Mode.NONE:
			if _doom != Doom.NONE:
				kind = OnlineMessages.Scene.EARTH_EXPLODES
	_online.progress_bits = _city_bits(play.progress)
	_online.announce(kind, _level_number, _level)
	if kind == OnlineMessages.Scene.LEVEL and _darkness.is_dark():
		_online.send_event(OnlineMessages.Event.LIGHTS, 1)


## (Host) the picture of the tick that just ran.
func _send_tick() -> void:
	if not _online.is_hosting():
		return
	_online.progress_bits = _city_bits(play.progress)
	if _mode == Mode.LEVEL:
		_online.send_level(_session, play.inventory)
	elif _mode == Mode.MAP:
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
	_sounds.play(sound)
	_online.send_sound(sound)


## The lights of the level went off or on, here and for the other player.
func _on_lights_changed(dark: bool) -> void:
	_set_dark(dark)
	_send_event(OnlineMessages.Event.LIGHTS, 1 if dark else 0)


## Online nothing pauses, so a window of the game closes by itself (or with
## a button).
func _close_by_itself_online() -> void:
	if _online.is_together():
		_window_time_left = ONLINE_WINDOW_SECONDS
		_buttons_close_window = true


## The saved cities of [param progress] as bits, first city lowest.
static func _city_bits(progress: Keen2Progress) -> int:
	var bits := 0
	var saved := progress.saved_cities()
	for city in saved.size():
		bits |= (1 << city) if saved[city] else 0
	return bits


## The progress the status screen shows: the game played here, or for the
## player who joined, what the host sends.
func _status_progress() -> Keen2Progress:
	if not _joined_online:
		return play.progress
	var progress := Keen2Progress.new(_progress.inventory)
	for city in Keen2Progress.CITY_LEVELS.size():
		if _remote_cities & (1 << city) != 0:
			progress.complete_level(Keen2Progress.CITY_LEVELS[city])
	return progress


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


## (Host) the other player joined: in a level his Keen appears at once.
func _on_partner_joined(_player_name: String) -> void:
	if _mode == Mode.LEVEL and _session != null and not _second_player.is_active():
		_add_online_partner()


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
	_progress = Keen2Progress.new()
	_remote_cities = 0
	_god_mode = false
	_show_title()


## The online game is over (or never began): a player who had joined is
## back at his own title.
func _on_online_stopped() -> void:
	_drop_online_partner()
	if _joined_online:
		_joined_online = false
		_progress = play.progress
		_show_title()


## (Joiner) the host shows another scene.
func _on_remote_scene(kind: OnlineMessages.Scene, number: int, tiles: PackedInt32Array) -> void:
	match kind:
		OnlineMessages.Scene.MAP, OnlineMessages.Scene.LEVEL:
			_show_remote_map(kind, number, tiles)
		OnlineMessages.Scene.GAME_OVER:
			_clear_screen()
			_show_game_over()
		OnlineMessages.Scene.ENDING:
			# Each player watches the ending at his own pace.
			_start_ending()
		OnlineMessages.Scene.EARTH_EXPLODES:
			_on_earth_exploded()
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
	_frame_camera()
	_apply_backdrop()
	_remote.begin(kind, _level, _properties, tiles)
	_mode = Mode.REMOTE
	_follow(_keen)


## (Joiner) a message of the host's game.
func _on_remote_event(kind: OnlineMessages.Event, value: Variant) -> void:
	if _mode != Mode.REMOTE:
		return
	match kind:
		OnlineMessages.Event.HINT:
			_show_elder_message(value)
		OnlineMessages.Event.KEENS_LEFT:
			_show_lives(value)
		OnlineMessages.Event.LIGHTS:
			_set_dark(value != 0)
		OnlineMessages.Event.MESSAGE:
			_show_message(value)


## (Joiner) runs the ticks for [param delta] seconds: sends our buttons and
## shows the host's picture.
func _run_remote(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	var input := KeenInput.new() if _menus.is_open() else KeenInput.from_actions()
	while _time_left >= KeenPhysics.TICK and _mode == Mode.REMOTE:
		_time_left -= KeenPhysics.TICK
		var snapshot := _online.client_tick(input, _own_view())
		if snapshot != null:
			_progress.inventory = snapshot.inventory
			_remote_cities = snapshot.progress_bits
			if _remote.show(snapshot):
				_follow(_keen)
	_place_sprites(_time_left / KeenPhysics.TICK)


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


## "Keens Left" with [param lives] lives; [Keen2View] shows it.
func _show_lives(_lives: int) -> void:
	pass


## An Elder's message of level [param number]; [Keen2View] shows it.
func _show_elder_message(_number: int) -> void:
	pass
