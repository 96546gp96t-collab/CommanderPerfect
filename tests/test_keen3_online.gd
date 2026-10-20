extends "res://tests/test_case.gd"
## Tests for playing Keen 3 online (milestone C10): Keen 3 is one of our
## games (its id in [constant OnlineProtocol.GAME_IDS]), so a Keen 3 player
## meets a Keen 3 host, and a player of Keen 1 or 2 who knocks at a Keen 3
## host (or the other way round) learns which game to switch to, by IP and
## in Steam's list; Keen 1's and Keen 2's messages stay byte for byte as
## they were; Keen 3's own numbers ([Keen3OnlineState]: the done levels, the
## ankh time of each Keen, Keen 3's own sounds, the map's view and Messie)
## travel in the snapshot and are checked when they arrive; Keen 3's events;
## a real host and joiner over ENet on this machine; the fingerprint of
## Keen 3's own level files.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const Maps := preload("res://tests/keen3_map_fixtures.gd")
const KEEN_3 := OnlineProtocol.GAME_ID_KEEN_3
const FINGERPRINT := "0123456789abcdef"
## A port next to the game's, apart from the other suites' test ports.
const TEST_PORT := OnlineProtocol.GAME_PORT + 9
const MAX_POLLS := 400
const POLL_MS := 5
const POLL_DELTA := 0.005
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"##############################",
]
const START_CELL := Vector2i(4, 2)


func test_keen_3_is_one_of_our_games() -> void:
	var ids := OnlineProtocol.GAME_IDS
	assert_equal(ids, [OnlineProtocol.GAME_ID, OnlineProtocol.GAME_ID_KEEN_2, KEEN_3], "three")
	assert_equal(GameCatalog.for_game_id(KEEN_3).scene, GameLaunch.KEEN_3_SCENE, "its scene")
	assert_equal(GameCatalog.for_game_id(KEEN_3).title, "Keen 3", "its name in Steam's list")


func test_keen_3_player_joins_a_keen_3_host() -> void:
	var gate := _gate(KEEN_3)
	var step := _ticket(KEEN_3).answer(gate.begin(1))
	assert_equal(step.problem, "", "the challenge is answered")
	assert_true(gate.judge(1, "player", step.reply).admit, "let in")


func test_players_of_another_keen_learn_to_switch_to_keen_3() -> void:
	for other in [OnlineProtocol.GAME_ID, OnlineProtocol.GAME_ID_KEEN_2]:
		var ticket := _ticket(other)
		var step := ticket.answer(_gate(KEEN_3).begin(1))
		assert_equal(step.problem, JoinHandshake.OTHER_GAME, "%s sees another game" % other)
		assert_equal(ticket.host_game_id, KEEN_3, "Keen 3, to switch to")
		var back := _ticket(KEEN_3)
		assert_equal(back.answer(_gate(other).begin(1)).problem, JoinHandshake.OTHER_GAME, "back")
		assert_equal(back.host_game_id, other, "and Keen 3 switches to %s" % other)
	var gate := _gate(KEEN_3)
	gate.begin(2)
	var answer := var_to_bytes(
		[OnlineProtocol.GAME_ID, OnlineProtocol.VERSION, FINGERPRINT, "x", PackedByteArray()]
	)
	assert_equal(gate.judge(2, "p", answer).reason, JoinHandshake.OTHER_GAME, "host refuses")


func test_steam_lists_keen_3_lobbies() -> void:
	var lobby := SteamLobby.data_for("Billy", false, KEEN_3)
	assert_true(SteamLobby.is_any_ours(lobby), "one of ours")
	assert_equal(SteamLobby.game_of(lobby), KEEN_3, "Keen 3's lobby")
	assert_true(SteamLobby.is_ours(lobby, KEEN_3), "Keen 3 sees it as its own")
	assert_true(not SteamLobby.is_ours(lobby), "Keen 1 does not")


func test_keen_1_and_2_snapshots_stay_byte_for_byte_the_same() -> void:
	var snapshot := Snapshot.new()
	snapshot.scene = 7
	snapshot.inventory.score = 1200
	snapshot.inventory.lives = 3
	snapshot.inventory.charges = 4
	snapshot.inventory.has_pogo = true
	snapshot.inventory.keycards[1] = true
	snapshot.progress_bits = 0b101
	snapshot.sounds = PackedByteArray([Sound.Id.KEEN_JUMP])
	var keen := Snapshot.Figure.new()
	keen.position = Vector2(10, 20)
	keen.sprite = 5
	snapshot.keens.append(keen)
	var actor := Snapshot.Figure.new()
	actor.id = 2
	actor.position = Vector2(30, 40)
	actor.sprite = 9
	snapshot.actors.append(actor)
	var flags := 1 | (1 << 2) | (0b101 << Snapshot.PROGRESS_SHIFT)
	var expected := [
		OnlineProtocol.Message.SNAPSHOT,
		7,
		PackedInt32Array([1200, 3, 4, flags]),
		PackedByteArray([Sound.Id.KEEN_JUMP]),
		PackedFloat32Array([10, 20, 5, KeenPhysics.SPRITE_SIZE.x, 0]),
		PackedFloat32Array([2, 30, 40, 9]),
		PackedInt32Array(),
	]
	assert_equal(var_to_bytes(snapshot.to_message()), var_to_bytes(expected), "as before C10")
	var online := OnlinePlay.new()
	assert_equal(online.extra, PackedInt32Array(), "Keen 1 and 2 send no extra")
	for node: Node in [online.session, online.steam, online.addresses, online]:
		node.free()
	assert_true(Snapshot.from_message(expected).extra.is_empty(), "and read none")


