class_name OnlinePlay
extends Node
## Playing online for [LevelView]: the network ([OnlineSession], Steam
## through [SteamService]) and what goes over it. See docs/online.md.
##
## The host runs the game as always. Every tick he sends what can be seen
## ([Snapshot]); when the screen changes (another map, game over, the
## ending) he sends the new scene with the tiles that differ from the level
## file; and tiles that change, and the messages of the game, as events.
## The Keen of the player who joins is player 2 in the host's level, steered
## by the buttons that player sends ([OnlineInput]).
##
## The player who joins runs nothing himself: he shows the host's scenes
## with his own level files and graphics, and the snapshots one per tick
## ([SnapshotBuffer]). The game screen and [RemoteGame] do the drawing; this
## node hands them what arrived through its signals.
##
## It also answers the online choices of the menus (hosting, joining) and
## tells the player in a window what happened.

## (Joiner) the host shows another scene: map or level [param number], with
## [param tiles] (x, y, tile, ...) changed from its file.
signal scene_changed(kind: OnlineMessages.Scene, number: int, tiles: PackedInt32Array)
## (Joiner) a tile of the shown map changed.
signal tile_changed(cell: Vector2i, tile: int)
## (Joiner) the host shows a message of the game.
signal event_shown(kind: OnlineMessages.Event, value: Variant)
## (Joiner) the host let us in.
signal joined(host_name: String)
## (Host) somebody joined, or left.
signal partner_joined(player_name: String)
signal partner_left(player_name: String)
## The online game is over, or could not start; the player is told why.
signal stopped
## Hosting has started.
signal hosting_started

## A joining player's view goes to the host this often, in ticks.
const VIEW_EVERY_TICKS := 10

## The fingerprint of this player's levels ([LevelFingerprint]).
var fingerprint := ""
## The game played online ([constant OnlineProtocol.GAME_ID] for Keen 1):
## only players and Steam lobbies of the same game meet.
var game_id := OnlineProtocol.GAME_ID:
	set = _set_game_id
## (Host) the progress bits sent with every snapshot ([member
## Snapshot.progress_bits]): Keen 2's saved cities; 0 for Keen 1.
var progress_bits := 0
## (Host) a game's own numbers sent with every snapshot ([member
## Snapshot.extra]): Keen 3's ([Keen3OnlineState]); empty for Keen 1 and 2,
## whose snapshots stay as they were.
var extra := PackedInt32Array()
## The level files, to tell which tiles of a map differ from its file.
var files: GameFiles
## Whether the ping may sound.
var sound_enabled := true

var session := OnlineSession.new()
## The menus, for asking and telling the player things, and the settings
## with his name.
var menus: MenuController
var settings: UserSettings
var steam := SteamService.new()
var addresses := HostAddresses.new()
var _maker := SnapshotMaker.new()
var _buffer := SnapshotBuffer.new()
var _partner_input := OnlineInput.new()
var _partner_view := Rect2()
## The scene shown now: counted up by the host at every change, so that
## the joiner can tell old snapshots and events from new ones.
var _scene := 0
var _scene_kind := OnlineMessages.Scene.WAITING
var _scene_number := 0
var _scene_level: LevelData
var _sounds := PackedByteArray()
var _sent_bits := -1
var _ticks_since_view := 0
var _over_steam := false
var _password := ""
## The address and password of the last join by IP, handed over when the
## host turns out to play another game.
var _join_address := ""
var _join_password := ""
## A wish waiting for Steam: [host?, password], or empty.
var _steam_wish: Array = []
var _steam_games: Array = []
var _ping: AudioStreamPlayer

@onready var _notice: OnlineNotice = %Notice


func _ready() -> void:
	add_child(session)
	add_child(steam)
	add_child(addresses)
	_ping = AudioStreamPlayer.new()
	_ping.stream = PingSound.render()
	add_child(_ping)
	session.received.connect(_on_received)
	session.joined.connect(_on_joined)
	session.join_failed.connect(_on_join_failed)
	session.host_left.connect(_on_host_left)
	session.partner_joined.connect(_on_partner_joined)
	session.partner_left.connect(_on_partner_left)
	steam.lobby_opened.connect(_on_lobby_opened)
	steam.lobby_entered.connect(_on_lobby_entered)
	steam.games_listed.connect(_on_games_listed)
	steam.failed.connect(func(reason: String) -> void: _stop(OnlineText.steam(reason)))
	addresses.public_lookup_finished.connect(func(_found: String) -> void: _refresh_menu())
	# Picks up a join that another game handed over when it switched here.
	_resume_join.call_deferred()


## Uses [param menu_controller] to ask and tell the player things, and the
## name in [param user_settings].
func attach(menu_controller: MenuController, user_settings: UserSettings) -> void:
	menus = menu_controller
	settings = user_settings
	menus.steam_games_wanted.connect(steam.ask_for_games)
	menus.addresses_wanted.connect(_on_addresses_wanted)


