class_name Keen4JoinedScreen
extends Keen4CoopScreen
## What the player who joined a Keen 4 host online sees (milestone D12;
## docs/keen4/gameplay.md, "Online"), between [Keen4CoopScreen] and
## [Keen4OnlineScreen]. He runs nothing of the game: he shows the host's
## maps from his own files with the tiles the host changed
## ([GalaxyOnlineMessages]), and every frame what the host sends
## ([GalaxySnapshot]): his own view (the host's camera on player 2), the
## sprites (player 2's in his colours), the sounds and the song, the box on
## the screen (made from his own files, [Keen4BoxNames]), the brightness and
## the inventory in the score box. His keys go to the host. Without a map
## (the host's title, menus, high scores) he sees the title picture; the
## end pages he reads at his own pace. An arrow at the edge points to the
## host's Keen while it is out of sight.

const WAITING_MESSAGE := "Waiting for %s"
const HOST_WALKS_MESSAGE := "Only the host can walk on the world map"
## The middle of a Keen's sprite, from its corner, in pixels (for the arrow).
const KEEN_MIDDLE := Vector2(12, 16)

## Whether the host's game is shown.
var _shows_host := false
var _host_name := ""
## The host's scene shown now.
var _remote_scene := -1
var _remote_kind := GalaxyOnlineMessages.Scene.WAITING
## The latest snapshot of the scene, shown at the next frame.
var _remote_snapshot: GalaxySnapshot
var _remote_box := PackedInt32Array()
var _mirrors: Array[GalaxyObject] = []

@onready var _arrow: PartnerArrow = %Arrow


## Whether this screen shows somebody else's game.
func is_remote() -> bool:
	return _shows_host


func in_game() -> bool:
	if _shows_host:
		return _remote_kind == GalaxyOnlineMessages.Scene.MAP
	return super()


## Joined [param host_name]'s game: whatever ran stops; the host's scenes
## come.
func _begin_remote(host_name: String) -> void:
	_host_name = host_name
	_shows_host = true
	_in_title_loop = false
	_after_game = false
	_partner_wanted = false
	_queue.clear()
	_played = null
	_on_map = null
	_recording = null
	_replay = null
	_stop_front()
	_end_split()
	_title_layer.clear()
	_remote_scene = -1
	_show_remote_waiting()


## Back to this player's own title loop.
func _end_remote() -> void:
	if not _shows_host:
		return
	_shows_host = false
	_remote_snapshot = null
	_objects.clear()
	_arrow.visible = false
	_window_sprite.visible = false
	_screen.modulate = Color.WHITE
	_score_box.visible = false
	_audio.stop_music()
	_stop_front()
	_start_title_loop()


func _show_remote_waiting() -> void:
	_remote_kind = GalaxyOnlineMessages.Scene.WAITING
	_objects.clear()
	_score_box.visible = false
	_arrow.visible = false
	_window_sprite.visible = false
	_screen.modulate = Color.WHITE
	_title_layer.show_picture(_title_picture())
	_show_message(WAITING_MESSAGE % _host_name)


## The host shows scene [param scene_id]: map [param number] with
## [param tiles] changed, the end, or nothing.
func _remote_scene_arrived(
	scene_id: int, kind: GalaxyOnlineMessages.Scene, number: int, tiles: PackedInt32Array
) -> void:
	_remote_scene = scene_id
	_remote_snapshot = null
	_remote_box = PackedInt32Array()
	_window_sprite.visible = false
	if _front != Front.NONE and _front != Front.HELP:
		_stop_front()
	match kind:
		GalaxyOnlineMessages.Scene.MAP:
			_show_remote_map(number, tiles)
		GalaxyOnlineMessages.Scene.ENDING:
			_remote_kind = kind
			_start_ending()
		_:
			_show_remote_waiting()


func _show_remote_map(number: int, tiles: PackedInt32Array) -> void:
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_remote_waiting()
		return
	GalaxyOnlineMessages.apply_tiles(map, tiles)
	_remote_kind = GalaxyOnlineMessages.Scene.MAP
	_title_layer.clear()
	_map_number = number
	_start = Keen4Start.find(map)
	_mode = Mode.LEVEL
	_clock.start_level()
	_galaxy_camera = GalaxyCamera.for_map(
		Vector2i(map.width, map.height),
		GalaxyCamera.blocks_in(map, Keen4Episode.COLUMN_BLOCK_INFO, true),
		GalaxyCamera.blocks_in(map, Keen4Episode.ROW_BLOCK_INFO, false)
	)
	_objects.clear()
	_show_map(map, _level_sprites())
	_score_box.visible = _keen4_settings.score_box
	_frame_view()