func test_keen_1_and_2_messages_stay_the_same() -> void:
	var events := OnlineMessages.Event
	var old_events := [events.HINT, events.KEENS_LEFT, events.SHIP_MISSING, events.MESSAGE]
	assert_equal(old_events + [events.LIGHTS], [0, 1, 2, 3, 4], "the old events keep their numbers")
	var scenes := OnlineMessages.Scene
	assert_equal(scenes.EARTH_EXPLODES, 5, "the scenes too")
	assert_equal(scenes.size(), 6, "Keen 3 needs no new scene")
	var lights := OnlineMessages.event(3, events.LIGHTS, 1)
	var expected := [OnlineProtocol.Message.EVENT, 3, 4, 1]
	assert_equal(var_to_bytes(lights), var_to_bytes(expected), "an event as before")


func test_keen_3_events_come_after_the_others() -> void:
	var events := OnlineMessages.Event
	var keen_3 := [events.SHIP_MESSAGE, events.MORTIMER, events.BORDER_FLASH]
	assert_equal(keen_3, [5, 6, 7], "at the end")
	for kind: int in keen_3:
		var read := OnlineMessages.read_event(OnlineMessages.event(4, kind, 2))
		assert_equal(read, [4, kind, 2], "event %d is read" % kind)


func test_keen_3_snapshot_of_a_level_there_and_back() -> void:
	var session := Fixtures.start_session(FIELD, START_CELL)
	var partner := session.add_player(session.keen.position + Vector2(40, 0)) as Keen3Body
	partner.add_ankh()
	var progress := Keen3Progress.new(session.inventory)
	progress.complete_level(1)
	progress.complete_level(16)
	session.inventory.charges = 7
	session.inventory.keycards[3] = true
	var sounds := PackedStringArray([Keen3Sounds.ANKH, Keen3Sounds.FOOTSLAM])
	var state := Keen3OnlineState.of_level(session, progress, sounds)
	var sent := SnapshotMaker.new().of_level(session, 2, session.inventory, PackedByteArray())
	sent.extra = state.to_numbers()
	var got := Snapshot.from_message(bytes_to_var(var_to_bytes(sent.to_message())))
	assert_true(got != null, "it arrives whole")
	assert_equal(got.inventory.charges, 7, "the charges")
	assert_equal(got.inventory.keycards, [false, false, false, true], "the keycards")
	var back := Keen3OnlineState.from_numbers(got.extra)
	assert_true(back != null, "Keen 3's numbers")
	var done: Array[int] = [1, 16]
	assert_equal(back.completed_levels(), done, "the done levels")
	assert_equal(back.ankh_ticks, PackedInt32Array([0, Keen3Body.ANKH_TICKS]), "each Keen's ankh")
	assert_equal(back.ankh_seconds(1), partner.ankh_seconds(), "as the status screen counts")
	assert_equal(back.sounds, sounds, "Keen 3's own sounds")
	assert_true(not back.view_center.is_finite(), "no map view in a level")
	assert_equal(back.messie_sprite, -1, "no Messie")


func test_keen_3_snapshot_of_the_map_carries_its_view_and_messie() -> void:
	var loop: Dictionary[Vector2i, int] = {}
	# Across the middle column, where she starts.
	for x in range(3, 30):
		loop[Vector2i(x, 3)] = Keen3MapInfo.PATH
	var map := Maps.open_map(Maps.field_rows(), loop, Vector2i(10, 8))
	Maps.run(map, KeenInput.new(), 3)
	var state := Keen3OnlineState.of_map(map, map.progress, PackedStringArray())
	var back := Keen3OnlineState.from_numbers(state.to_numbers())
	assert_true(back.view_center.distance_to(map.scroll.center()) < 0.1, "the host's view")
	assert_true(back.messie_position.distance_to(map.messie.position) < 0.1, "Messie's place")
	assert_equal(back.messie_sprite, map.messie.sprite_index(), "her picture")


