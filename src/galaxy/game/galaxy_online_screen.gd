class_name GalaxyOnlineScreen
extends GalaxyJoinedScreen
## A Galaxy episode online (made from Keen 4's [Keen4OnlineScreen],
## milestone E11; docs/keen4/gameplay.md and docs/keen5/gameplay.md,
## "Online"), between [GalaxyJoinedScreen] and the episode's view: the
## shared [OnlinePlay] (hosting and joining by IP or through Steam, the
## handshake with the episode's id ([member GalaxyGameRules.game_id]) and
## the fingerprint of its maps, [GalaxyFingerprint]; joining a host of
## another episode switches game), reached from the control panel
## (Configure > Online Game), and what the host sends:
##   - the scene when the map on his screen changes (a new map, Try Again,
##     the end, nothing), with every tile of the three planes that differs
##     from the file ([GalaxyOnlineMessages]); tiles that change later;
##   - every logic frame a [GalaxySnapshot]: the joiner's view, the sprites,
##     the sounds, the song, the box (named by [GalaxyBoxNames]), the
##     brightness and the episode's numbers ([GalaxyOnlineState]).
## The player who joins is player 2 in the host's levels (with the keys he
## sends; no split screen: each has his own screen). The world map is the
## host's. F7 (player 2 on the keyboard) is off while online.
## The episode's view calls [method _set_up_online] after
## [method GalaxyCoopScreen._set_up_coop].

var _online_partner := false
var _scene_id := 0
## What the scene sent last was: kind, map and the session it showed.
var _scene_key: Array = []
var _frame_sounds := PackedByteArray()
var _last_figures := PackedInt32Array()
var _notice_text := ""

@onready var _notice: OnlineNotice = %Notice


## After [method GalaxyCoopScreen._set_up_coop]: the boxes named for the
## joiner, and the online game with the episode's id and maps.
func _set_up_online() -> void:
	_box_names = _new_box_names()
	_online_state = _new_online_state()
	_boxes = GalaxyNamedBoxes.create_named(_data, rules, _box_names)
	_online.game_id = rules.game_id
	_online.fingerprint = GalaxyFingerprint.of(_data.maps)
	_online.attach(_panel, _user_settings)
	_online.hosting_started.connect(_on_hosting_started)
	_online.partner_joined.connect(_on_partner_joined)
	_online.partner_left.connect(_on_partner_left)
	_online.stopped.connect(_on_online_stopped)
	_online.joined.connect(_begin_remote)
	_online.session.received.connect(_on_galaxy_message)


## The online game (tests).
func online() -> OnlinePlay:
	return _online


func _process(delta: float) -> void:
	if _shows_host:
		_remote_process(delta)
	else:
		var tic := _clock.tic
		super(delta)
		if _online.has_partner():
			_announce_scene()
			if _clock.tic != tic:
				_send_snapshot()
			_point_at_partner()
	_show_notice()


func _on_panel_chosen(id: StringName, value: int) -> void:
	if _online.handle_choice(id, value):
		return
	if id == MenuController.CHOICE_LEAVE_ONLINE:
		_online.leave()
		_end_remote()
		_on_online_stopped()
		return
	if _shows_host and id == MenuController.CHOICE_RESUME:
		return
	super(id, value)


## The panel knows whether this player hosts or joined.
func _open_panel() -> void:
	_panel.online = _online.menu_info()
	super()


func _may_toggle_partner() -> bool:
	return super() and not _online.is_active()


func _wants_partner() -> bool:
	return super() or _online_partner


func _split_active() -> bool:
	return super() and not _online_partner


## The joiner's view may be wider than the host's (his own widescreen
## setting): his objects wake up around the widest view the game draws.
func _partner_view_width(width: int) -> int:
	if not _online_partner:
		return super(width)
	var widest := (
		DisplaySettings.ORIGINAL_SIZE.y
		* DisplaySettings.ORIGINAL_PIXEL_ASPECT
		* DisplaySettings.WIDESCREEN_RATIO
	)
	return maxi(width, roundi(widest / 2.0) * 2)


func _partner_input() -> KeenInput:
	if _online_partner:
		return _online.partner_input() if partner_keen() != null else null
	return super()


## While a box waits the partner's buttons are taken all the same, so they
## do not pile up for the next level.
func _waiting(tics: int) -> void:
	super(tics)
	if _online_partner:
		_online.partner_input()


## The joiner's own help, menu and keys are his; the host's game goes on.
func _front_input(event: InputEvent) -> bool:
	if not _shows_host or _panel.is_open() or _front != Front.NONE:
		return super(event)
	if event.is_action_pressed("ui_cancel"):
		_open_panel()
	return true


func _open_help() -> void:
	if not _shows_host:
		super()


## Every tile of a played map also goes to the joiner (its sounds go
## through [method _play_sound]).
func _start_playing(map: GalaxyMap, camera: GalaxyCamera, world: GalaxyWorld) -> void:
	super(map, camera, world)
	var fore := world.tile_writer
	var back := world.back_tile_writer
	world.tile_writer = func(cell: Vector2i, tile: int) -> void:
		fore.call(cell, tile)
		_send_tile(GalaxyMap.Layer.FOREGROUND, cell, tile)
	world.back_tile_writer = func(cell: Vector2i, tile: int) -> void:
		back.call(cell, tile)
		_send_tile(GalaxyMap.Layer.BACKGROUND, cell, tile)


