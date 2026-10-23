extends "res://tests/test_case.gd"
## Tests for playing Keen 5 online (milestone E11): Keen 5 is the last of
## our games ([constant OnlineProtocol.GAME_IDS], after Keen 4), so a Keen
## 5 player meets a Keen 5 host, and a player of Keen 1-4 who knocks at a
## Keen 5 host learns to switch to it and the other way round, by IP (also
## over ENet on this machine) and in Steam's list; the Galaxy message
## kinds keep their numbers; Keen 5's numbers in a snapshot
## ([Keen5OnlineState] on [GalaxyOnlineState]) go there and back, and the
## bytes of a Keen 5 snapshot are fixed; the fingerprint of Keen 5's maps
## (with the player's files) is its own.

const KEEN_4 := OnlineProtocol.GAME_ID_KEEN_4
const KEEN_5 := OnlineProtocol.GAME_ID_KEEN_5
const OTHERS: Array[String] = [
	OnlineProtocol.GAME_ID,
	OnlineProtocol.GAME_ID_KEEN_2,
	OnlineProtocol.GAME_ID_KEEN_3,
	OnlineProtocol.GAME_ID_KEEN_4,
]
const FINGERPRINT := "0123456789abcdef"
## A port next to the game's, apart from the other suites' test ports.
const TEST_PORT := OnlineProtocol.GAME_PORT + 15
const MAX_POLLS := 400
const POLL_MS := 5
const POLL_DELTA := 0.005
const SCORE := 123450
const NEXT_LIFE := 140000
const GEMS: Array[int] = [1, 0, 2, 1]
const FUSE_LEVEL := 4
const KORATH_LEVEL := 13
const DOOR_LEVEL := 2
## The bytes (hex of var_to_bytes) of the snapshot of
## [method _fixed_snapshot], as E11 made it.
const SNAPSHOT_HEX := (
	"1c0000000a00000002000000080000000200000007000000020000000004000002000000a0020000"
	+ "1e0000000c00000000080000000200004001000005000000000a000000020000400100000a000000"
	+ "000c00006000000013000000000000001d0000000200000005910000020000000200000002000000"
	+ "640000001e000000030000002000000004000000010000001e0000000c0000003ae2010003000000"
	+ "050000000000000000000000204e0000140000000100000001000000020000001000000000000000"
)


func test_keen_5_is_the_last_of_our_games() -> void:
	assert_equal(KEEN_5, "commanderperfect-keen5", "its id")
	assert_equal(Keen5Files.GAME_ID, KEEN_5, "the same as Keen5Files'")
	assert_equal(Keen5Episode.game_rules().game_id, KEEN_5, "and the rules'")
	assert_equal(OnlineProtocol.GAME_IDS, OTHERS + [KEEN_5], "last of the five")
	var game := GameCatalog.for_game_id(KEEN_5)
	assert_true(game != null, "the catalog knows it")
	assert_equal(game.scene, GameLaunch.KEEN_5_SCENE, "its scene")
	assert_equal(game.title, "Keen 5", "its name in Steam's list")


func test_galaxy_message_kinds_keep_their_numbers() -> void:
	var kinds := OnlineProtocol.Message
	assert_equal(
		[kinds.GALAXY_SCENE, kinds.GALAXY_TILE, kinds.GALAXY_SNAPSHOT], [6, 7, 8], "as in D12"
	)
	assert_equal(kinds.size(), 9, "no new kind: Keen 5 needs none")
	assert_equal(GalaxyOnlineMessages.Scene.size(), 3, "nor a new scene")


func test_keen_5_player_joins_a_keen_5_host() -> void:
	var gate := _gate(KEEN_5)
	var step := _ticket(KEEN_5).answer(gate.begin(1))
	assert_equal(step.problem, "", "the challenge is answered")
	assert_true(gate.judge(1, "player", step.reply).admit, "let in")


func test_players_of_keen_1_to_4_learn_to_switch_to_keen_5_and_back() -> void:
	for other in OTHERS:
		var ticket := _ticket(other)
		var step := ticket.answer(_gate(KEEN_5).begin(1))
		assert_equal(step.problem, JoinHandshake.OTHER_GAME, "%s sees another game" % other)
		assert_equal(ticket.host_game_id, KEEN_5, "%s: Keen 5, to switch to" % other)
		var back := _ticket(KEEN_5)
		assert_equal(back.answer(_gate(other).begin(1)).problem, JoinHandshake.OTHER_GAME, "back")
		assert_equal(back.host_game_id, other, "Keen 5 switches to %s" % other)
	var gate := _gate(KEEN_5)
	gate.begin(2)
	var answer := var_to_bytes(
		[KEEN_4, OnlineProtocol.VERSION, FINGERPRINT, "x", PackedByteArray()]
	)
	assert_equal(gate.judge(2, "p", answer).reason, JoinHandshake.OTHER_GAME, "host refuses Keen 4")