func set_textures(textures: GraphicsTextures) -> void:
	_notice.set_textures(textures)


func set_view_size(view_size: Vector2i) -> void:
	_notice.view_size = view_size
	_notice.queue_redraw()


func is_active() -> bool:
	return session.is_active() or not _steam_wish.is_empty()


## (Host) whether somebody plays along.
func has_partner() -> bool:
	return session.is_host() and session.has_partner()


func partner_name() -> String:
	return session.partner_name


## Does what the player chose in the menus, if it is about playing online:
## hosting or joining (see [MenuController]). Returns whether it was.
func handle_choice(id: StringName, value: int) -> bool:
	var password := menus.host_password if menus.host_locked else ""
	match id:
		MenuController.CHOICE_HOST:
			if value == MenuController.HOST_THROUGH_STEAM:
				_host_through_steam(password)
			else:
				_host_by_ip(settings.online_name, password)
		MenuController.CHOICE_JOIN_IP:
			_join_by_ip(menus.join_address, settings.online_name, menus.join_password)
		MenuController.CHOICE_JOIN_STEAM:
			_join_through_steam(value, menus.join_password)
		_:
			return false
	return true


## Stops hosting, or leaves the host's game.
func leave() -> void:
	_steam_wish.clear()
	session.leave()
	steam.leave()
	_reset()


## Whether two play together now: hosting with somebody in, or in
## somebody's game. Then nothing pauses.
func is_together() -> bool:
	return session.has_partner()


## (Host) whether we host a game.
func is_hosting() -> bool:
	return session.is_host()


## What the menus show about playing online.
func menu_info() -> OnlineMenuInfo:
	var info := _address_info()
	if session.is_host():
		info.role = OnlineMenuInfo.Role.HOST
		info.host_lines = _host_lines()
	elif session.is_client():
		info.role = OnlineMenuInfo.Role.CLIENT
	info.partner_name = session.partner_name if session.has_partner() else ""
	return info


## (Host) the screen shows something new: map or level [param number]
## ([param level] as it is now), or another [param kind] of scene.
func announce(kind: OnlineMessages.Scene, number: int, level: LevelData) -> void:
	_scene += 1
	_scene_kind = kind
	_scene_number = number
	_scene_level = level
	_maker.reset()
	_sounds.clear()
	_send_scene()


## (Host) a tile of the shown map changed.
func send_tile(cell: Vector2i, tile: int) -> void:
	if has_partner():
		session.send(OnlineMessages.tile(_scene, cell, tile))


## (Host) a sound of the game, sent with the next snapshot.
func send_sound(sound: Sound.Id) -> void:
	if has_partner() and _sounds.size() < Snapshot.MAX_FIGURES:
		_sounds.append(sound)


## (Host) a message of the game that the other player sees too.
func send_event(kind: OnlineMessages.Event, value: Variant) -> void:
	if has_partner():
		session.send(OnlineMessages.event(_scene, kind, value))


## (Host) the picture of the tick that just ran in a level.
func send_level(level_session: LevelSession, inventory: Inventory) -> void:
	if has_partner():
		_send_snapshot(_maker.of_level(level_session, _scene, inventory, _take_sounds()))


## (Host) the picture of the tick that just ran on the world map.
func send_map(map_keen: MapKeen, inventory: Inventory) -> void:
	if has_partner():
		_send_snapshot(_maker.of_map(map_keen, _scene, inventory, _take_sounds()))


## (Host) the buttons of the other player for the next tick.
func partner_input() -> KeenInput:
	return _partner_input.next()


## (Host) what the other player sees of the level, in level pixels.
func partner_view() -> Rect2:
	return _partner_view if has_partner() else Rect2()


## (Joiner) one tick: sends our buttons when they changed (and now and then
## what we see), and returns the host's picture for this tick, or null to
## keep the last one.
func client_tick(input: KeenInput, view: Rect2) -> Snapshot:
	if not session.is_client() or not session.has_partner():
		return null
	var bits := OnlineInput.to_bits(input)
	if bits != _sent_bits:
		_sent_bits = bits
		session.send(OnlineMessages.input(bits))
	_ticks_since_view += 1
	if _ticks_since_view >= VIEW_EVERY_TICKS:
		_ticks_since_view = 0
		session.send(OnlineMessages.view(view), false)
	return _buffer.take()


func _set_game_id(id: String) -> void:
	game_id = id
	session.game_id = id
	steam.game_id = id


## Hosts by IP as [param player_name].
func _host_by_ip(player_name: String, password: String) -> void:
	_over_steam = false
	_password = password
	var error := session.host(EnetTransport.new(), player_name, password, fingerprint)
	if error != OK:
		_stop(OnlineText.host_failed(error))
		return
	addresses.look_up()
	_on_hosting_started()