func _play_sound(sound_name: StringName, interrupt := false) -> void:
	super(sound_name, interrupt)
	var number: int = _audio.names.get(sound_name, -1)
	if _online.has_partner() and number >= 0 and _frame_sounds.size() < GalaxySnapshot.MAX_SOUNDS:
		_frame_sounds.append(number | (GalaxySnapshot.INTERRUPT if interrupt else 0))


func _send_tile(layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	if _online.has_partner():
		_online.session.send(GalaxyOnlineMessages.tile(_scene_id, layer, cell, tile))


## Hosting from the title starts a new game; player 2 on the keyboard
## leaves.
func _on_hosting_started() -> void:
	if _partner_wanted:
		_partner_wanted = false
		_remove_partner()
	if not in_game():
		_new_game()


func _on_partner_joined(_player_name: String) -> void:
	_online_partner = true
	_scene_key = []
	if partner_keen() == null and _can_join_now():
		_add_partner()


func _on_partner_left(_player_name: String) -> void:
	_online_partner = false
	_remove_partner()
	_arrow.visible = false


func _on_online_stopped() -> void:
	if _online_partner:
		_on_partner_left("")
	_end_remote()


func _on_galaxy_message(message: Array) -> void:
	if not _shows_host:
		return
	match message[0]:
		OnlineProtocol.Message.GALAXY_SCENE:
			var scene := GalaxyOnlineMessages.read_scene(message)
			if not scene.is_empty():
				_remote_scene_arrived(scene[0], scene[1], scene[2], scene[3])
		OnlineProtocol.Message.GALAXY_TILE:
			var change := GalaxyOnlineMessages.read_tile(message)
			if not change.is_empty():
				_remote_tile_arrived(change[0], change[1], change[2], change[3])
		OnlineProtocol.Message.GALAXY_SNAPSHOT:
			var snapshot := GalaxySnapshot.from_message(message)
			if snapshot != null:
				_remote_snapshot_arrived(snapshot)


## Sends the scene when the screen shows another one: a map being played
## (a new session of it: Try Again starts anew), the end, or nothing (also
## a scene over the whole screen, such as Keen 5's exploding galaxy). The
## boxes between two maps keep the last map behind them.
func _announce_scene() -> void:
	var kind := GalaxyOnlineMessages.Scene.WAITING
	var number := 0
	var session_id := 0
	var playing := not _in_title_loop and not _after_game and _front == Front.NONE
	if _front == Front.ENDING:
		kind = GalaxyOnlineMessages.Scene.ENDING
	elif playing and (_played != null or _on_map != null):
		kind = GalaxyOnlineMessages.Scene.MAP
		number = _map_number
		session_id = (_played.get_instance_id() if _played != null else _on_map.get_instance_id())
	elif playing and not _queue.is_empty() and not _scene_key.is_empty():
		return
	var key: Array = [kind, number, session_id]
	if key == _scene_key:
		return
	_scene_key = key
	_scene_id += 1
	_last_figures = PackedInt32Array()
	var tiles := PackedInt32Array()
	if kind == GalaxyOnlineMessages.Scene.MAP and _map != null:
		tiles = GalaxyOnlineMessages.changed_tiles(_map, _data.maps.load_map(number))
	_online.session.send(GalaxyOnlineMessages.scene(_scene_id, kind, number, tiles))


func _send_snapshot() -> void:
	var snapshot := GalaxySnapshot.new()
	snapshot.scene = _scene_id
	var world := _played_world()
	if world != null:
		snapshot.add_objects(world.objects, world.player(), world.partner)
		_last_figures = snapshot.figures
	else:
		snapshot.figures = _last_figures
	snapshot.view = _partner_scroll()
	snapshot.sounds = _frame_sounds
	_frame_sounds = PackedByteArray()
	snapshot.song = _audio.song()
	var step := _queue.current()
	if step != null:
		snapshot.box = _box_names.description_of(step.image)
		snapshot.brightness = roundi(step.brightness * GalaxySnapshot.FULL_BRIGHTNESS)
	snapshot.extra = _online_state.pack(_inventory, _game_progress, _difficulty)
	_online.session.send(snapshot.to_message(), false)


## Where the joiner looks: the host's camera on player 2 in a level, the
## host's view on the world map.
func _partner_scroll() -> Vector2i:
	if _played != null and _played.camera_2 != null:
		return _played.camera_2.scroll
	return _galaxy_camera.scroll if _galaxy_camera != null else Vector2i.ZERO


## The arrow on the host's screen points to player 2 while he is out of
## sight.
func _point_at_partner() -> void:
	var keen := partner_keen()
	if keen == null:
		_arrow.visible = false
		return
	_arrow.color = PartnerArrow.PARTNER_COLOR
	var box := keen.box
	var middle := Vector2(box.left + box.right, box.top + box.bottom) / 2.0 / GalaxyUnits.PER_PIXEL
	_arrow.point_at(_own_view(), middle)


## The shared notice ("Name joined") is drawn with Keen 1's font; a Galaxy
## episode shows its text as a message.
func _show_notice() -> void:
	var text := _notice.text()
	if text != _notice_text:
		_notice_text = text
		if not text.is_empty():
			_show_message(text)
