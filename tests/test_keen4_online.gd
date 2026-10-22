extends "res://tests/test_case.gd"
## Tests for playing Keen 4 online (milestone D12): Keen 4 is one of our
## games (its id last in [constant OnlineProtocol.GAME_IDS]), so a Keen 4
## player meets a Keen 4 host, a player of Keen 1, 2 or 3 who knocks at a
## Keen 4 host learns to switch to it and the other way round, by IP and in
## Steam's list; Galaxy's message kinds come after Keen 1-3's; a real host
## and joiner over ENet on this machine, and a Keen 1 player knocking at a
## Keen 4 host there; the fingerprint of Keen 4's maps (GAMEMAPS with its
## headers).

const KEEN_4 := OnlineProtocol.GAME_ID_KEEN_4
const OTHERS: Array[String] = [
	OnlineProtocol.GAME_ID, OnlineProtocol.GAME_ID_KEEN_2, OnlineProtocol.GAME_ID_KEEN_3
]
const FINGERPRINT := "fedcba9876543210"
## A port next to the game's, apart from the other suites' test ports.
const TEST_PORT := OnlineProtocol.GAME_PORT + 14
const MAX_POLLS := 400
const POLL_MS := 5
const POLL_DELTA := 0.005


func test_keen_4_is_one_of_our_games() -> void:
	assert_equal(KEEN_4, "commanderperfect-keen4", "its id")
	assert_equal(Keen4Files.GAME_ID, KEEN_4, "the same as Keen4Files'")
	assert_equal(OnlineProtocol.GAME_IDS, OTHERS + [KEEN_4], "last of the four")
	var game := GameCatalog.for_game_id(KEEN_4)
	assert_true(game != null, "the catalog knows it")
	assert_equal(game.scene, GameLaunch.KEEN_4_SCENE, "its scene")
	assert_equal(game.title, "Keen 4", "its name in Steam's list")


func test_galaxy_message_kinds_come_after_the_others() -> void:
	var kinds := OnlineProtocol.Message
	assert_equal(
		[kinds.GALAXY_SCENE, kinds.GALAXY_TILE, kinds.GALAXY_SNAPSHOT], [6, 7, 8], "at the end"
	)


func test_keen_4_player_joins_a_keen_4_host() -> void:
	var gate := _gate(KEEN_4)
	var step := _ticket(KEEN_4).answer(gate.begin(1))
	assert_equal(step.problem, "", "the challenge is answered")
	assert_true(gate.judge(1, "player", step.reply).admit, "let in")


func test_keen_4_with_a_password() -> void:
	var gate := _gate(KEEN_4)
	gate.password = "galaxy"
	var ticket := _ticket(KEEN_4)
	ticket.password = "galaxy"
	var step := ticket.answer(gate.begin(1))
	assert_true(gate.judge(1, "player", step.reply).admit, "the right password")
	var wrong := _ticket(KEEN_4)
	wrong.password = "vorticon"
	var other := gate.judge(2, "other", wrong.answer(gate.begin(2)).reply)
	assert_true(not other.admit, "a wrong one is refused")
	assert_equal(other.reason, JoinHandshake.WRONG_PASSWORD, "and told so")


func test_players_of_another_keen_learn_to_switch_to_keen_4_and_back() -> void:
	for other in OTHERS:
		var ticket := _ticket(other)
		var step := ticket.answer(_gate(KEEN_4).begin(1))
		assert_equal(step.problem, JoinHandshake.OTHER_GAME, "%s sees another game" % other)
		assert_equal(ticket.host_game_id, KEEN_4, "%s: Keen 4, to switch to" % other)
		var back := _ticket(KEEN_4)
		assert_equal(back.answer(_gate(other).begin(1)).problem, JoinHandshake.OTHER_GAME, "back")
		assert_equal(back.host_game_id, other, "Keen 4 switches to %s" % other)
		assert_true(GameCatalog.for_game_id(other) != null, "%s is a game we know" % other)
	var gate := _gate(KEEN_4)
	gate.begin(2)
	var answer := var_to_bytes(
		[OnlineProtocol.GAME_ID_KEEN_3, OnlineProtocol.VERSION, FINGERPRINT, "x", PackedByteArray()]
	)
	assert_equal(gate.judge(2, "p", answer).reason, JoinHandshake.OTHER_GAME, "host refuses")


func test_a_join_for_keen_4_is_handed_over_once() -> void:
	var join := GameLaunch.OnlineJoin.new()
	join.address = "127.0.0.1"
	GameLaunch.request_join(join)
	assert_true(GameLaunch.take_join_request() == join, "handed to Keen 4's screen")
	assert_true(GameLaunch.take_join_request() == null, "only once")