func test_broken_keen_3_numbers_are_refused() -> void:
	var good := Keen3OnlineState.new().to_numbers()
	var message := Snapshot.new().to_message()
	message.append(PackedFloat32Array(Array(good)))
	assert_true(Snapshot.from_message(message) == null, "not whole numbers")
	var too_many := PackedInt32Array()
	too_many.resize(Snapshot.MAX_EXTRA + 1)
	message[Snapshot.PARTS] = too_many
	assert_true(Snapshot.from_message(message) == null, "too many")
	message.append(good)
	assert_true(Snapshot.from_message(message) == null, "too many parts")
	assert_true(Keen3OnlineState.from_numbers(good.slice(1)) == null, "one short")
	var wild := good.duplicate()
	wild[Keen3OnlineState.ANKH_INDEX] = -50
	wild[Keen3OnlineState.ANKH_INDEX + 1] = 1 << 30
	wild[Keen3OnlineState.MESSIE_INDEX + 2] = 1 << 20
	wild[Keen3OnlineState.MESSIE_INDEX] = -(1 << 20)
	var state := Keen3OnlineState.from_numbers(wild)
	assert_equal(state.ankh_ticks[0], 0, "no time below 0")
	assert_equal(state.ankh_ticks[1], Keen3OnlineState.MAX_ANKH_TICKS, "nor beyond reason")
	assert_equal(state.messie_sprite, -1, "no such picture")
	assert_equal(state.messie_position.x, 0.0, "on the map")


func test_keen_3_host_and_joiner_over_enet() -> void:
	var host := _session_of(KEEN_3)
	var client := _session_of(KEEN_3)
	var host_in := [false]
	var client_got: Array[Array] = []
	host.partner_joined.connect(func(_who: String) -> void: host_in[0] = true)
	client.received.connect(func(message: Array) -> void: client_got.append(message))
	assert_equal(host.host(EnetTransport.new(), "Hosty", "", FINGERPRINT, TEST_PORT), OK, "hosts")
	client.join(EnetTransport.new(), "127.0.0.1", "Joiny", "", FINGERPRINT, TEST_PORT)
	_poll_until([host, client], func() -> bool: return host_in[0] and client.has_partner())
	assert_true(host.has_partner() and client.has_partner(), "both are connected")
	var snapshot := Snapshot.new()
	var state := Keen3OnlineState.new()
	state.done_levels = 0b11
	state.ankh_ticks = PackedInt32Array([100, 200])
	snapshot.extra = state.to_numbers()
	host.send(snapshot.to_message(), false)
	_poll_until([host, client], func() -> bool: return not client_got.is_empty())
	assert_equal(client_got.size(), 1, "the snapshot arrives")
	var got := Snapshot.from_message(client_got[0]) if not client_got.is_empty() else null
	var back := Keen3OnlineState.from_numbers(got.extra) if got != null else null
	assert_true(back != null and back.ankh_ticks[1] == 200, "with Keen 3's numbers")
	client.leave()
	host.leave()
	host.free()
	client.free()


func test_keen_1_player_at_a_keen_3_host_over_enet_switches() -> void:
	var host := _session_of(KEEN_3)
	var client := _session_of(OnlineProtocol.GAME_ID)
	var reasons: Array[String] = []
	client.join_failed.connect(func(reason: String) -> void: reasons.append(reason))
	host.host(EnetTransport.new(), "Hosty", "", FINGERPRINT, TEST_PORT)
	client.join(EnetTransport.new(), "127.0.0.1", "J", "", FINGERPRINT, TEST_PORT)
	_poll_until([host, client], func() -> bool: return not reasons.is_empty())
	assert_equal(reasons, [JoinHandshake.OTHER_GAME], "another game of ours")
	assert_equal(client.host_game_id, KEEN_3, "Keen 3, to switch to")
	assert_true(GameCatalog.for_game_id(client.host_game_id) != null, "a game we know")
	assert_true(not host.has_partner(), "nobody joined")
	client.leave()
	host.leave()
	host.free()
	client.free()


func test_fingerprint_reads_keen_3_level_files() -> void:
	var keen_3 := Keen3Files.locate()
	if keen_3 == null:
		return
	var print_3 := LevelFingerprint.of(keen_3)
	assert_equal(print_3.length(), LevelFingerprint.LENGTH, "a fingerprint")
	var keen_2 := Keen2Files.locate()
	if keen_2 != null:
		assert_true(print_3 != LevelFingerprint.of(keen_2), "not Keen 2's")


func _gate(game_id: String) -> JoinGate:
	var gate := JoinGate.new()
	gate.game_id = game_id
	gate.fingerprint = FINGERPRINT
	return gate


func _ticket(game_id: String) -> JoinTicket:
	var ticket := JoinTicket.new()
	ticket.game_id = game_id
	ticket.fingerprint = FINGERPRINT
	return ticket


func _session_of(game_id: String) -> OnlineSession:
	var session := OnlineSession.new()
	session.game_id = game_id
	return session


func _poll_until(sessions: Array, done: Callable) -> void:
	for attempt in MAX_POLLS:
		for session: OnlineSession in sessions:
			session.poll(POLL_DELTA)
		if done.call():
			return
		OS.delay_msec(POLL_MS)