## Hosts through Steam; hosting starts once Steam has opened the lobby.
func _host_through_steam(password: String) -> void:
	_steam_wish = [true, password]
	_tell(["Opening a Steam lobby..."])
	steam.open_lobby(not password.is_empty())


func _join_by_ip(address: String, player_name: String, password: String) -> void:
	_over_steam = false
	_join_address = address
	_join_password = password
	var error := session.join(EnetTransport.new(), address, player_name, password, fingerprint)
	if error != OK:
		_stop(OnlineText.join_failed(OnlineSession.NO_ANSWER))
		return
	_tell(["Joining " + address + "..."])


## Joins the friend's game at [param index] of the last list.
func _join_through_steam(index: int, password: String) -> void:
	if index < 0 or index >= _steam_games.size():
		return
	var lobby_game := SteamLobby.game_of(_steam_games[index][1])
	if lobby_game != game_id:
		var join := GameLaunch.OnlineJoin.new()
		join.lobby_id = int(_steam_games[index][0])
		join.password = password
		_switch_game(lobby_game, join)
		return
	_steam_wish = [false, password]
	_tell(["Joining through Steam..."])
	steam.enter_lobby(int(_steam_games[index][0]))


## The game makes way for the online one first; then the window says how
## to join (and fills in the internet address once it is found).
func _on_hosting_started() -> void:
	hosting_started.emit()
	menus.online = menu_info()
	menus.close_all()
	menus.show_hosting()


## The menus want this computer's addresses (to set up hosting).
func _on_addresses_wanted() -> void:
	addresses.look_up()
	_refresh_menu()


## Shows [param lines] in a window that any key closes.
func _tell(lines: PackedStringArray) -> void:
	menus.close_all()
	lines.append_array(["", "   Press a key"])
	menus.show_message(lines)


func _refresh_menu() -> void:
	menus.online = menu_info()
	menus.refresh_online()


func _send_scene() -> void:
	if not has_partner():
		return
	var tiles := PackedInt32Array()
	if _scene_kind in [OnlineMessages.Scene.MAP, OnlineMessages.Scene.LEVEL]:
		tiles = changed_tiles(_scene_level, _original(_scene_number))
	session.send(OnlineMessages.scene(_scene, _scene_kind, _scene_number, tiles))


## The tiles of [param level] that differ from [param original]: x, y and
## the tile for each.
static func changed_tiles(level: LevelData, original: LevelData) -> PackedInt32Array:
	var tiles := PackedInt32Array()
	if level == null or original == null:
		return tiles
	if level.width != original.width or level.height != original.height:
		return tiles
	for y in level.height:
		for x in level.width:
			var tile := level.tile_at(Vector2i(x, y))
			if tile != original.tile_at(Vector2i(x, y)):
				tiles.append_array([x, y, tile])
	return tiles


func _original(number: int) -> LevelData:
	if ShipLevels.is_ship_level(number):
		return ShipLevels.build(number)
	if files == null:
		return null
	return LevelData.parse(files.read(files.level_file(number)))


func _send_snapshot(snapshot: Snapshot) -> void:
	snapshot.progress_bits = progress_bits
	snapshot.extra = extra
	session.send(snapshot.to_message(), false)


func _take_sounds() -> PackedByteArray:
	var sounds := _sounds
	_sounds = PackedByteArray()
	return sounds


## Menu info with only this computer's addresses filled in.
func _address_info() -> OnlineMenuInfo:
	var info := OnlineMenuInfo.new()
	info.local_addresses = HostAddresses.local()
	info.public_address = addresses.public_address
	info.public_lookup_done = addresses.public_lookup_done
	return info


func _host_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if _over_steam:
		lines.append("Via Steam, friends only")
	else:
		lines.append("Via IP, UDP port %d" % OnlineProtocol.GAME_PORT)
		lines.append_array(_address_info().address_lines())
	lines.append("Password: " + (_password if not _password.is_empty() else "none"))
	return lines


func _on_received(message: Array) -> void:
	if session.is_host():
		_on_host_received(message)
	else:
		_on_client_received(message)


func _on_host_received(message: Array) -> void:
	match message[0]:
		OnlineProtocol.Message.INPUT:
			var bits := OnlineMessages.read_input(message)
			if bits >= 0:
				_partner_input.receive(bits)
		OnlineProtocol.Message.VIEW:
			_partner_view = OnlineMessages.read_view(message)