func test_steam_lists_keen_4_lobbies() -> void:
	var lobby := SteamLobby.data_for("Billy", false, KEEN_4)
	assert_true(SteamLobby.is_any_ours(lobby), "one of ours")
	assert_equal(SteamLobby.game_of(lobby), KEEN_4, "Keen 4's lobby")
	assert_true(SteamLobby.is_ours(lobby, KEEN_4), "Keen 4 sees it as its own")
	for other in OTHERS:
		assert_true(not SteamLobby.is_ours(lobby, other), "%s does not" % other)
		assert_true(not SteamLobby.is_ours(SteamLobby.data_for("B", false, other), KEEN_4), "nor")


func test_keen_4_host_and_joiner_over_enet() -> void:
	var host := _session_of(KEEN_4)
	var client := _session_of(KEEN_4)
	var host_in := [false]
	var client_got: Array[Array] = []
	var host_got: Array[Array] = []
	host.partner_joined.connect(func(_who: String) -> void: host_in[0] = true)
	client.received.connect(func(message: Array) -> void: client_got.append(message))
	host.received.connect(func(message: Array) -> void: host_got.append(message))
	assert_equal(host.host(EnetTransport.new(), "Hosty", "", FINGERPRINT, TEST_PORT), OK, "hosts")
	client.join(EnetTransport.new(), "127.0.0.1", "Joiny", "", FINGERPRINT, TEST_PORT)
	_poll_until([host, client], func() -> bool: return host_in[0] and client.has_partner())
	assert_true(host.has_partner() and client.has_partner(), "both are connected")
	var scene := [OnlineProtocol.Message.GALAXY_SCENE, 1, 2, 4, PackedInt32Array([1, 3, 4, 210])]
	host.send(scene, true)
	var tile := [OnlineProtocol.Message.GALAXY_TILE, 1, 2, 5, 6, 1234]
	host.send(tile, true)
	_poll_until([host, client], func() -> bool: return client_got.size() >= 2)
	assert_equal(client_got.size(), 2, "the scene and the tile arrive")
	if client_got.size() == 2:
		assert_equal(client_got[0], scene, "the scene as sent")
		assert_equal(client_got[1], tile, "the tile as sent")
	var up := KeenInput.new()
	up.vertical = -1
	client.send(OnlineMessages.input(OnlineInput.to_bits(up)), true)
	_poll_until([host, client], func() -> bool: return not host_got.is_empty())
	var bits := OnlineMessages.read_input(host_got[0]) if not host_got.is_empty() else -1
	assert_equal(OnlineInput.from_bits(bits).vertical, -1, "the joiner's up reaches the host")
	client.leave()
	host.leave()
	host.free()
	client.free()


func test_a_keen_1_player_at_a_keen_4_host_over_enet_switches() -> void:
	for other in OTHERS:
		var host := _session_of(KEEN_4)
		var client := _session_of(other)
		var reasons: Array[String] = []
		client.join_failed.connect(func(reason: String) -> void: reasons.append(reason))
		host.host(EnetTransport.new(), "Hosty", "", FINGERPRINT, TEST_PORT)
		client.join(EnetTransport.new(), "127.0.0.1", "J", "", FINGERPRINT, TEST_PORT)
		_poll_until([host, client], func() -> bool: return not reasons.is_empty())
		assert_equal(reasons, [JoinHandshake.OTHER_GAME], "%s: another game of ours" % other)
		assert_equal(client.host_game_id, KEEN_4, "%s: Keen 4, to switch to" % other)
		assert_true(not host.has_partner(), "nobody joined")
		client.leave()
		host.leave()
		host.free()
		client.free()


func test_a_keen_4_player_with_other_maps_is_refused() -> void:
	var gate := _gate(KEEN_4)
	var ticket := _ticket(KEEN_4)
	ticket.fingerprint = "0000000000000000"
	var verdict := gate.judge(1, "p", ticket.answer(gate.begin(1)).reply)
	assert_true(not verdict.admit, "other maps")
	assert_equal(verdict.reason, JoinHandshake.OTHER_DATA, "said so")


func test_fingerprint_of_keen_4_maps() -> void:
	assert_equal(GalaxyFingerprint.of(null), "", "nothing without maps")
	var files := Keen4Files.locate()
	if files == null:
		return
	var data := Keen4Episode.load_data(files)
	var print_4 := GalaxyFingerprint.of(data.maps)
	assert_equal(print_4.length(), LevelFingerprint.LENGTH, "a fingerprint")
	assert_equal(GalaxyFingerprint.of(Keen4Episode.load_data(files).maps), print_4, "the same")
	var changed := Keen4Episode.load_data(files).maps
	changed.data[changed.data.size() / 2] ^= 1
	assert_true(GalaxyFingerprint.of(changed) != print_4, "changed maps, another fingerprint")
	var keen_3 := Keen3Files.locate()
	if keen_3 != null:
		assert_true(print_4 != LevelFingerprint.of(keen_3), "not Keen 3's")


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