func test_steam_lists_keen_5_lobbies() -> void:
	var lobby := SteamLobby.data_for("Billy", false, KEEN_5)
	assert_true(SteamLobby.is_any_ours(lobby), "one of ours")
	assert_equal(SteamLobby.game_of(lobby), KEEN_5, "Keen 5's lobby")
	assert_true(SteamLobby.is_ours(lobby, KEEN_5), "Keen 5 sees it as its own")
	for other in OTHERS:
		assert_true(not SteamLobby.is_ours(lobby, other), "%s does not" % other)


func test_a_keen_4_player_at_a_keen_5_host_over_enet_switches_and_back() -> void:
	for pair in [[KEEN_5, KEEN_4], [KEEN_4, KEEN_5]]:
		var host_game: String = pair[0]
		var host := _session_of(host_game)
		var client := _session_of(pair[1])
		var reasons: Array[String] = []
		client.join_failed.connect(func(reason: String) -> void: reasons.append(reason))
		host.host(EnetTransport.new(), "Hosty", "", FINGERPRINT, TEST_PORT)
		client.join(EnetTransport.new(), "127.0.0.1", "J", "", FINGERPRINT, TEST_PORT)
		_poll_until([host, client], func() -> bool: return not reasons.is_empty())
		assert_equal(reasons, [JoinHandshake.OTHER_GAME], "%s at %s" % [pair[1], host_game])
		assert_equal(client.host_game_id, host_game, "to switch to %s" % host_game)
		assert_true(not host.has_partner(), "nobody joined")
		var game := GameCatalog.for_game_id(client.host_game_id)
		assert_true(game != null and game.scene.ends_with(".tscn"), "the scene to switch to")
		client.leave()
		host.leave()
		host.free()
		client.free()


func test_the_shared_numbers_go_there_and_back() -> void:
	var state := GalaxyOnlineState.new()
	var carried := _inventory(GalaxyInventory.new())
	var progress := GalaxyProgress.new()
	progress.mark_done(1)
	progress.mark_done(17)
	var numbers := state.pack(carried, progress, GalaxyDifficulty.Level.HARD)
	assert_equal(numbers.size(), GalaxyOnlineState.Field.size(), "no extra numbers")
	assert_true(state.is_sane(numbers), "sane")
	var shown := GalaxyInventory.new()
	var shown_progress := GalaxyProgress.new()
	shown_progress.mark_done(5)
	state.unpack(numbers, shown, shown_progress)
	_assert_same_inventory(shown, carried)
	assert_equal(shown_progress.done_levels(), PackedInt32Array([1, 17]), "exactly the host's")


func test_keen_5_numbers_go_there_and_back() -> void:
	var state := Keen5OnlineState.new()
	var carried := _inventory(Keen5Inventory.new_game()) as Keen5Inventory
	carried.keycard = true
	carried.fuses_remaining = 3
	var progress := Keen5Progress.new()
	progress.mark_done(DOOR_LEVEL)
	progress.mark_done(FUSE_LEVEL, Keen5Progress.DONE_BY_FUSE)
	progress.mark_done(KORATH_LEVEL, Keen5Progress.DONE_BY_FUSE)
	progress.korath_arrival = true
	var numbers := state.pack(carried, progress, GalaxyDifficulty.Level.EASY)
	assert_equal(numbers.size(), GalaxyOnlineState.Field.size() + 4, "four of Keen 5's own")
	assert_true(numbers.size() <= GalaxySnapshot.MAX_EXTRA, "room in a snapshot")
	var shown := Keen5Inventory.new_game()
	var shown_progress := Keen5Progress.new()
	state.unpack(numbers, shown, shown_progress)
	_assert_same_inventory(shown, carried)
	assert_true(shown.keycard, "the keycard")
	assert_equal(shown.fuses_remaining, 3, "the fuses still to break")
	assert_equal(shown_progress.done_value(DOOR_LEVEL), Keen5Progress.DONE, "a door: 1")
	assert_equal(shown_progress.done_value(FUSE_LEVEL), Keen5Progress.DONE_BY_FUSE, "a fuse: 14")
	assert_true(shown_progress.korath_fuse_broken(), "the secret end")
	assert_true(shown_progress.korath_arrival, "the arrival on Korath III")
	carried.keycard = false
	progress.korath_arrival = false
	state.unpack(state.pack(carried, progress, 0), shown, shown_progress)
	assert_true(not shown.keycard and not shown_progress.korath_arrival, "and gone again")