func _on_client_received(message: Array) -> void:
	match message[0]:
		OnlineProtocol.Message.SCENE:
			var scene := OnlineMessages.read_scene(message)
			if scene.is_empty():
				return
			_scene = scene[0]
			_buffer.clear()
			scene_changed.emit(scene[1], scene[2], scene[3])
		OnlineProtocol.Message.TILE:
			var change := OnlineMessages.read_tile(message)
			if not change.is_empty() and change[0] == _scene:
				tile_changed.emit(change[1], change[2])
		OnlineProtocol.Message.EVENT:
			var event := OnlineMessages.read_event(message)
			if not event.is_empty() and event[0] == _scene:
				event_shown.emit(event[1], event[2])
		OnlineProtocol.Message.SNAPSHOT:
			var snapshot := Snapshot.from_message(message)
			if snapshot != null and snapshot.scene == _scene:
				_buffer.push(snapshot)


func _on_joined(host_name: String) -> void:
	_sent_bits = -1
	_steam_wish.clear()
	menus.close_all()
	joined.emit(host_name)
	_notice.show_text("Joined %s's game" % host_name)


func _on_join_failed(reason: String) -> void:
	if reason == JoinHandshake.OTHER_GAME and not _over_steam:
		var join := GameLaunch.OnlineJoin.new()
		join.address = _join_address
		join.password = _join_password
		_switch_game(session.host_game_id, join)
		return
	_stop(OnlineText.join_failed(reason))


## The host plays another of our games ([param other_game]): this game
## makes way for it, and the other game joins with [param join] as soon as
## it is shown. When its files are missing, the player is told so.
func _switch_game(other_game: String, join: GameLaunch.OnlineJoin) -> void:
	var game := GameCatalog.for_game_id(other_game)
	if game == null:
		_stop(OnlineText.join_failed(JoinHandshake.OTHER_GAME))
		return
	if not game.is_available():
		_stop(OnlineText.missing_game(game.title))
		return
	_steam_wish.clear()
	if session.is_active():
		session.leave_soon()
	steam.leave()
	_reset()
	menus.close_all()
	GameLaunch.request_join(join)
	get_tree().change_scene_to_file.call_deferred(game.scene)


## (In a game that was switched to) joins the host that the other game
## handed over, if any.
func _resume_join() -> void:
	var join := GameLaunch.take_join_request()
	if join == null or settings == null:
		return
	if join.lobby_id != 0:
		_steam_wish = [false, join.password]
		_tell(["Joining through Steam..."])
		steam.enter_lobby(join.lobby_id)
	else:
		_join_by_ip(join.address, settings.online_name, join.password)


func _on_host_left() -> void:
	_stop(OnlineText.host_left())


func _on_partner_joined(player_name: String) -> void:
	_partner_input.clear()
	_partner_view = Rect2()
	_maker.reset()
	if sound_enabled:
		_ping.play()
	_notice.show_text("%s joined" % player_name)
	_send_scene()
	partner_joined.emit(player_name)
	_refresh_menu()


func _on_partner_left(player_name: String) -> void:
	_partner_input.clear()
	_notice.show_text("%s left" % player_name)
	partner_left.emit(player_name)
	_refresh_menu()


func _on_lobby_opened(lobby_id: int) -> void:
	if _steam_wish.is_empty() or not _steam_wish[0]:
		return
	_password = _steam_wish[1]
	_steam_wish.clear()
	_over_steam = true
	var error := session.host(
		SteamTransport.on(lobby_id), SteamService.player_name(), _password, fingerprint
	)
	if error != OK:
		steam.leave()
		_stop(OnlineText.host_failed(error))
		return
	_on_hosting_started()


func _on_lobby_entered(lobby_id: int) -> void:
	if _steam_wish.is_empty() or _steam_wish[0]:
		return
	var password: String = _steam_wish[1]
	_over_steam = true
	var error := session.join(
		SteamTransport.on(lobby_id),
		str(lobby_id),
		SteamService.player_name(),
		password,
		fingerprint
	)
	if error != OK:
		_steam_wish.clear()
		steam.leave()
		_stop(OnlineText.join_failed(OnlineSession.NO_ANSWER))


func _on_games_listed(games: Array) -> void:
	_steam_games = games.duplicate()
	var lines := PackedStringArray()
	var locked: Array[bool] = []
	for game: Array in games:
		var line := SteamLobby.described(game[1], int(game[2]))
		var other := GameCatalog.for_game_id(SteamLobby.game_of(game[1]))
		if other != null and other.game_id != game_id:
			line += " " + other.title
		lines.append(line)
		locked.append(SteamLobby.is_locked(game[1]))
	menus.show_steam_games(lines, locked)


## The online game ends (or never began), and [param lines] say why.
func _stop(lines: PackedStringArray) -> void:
	_steam_wish.clear()
	if session.is_active():
		session.leave_soon()
	steam.leave()
	_reset()
	stopped.emit()
	menus.close_all()
	menus.show_message(lines)


func _reset() -> void:
	_buffer.clear()
	_partner_input.clear()
	_partner_view = Rect2()
	_scene_level = null
	_sounds.clear()
	_sent_bits = -1
