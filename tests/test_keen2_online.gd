extends "res://tests/test_case.gd"
## Tests for playing Keen 2 online (milestone B9): each game has its own id,
## so a Keen 1 host and a Keen 2 player do not meet (and are told why), while
## Keen 1's handshake and snapshots stay exactly as they were; Keen 2's
## snapshot carries the saved cities; the Earth exploding and the lights are
## sent; the fingerprint reads Keen 2's own level files.

const KEEN_2 := OnlineProtocol.GAME_ID_KEEN_2
const FINGERPRINT := "abc"


func test_keen_2_player_joins_a_keen_2_host() -> void:
	var gate := _gate(KEEN_2)
	var ticket := _ticket(KEEN_2)
	var step := ticket.answer(gate.begin(1))
	assert_equal(step.problem, "", "the challenge is answered")
	var verdict := gate.judge(1, "player", step.reply)
	assert_true(verdict.admit, "let in")


func test_keen_1_host_and_keen_2_player_do_not_meet() -> void:
	var step := _ticket(KEEN_2).answer(_gate(OnlineProtocol.GAME_ID).begin(1))
	assert_equal(step.problem, JoinHandshake.OTHER_GAME, "the player sees another game")
	var gate := _gate(OnlineProtocol.GAME_ID)
	gate.begin(2)
	var answer := var_to_bytes(
		[KEEN_2, OnlineProtocol.VERSION, FINGERPRINT, "x", PackedByteArray()]
	)
	assert_equal(gate.judge(2, "player", answer).reason, JoinHandshake.OTHER_GAME, "host refuses")
	var stranger := _ticket(KEEN_2).answer(var_to_bytes(["other", 1, PackedByteArray(), false]))
	assert_equal(stranger.problem, JoinHandshake.NOT_OURS, "not ours at all")
	assert_true(not OnlineText.join_failed(JoinHandshake.OTHER_GAME).is_empty(), "a text")


func test_keen_1_handshake_is_unchanged() -> void:
	var nonce := JoinHandshake.make_nonce()
	var expected := var_to_bytes([OnlineProtocol.GAME_ID, OnlineProtocol.VERSION, nonce, true])
	assert_equal(JoinHandshake.challenge(nonce, true), expected, "the challenge")
	assert_equal(
		JoinHandshake.proof(nonce, "pw"),
		JoinHandshake.proof(nonce, "pw", OnlineProtocol.GAME_ID),
		"the proof"
	)
	assert_true(
		JoinHandshake.proof(nonce, "pw") != JoinHandshake.proof(nonce, "pw", KEEN_2),
		"a proof for Keen 1 is no proof for Keen 2"
	)


func test_snapshot_carries_the_cities_and_keen_1_stays_the_same() -> void:
	var snapshot := Snapshot.new()
	snapshot.inventory.has_pogo = true
	snapshot.inventory.keycards[2] = true
	var keen_1_flags := 1 | (1 << 3)
	assert_equal(snapshot.to_message()[2][3], keen_1_flags, "Keen 1's flags as before")
	snapshot.progress_bits = 0b10100101
	var back := Snapshot.from_message(snapshot.to_message())
	assert_true(back != null, "read back")
	assert_equal(back.progress_bits, 0b10100101, "the cities")
	assert_true(back.inventory.has_pogo and back.inventory.keycards[2], "the rest")
	assert_true(not back.inventory.ship_parts.has(true), "no ship parts")


func test_city_bits_follow_the_saved_cities() -> void:
	var progress := Keen2Progress.new()
	progress.complete_level(Keen2Progress.CITY_LEVELS[0])
	progress.complete_level(Keen2Progress.CITY_LEVELS[3])
	assert_equal(Keen2OnlineScreen._city_bits(progress), 0b1001, "London and New York")


func test_steam_lobbies_are_per_game() -> void:
	var keen_2 := SteamLobby.data_for("Billy", false, KEEN_2)
	assert_true(SteamLobby.is_ours(keen_2, KEEN_2), "Keen 2 sees Keen 2's")
	assert_true(not SteamLobby.is_ours(keen_2), "Keen 1 does not")
	assert_true(SteamLobby.is_ours(SteamLobby.data_for("Billy", false)), "Keen 1's as before")


func test_earth_scene_and_lights_event_are_read() -> void:
	var scene := OnlineMessages.scene(3, OnlineMessages.Scene.EARTH_EXPLODES, 81, [])
	var read := OnlineMessages.read_scene(scene)
	assert_equal(read[1], OnlineMessages.Scene.EARTH_EXPLODES, "the Earth exploding")
	var event := OnlineMessages.event(3, OnlineMessages.Event.LIGHTS, 1)
	assert_equal(OnlineMessages.read_event(event), [3, OnlineMessages.Event.LIGHTS, 1], "lights")


func test_fingerprint_reads_keen_2_level_files() -> void:
	var keen_2 := Keen2Files.locate()
	if keen_2 == null:
		return
	var print_2 := LevelFingerprint.of(keen_2)
	assert_equal(print_2.length(), LevelFingerprint.LENGTH, "a fingerprint")
	var keen_1 := GameFiles.locate()
	if keen_1 != null:
		assert_true(print_2 != LevelFingerprint.of(keen_1), "not Keen 1's")


func test_keen_1_fingerprint_is_unchanged() -> void:
	var keen_1 := GameFiles.locate()
	if keen_1 == null:
		return
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for number in keen_1.level_numbers():
		var data := keen_1.read(GameFiles.level_file_name(number))
		context.update(("%d:%d;" % [number, data.size()]).to_utf8_buffer())
		context.update(data)
	var before := context.finish().hex_encode().left(LevelFingerprint.LENGTH)
	assert_equal(LevelFingerprint.of(keen_1), before, "as it was")


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