func test_insane_numbers_change_nothing() -> void:
	var state := Keen5OnlineState.new()
	var carried := Keen5Inventory.new_game()
	var progress := Keen5Progress.new()
	var good := state.pack(carried, progress, 0)
	for broken in [
		PackedInt32Array(),
		good.slice(0, good.size() - 1),
		_with(good, GalaxyOnlineState.Field.SCORE, -1),
		_with(good, GalaxyOnlineState.Field.DIFFICULTY, 9),
		_with(good, GalaxyOnlineState.Field.size() + Keen5OnlineState.Extra.KEYCARD, 2),
		_with(good, GalaxyOnlineState.Field.size() + Keen5OnlineState.Extra.FUSES_REMAINING, -3),
	]:
		assert_true(not state.is_sane(broken), "refused: %s" % broken)
		var shown := Keen5Inventory.new_game()
		shown.score = SCORE
		state.unpack(broken, shown, progress)
		assert_equal(shown.score, SCORE, "nothing taken over")
	assert_true(
		not GalaxyOnlineState.new().is_sane(good), "Keen 5's numbers are not the shared ones'"
	)


func test_the_bytes_of_a_keen_5_snapshot() -> void:
	var snapshot := _fixed_snapshot()
	var message := snapshot.to_message()
	assert_equal(var_to_bytes(message).hex_encode(), SNAPSHOT_HEX, "the bytes as E11 made them")
	var back := GalaxySnapshot.from_message(message)
	assert_true(back != null, "read back")
	if back == null:
		return
	assert_equal(back.extra, snapshot.extra, "Keen 5's numbers")
	assert_equal(back.box, snapshot.box, "the fuse message's name")
	var shown := Keen5Inventory.new_game()
	var shown_progress := Keen5Progress.new()
	Keen5OnlineState.new().unpack(back.extra, shown, shown_progress)
	assert_true(shown.keycard, "the keycard arrives")


func test_fingerprint_of_keen_5_maps() -> void:
	var files := Keen5Files.locate()
	if files == null:
		return
	var print_5 := GalaxyFingerprint.of(Keen5Episode.load_data(files).maps)
	assert_equal(print_5.length(), LevelFingerprint.LENGTH, "a fingerprint")
	assert_equal(GalaxyFingerprint.of(Keen5Episode.load_data(files).maps), print_5, "the same")
	var keen_4 := Keen4Files.locate()
	if keen_4 != null:
		var print_4 := GalaxyFingerprint.of(Keen4Episode.load_data(keen_4).maps)
		assert_true(print_5 != print_4, "not Keen 4's")


## A snapshot made of fixed numbers: two figures (the host's Keen and
## player 2's), two sounds, a song, the fuse message as the box, Keen 5's
## numbers.
static func _fixed_snapshot() -> GalaxySnapshot:
	var snapshot := GalaxySnapshot.new()
	snapshot.scene = 7
	snapshot.view = Vector2i(0x400, 0x2A0)
	snapshot.add_figure(Vector2i(0x800, 0x200), 0x140, 1 | GalaxySnapshot.HOST_KEEN)
	snapshot.add_figure(Vector2i(0xA00, 0x200), 0x140, 2 | GalaxySnapshot.PARTNER_KEEN)
	snapshot.add_figure(Vector2i(0xC00, 0x60), 0x13, 0)
	snapshot.sounds = PackedByteArray([5, 17 | GalaxySnapshot.INTERRUPT])
	snapshot.song = 2
	snapshot.brightness = GalaxySnapshot.FULL_BRIGHTNESS
	snapshot.box = PackedInt32Array([Keen5BoxNames.FUSE, FUSE_LEVEL, 1])
	var carried := Keen5Inventory.new_game()
	carried.score = SCORE
	carried.keycard = true
	carried.fuses_remaining = 2
	var progress := Keen5Progress.new()
	progress.mark_done(DOOR_LEVEL)
	progress.mark_done(FUSE_LEVEL, Keen5Progress.DONE_BY_FUSE)
	snapshot.extra = Keen5OnlineState.new().pack(carried, progress, GalaxyDifficulty.DEFAULT)
	return snapshot


func _inventory(carried: GalaxyInventory) -> GalaxyInventory:
	carried.score = SCORE
	carried.lives = 4
	carried.shots = 17
	carried.drops = 42
	carried.next_life_at = NEXT_LIFE
	for colour in GEMS.size():
		carried.gems[colour] = GEMS[colour]
	return carried


func _assert_same_inventory(shown: GalaxyInventory, carried: GalaxyInventory) -> void:
	assert_equal(shown.score, carried.score, "the score")
	assert_equal(shown.lives, carried.lives, "the lives")
	assert_equal(shown.shots, carried.shots, "the charges")
	assert_equal(shown.drops, carried.drops, "the drops")
	assert_equal(shown.next_life_at, carried.next_life_at, "the next extra life")
	assert_equal(shown.gems, carried.gems, "the gems")


static func _with(numbers: PackedInt32Array, index: int, value: int) -> PackedInt32Array:
	var changed := numbers.duplicate()
	changed[index] = value
	return changed


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