## A tile of the host's map changed.
func _remote_tile_arrived(scene_id: int, layer: int, cell: Vector2i, tile: int) -> void:
	if scene_id != _remote_scene or _remote_kind != GalaxyOnlineMessages.Scene.MAP:
		return
	if layer == GalaxyMap.Layer.INFO:
		if _map != null and cell.x < _map.width and cell.y < _map.height:
			_map.planes[layer][cell.y * _map.width + cell.x] = tile
		return
	_galaxy_map.set_tile(layer as GalaxyMap.Layer, cell, tile)


func _remote_snapshot_arrived(snapshot: GalaxySnapshot) -> void:
	if snapshot.scene == _remote_scene:
		_remote_snapshot = snapshot


## A frame of the screen while the host's game is shown: the joiner's keys
## go out, the latest snapshot comes on the screen.
func _remote_process(delta: float) -> void:
	_message_time_left -= delta
	for frame in _clock.advance(delta):
		var tics := _clock.run_frame()
		if _front == Front.ENDING or _panel.is_open():
			_run_frame(tics)
		_online.client_tick(_remote_input(), Rect2())
		if _remote_kind == GalaxyOnlineMessages.Scene.MAP:
			_galaxy_map.animate(tics)
		# Without a new picture from the host (his game waits behind a box)
		# the sprites stand still where they were drawn (D13.2).
		_game_stepped = _remote_snapshot != null
		if _remote_snapshot != null:
			_apply_remote(_remote_snapshot)
			_remote_snapshot = null
	_objects.place(_blend_to_draw(), _settings.smooth_motion)
	_place_overlays()
	_update_backdrops()
	_update_status()


## The joiner's keys; on the world map only the host walks.
func _remote_input() -> KeenInput:
	if _panel.is_open() or _front != Front.NONE:
		return KeenInput.new()
	var input := KeenInput.from_actions()
	var pressed := input.direction != 0 or input.vertical != 0 or input.jump or input.pogo
	if pressed and _map_number == Keen4Episode.WORLD_MAP and _message_time_left <= 0.0:
		_show_message(HOST_WALKS_MESSAGE)
	return input


func _apply_remote(snapshot: GalaxySnapshot) -> void:
	if _remote_kind == GalaxyOnlineMessages.Scene.MAP and _galaxy_camera != null:
		_galaxy_camera.scroll = snapshot.view
		_frame_view()
		_objects.show_objects(_mirror(snapshot))
		Keen4OnlineState.unpack(snapshot.extra, _inventory, _game_progress)
		# The host's score box stands still behind a box (a death takes the
		# life before the next frame shows it).
		if snapshot.box.is_empty():
			_update_score_box()
		_point_at_host(snapshot)
	for sound in snapshot.sounds:
		if sound & GalaxySnapshot.INTERRUPT:
			_audio.stop_sound()
		_audio.play_number(sound & ~GalaxySnapshot.INTERRUPT)
	if snapshot.song != _audio.song():
		_audio.start_song(snapshot.song)
	if snapshot.box != _remote_box:
		_remote_box = snapshot.box
		var image := Keen4BoxNames.image_for(_remote_box, _boxes, _messages)
		_window_sprite.visible = image != null
		if image != null:
			_window_sprite.texture = ImageTexture.create_from_image(image)
	_screen.modulate = Color(
		Color.WHITE * (float(snapshot.brightness) / GalaxySnapshot.FULL_BRIGHTNESS), 1.0
	)


## Objects that stand for the host's sprites, one per figure, kept from
## frame to frame (so smooth motion can follow them).
func _mirror(snapshot: GalaxySnapshot) -> Array[GalaxyObject]:
	var shown: Array[GalaxyObject] = []
	var figures := snapshot.figures
	for index in snapshot.figure_count():
		if index == _mirrors.size():
			var made := GalaxyObject.new()
			made.activity = GalaxyObject.Activity.ALWAYS
			_mirrors.append(made)
		var mirror := _mirrors[index]
		var start := index * GalaxySnapshot.FIGURE_FIELDS
		var flags := figures[start + 3]
		mirror.position = Vector2i(figures[start], figures[start + 1])
		mirror.sprite = figures[start + 2]
		mirror.priority = flags & GalaxySnapshot.PRIORITY_MASK
		var partner := flags & GalaxySnapshot.PARTNER_KEEN != 0
		_objects.tint(mirror, _partner_material if partner else null)
		shown.append(mirror)
	return shown


func _point_at_host(snapshot: GalaxySnapshot) -> void:
	_arrow.color = PartnerArrow.HOST_COLOR
	var figures := snapshot.figures
	for start in range(0, figures.size(), GalaxySnapshot.FIGURE_FIELDS):
		if figures[start + 3] & GalaxySnapshot.HOST_KEEN:
			var at := Vector2(figures[start], figures[start + 1]) / GalaxyUnits.PER_PIXEL
			_arrow.point_at(_own_view(), at + KEEN_MIDDLE)
			return
	_arrow.visible = false


## The end pages are over: the joiner waits for the host again (the high
## scores are the host's).
func _game_ended() -> void:
	if not _shows_host:
		super()
		return
	_stop_front()
	_show_remote_waiting()
