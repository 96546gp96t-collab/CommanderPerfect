extends "res://tests/test_case.gd"
## Tests for what goes over the network once two play online: the picture
## of a tick ([Snapshot]) there and back, the joiner's copies of the
## actors, his buttons, the queue of pictures, the other messages, where the
## joiner's Keen appears, the arrow toward the other player, Steam lobby
## data, addresses and the ping. In small hand-made levels (no game data).

const Fixtures := preload("res://tests/fixtures.gd")
const SETTLE_TICKS := 120
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"##############################",
]
const START_CELL := Vector2i(6, 12)


func test_snapshot_of_a_level_there_and_back() -> void:
	var session := _session(FIELD)
	session.add_player(session.keen.position + Vector2(40, 0))
	session.inventory.score = 1234
	session.inventory.charges = 3
	session.inventory.keycards[2] = true
	session.inventory.ship_parts[1] = true
	session.inventory.has_pogo = true
	session.add_actor(RaygunShot.create(session.keen.position, 1))
	session.add_actor(OpeningDoor.create(Vector2i(3, 4), PackedInt32Array([7, 7])))
	var maker := SnapshotMaker.new()
	var sent := maker.of_level(session, 5, session.inventory, PackedByteArray([Sound.Id.KEEN_JUMP]))
	var got := Snapshot.from_message(_over_the_wire(sent.to_message()))
	assert_true(got != null, "it arrives whole")
	assert_equal(got.scene, 5, "scene")
	assert_equal(got.keens.size(), 2, "both Keens")
	assert_equal(got.keens[1].position, session.keens[1].position, "player 2's place")
	assert_equal(got.keens[0].sprite, session.keen.sprite_index(), "sprite")
	assert_equal(got.actors.size(), 1, "the shot")
	assert_equal(got.doors.size(), 1, "the door")
	assert_equal(got.doors[0].tiles, PackedInt32Array([7, 7]), "door tiles")
	assert_equal(got.inventory.score, 1234, "score")
	assert_equal(got.inventory.charges, 3, "charges")
	assert_equal(got.inventory.keycards, [false, false, true, false], "keycards")
	assert_equal(got.inventory.ship_parts, [false, true, false, false], "ship parts")
	assert_true(got.inventory.has_pogo, "pogo")
	assert_equal(got.sounds, PackedByteArray([Sound.Id.KEEN_JUMP]), "sounds")


func test_snapshot_of_the_map() -> void:
	var map_keen := MapKeen.create(Fixtures.create_collision(FIELD), Vector2(30, 40))
	var got := Snapshot.from_message(
		SnapshotMaker.new().of_map(map_keen, 1, Inventory.new(), PackedByteArray()).to_message()
	)
	assert_equal(got.keens.size(), 1, "one Keen walks there")
	assert_equal(got.keens[0].position, Vector2(30, 40), "where he is")
	map_keen.hidden = true
	got = Snapshot.from_message(
		SnapshotMaker.new().of_map(map_keen, 1, Inventory.new(), PackedByteArray()).to_message()
	)
	assert_equal(got.keens[0].sprite, -1, "not drawn while he teleports")


func test_broken_snapshots_are_refused() -> void:
	var good := Snapshot.new().to_message()
	assert_true(Snapshot.from_message(good) != null, "an empty one is fine")
	var broken := good.duplicate()
	broken[4] = PackedFloat32Array([1, 2, 3])
	assert_true(Snapshot.from_message(broken) == null, "a Keen with too few numbers")
	broken = good.duplicate()
	broken[6] = PackedInt32Array([1, 0, 0, 16, 99])
	assert_true(Snapshot.from_message(broken) == null, "a door with too many tiles")
	broken = good.duplicate()
	broken[2] = "score"
	assert_true(Snapshot.from_message(broken) == null, "the wrong type")
	assert_true(Snapshot.from_message([OnlineProtocol.Message.SNAPSHOT]) == null, "too short")


func test_actors_keep_their_copy_from_tick_to_tick() -> void:
	var session := _session(FIELD)
	session.add_actor(RaygunShot.create(session.keen.position, 1))
	var maker := SnapshotMaker.new()
	var mirrors := MirrorActors.new()
	var first := mirrors.update(maker.of_level(session, 1, session.inventory, PackedByteArray()))
	session.step(KeenInput.new())
	var second := mirrors.update(maker.of_level(session, 1, session.inventory, PackedByteArray()))
	assert_equal(first.size(), 1, "one copy")
	assert_true(first[0] == second[0], "the same copy, so its sprite glides")
	assert_equal(second[0].position, session.actors[0].position, "moved along")
	assert_equal(second[0].sprite_index(), session.actors[0].sprite_index(), "same sprite")


func test_buttons_there_and_back() -> void:
	var input := KeenInput.create(-1, true, false, true)
	input.vertical = 1
	var back := OnlineInput.from_bits(OnlineInput.to_bits(input))
	assert_equal(
		[back.direction, back.vertical, back.jump, back.pogo, back.fire],
		[-1, 1, true, false, true],
		"the same buttons"
	)


func test_a_quick_tap_lasts_a_tick() -> void:
	var queue := OnlineInput.new()
	queue.receive(OnlineInput.JUMP)
	queue.receive(0)
	assert_true(queue.next().jump, "the press comes first")
	assert_true(not queue.next().jump, "then the release")
	assert_true(not queue.next().jump, "and it stays released")


func test_too_many_button_changes_are_dropped() -> void:
	var queue := OnlineInput.new()
	for change in OnlineInput.MAX_QUEUED * 2:
		queue.receive(change % 2)
	var count := 0
	while queue._queue.size() > 0:
		queue.next()
		count += 1
	assert_equal(count, OnlineInput.MAX_QUEUED, "a flood is cut off")


func test_snapshot_buffer_keeps_a_small_reserve() -> void:
	var buffer := SnapshotBuffer.new()
	buffer.push(Snapshot.new())
	assert_true(buffer.take() == null, "waits for a reserve")
	buffer.push(Snapshot.new())
	assert_true(buffer.take() != null, "then shows one per tick")
	assert_true(buffer.take() != null, "and the next")
	assert_true(buffer.take() == null, "ran dry: keeps the last picture")
	for count in SnapshotBuffer.MOST + 4:
		buffer.push(Snapshot.new())
	assert_equal(buffer.size(), SnapshotBuffer.MOST, "never far behind")


func test_messages_there_and_back() -> void:
	var tiles := PackedInt32Array([3, 4, 143])
	var scene := OnlineMessages.read_scene(
		_over_the_wire(OnlineMessages.scene(7, OnlineMessages.Scene.LEVEL, 3, tiles))
	)
	assert_equal(scene, [7, OnlineMessages.Scene.LEVEL, 3, tiles], "scene")
	var tile := OnlineMessages.read_tile(OnlineMessages.tile(7, Vector2i(5, 6), 99))
	assert_equal(tile, [7, Vector2i(5, 6), 99], "tile")
	var event := OnlineMessages.read_event(
		OnlineMessages.event(7, OnlineMessages.Event.MESSAGE, "Level 3 completed!\n")
	)
	assert_equal(event, [7, OnlineMessages.Event.MESSAGE, "Level 3 completed!"], "plain text")
	assert_equal(OnlineMessages.read_input(OnlineMessages.input(5)), 5, "input")
	var view := Rect2(10, 20, 426, 200)
	assert_equal(OnlineMessages.read_view(OnlineMessages.view(view)), view, "view")


func test_broken_messages_are_refused() -> void:
	assert_equal(OnlineMessages.read_scene([0, 1, 99, 0, PackedInt32Array()]), [], "unknown kind")
	assert_equal(
		OnlineMessages.read_scene([0, 1, 1, 0, PackedInt32Array([1, 2])]), [], "half a tile"
	)
	assert_equal(OnlineMessages.read_tile([1, 1, -5, 2, 3]), [], "a cell outside")
	assert_equal(OnlineMessages.read_event([2, 1, 1, "three"]), [], "lives that are not a number")
	assert_equal(OnlineMessages.read_input([4, "x"]), -1, "input that is not a number")
	assert_true(not OnlineMessages.read_view([5, 1, 2, "a", 4]).has_area(), "a view of text")


func test_changed_tiles_are_found() -> void:
	var original := Fixtures.create_level(FIELD)
	var level := Fixtures.create_level(FIELD)
	assert_equal(OnlinePlay.changed_tiles(level, original), PackedInt32Array(), "nothing yet")
	level.set_tile(Vector2i(4, 5), Fixtures.LOLLIPOP)
	assert_equal(
		OnlinePlay.changed_tiles(level, original),
		PackedInt32Array([4, 5, Fixtures.LOLLIPOP]),
		"one tile"
	)


func test_joining_keen_appears_beside_the_host() -> void:
	var session := _session(FIELD)
	session.keen.facing = 1
	var at := OnlineSpawn.beside(session, session.keen)
	assert_true(at.x > session.keen.position.x, "in front of him")
	assert_equal(at.y, session.keen.position.y, "on the same floor")


func test_joining_keen_appears_on_the_other_side_of_a_wall() -> void:
	var rows := FIELD.duplicate()
	rows[12] = ".......#......................"
	rows[13] = ".......#......................"
	var session := _session(rows)
	session.keen.facing = 1
	var at := OnlineSpawn.beside(session, session.keen)
	assert_true(at.x < session.keen.position.x, "behind him, not in the wall")


func test_arrow_points_to_a_partner_out_of_sight() -> void:
	var view := Rect2(0, 0, 320, 200)
	assert_equal(PartnerArrow.place(view, Vector2(100, 100)), [], "in sight: no arrow")
	var right := PartnerArrow.place(view, Vector2(1000, 100))
	assert_equal(right[0], Vector2(320 - PartnerArrow.MARGIN, 100), "at the right edge")
	assert_equal(right[1], Vector2.RIGHT, "pointing right")
	var above := PartnerArrow.place(view, Vector2(160, -500))
	assert_equal(above[0], Vector2(160, PartnerArrow.MARGIN), "at the top edge")


func test_steam_lobby_data() -> void:
	var data := SteamLobby.data_for("Billy", true)
	assert_true(SteamLobby.is_ours(data), "ours")
	assert_true(SteamLobby.is_locked(data), "with a password")
	assert_true(not data.values().has("secret"), "never the password itself")
	assert_equal(SteamLobby.described(data, 1), "Billy (1/2) *", "a line for the list")
	data[SteamLobby.GAME_KEY] = "spacewar"
	assert_true(not SteamLobby.is_ours(data), "somebody else's game")
	assert_equal(SteamLobby.lobby_of_friend({"id": 480, "lobby": 77}, 480), 77, "a friend's lobby")
	assert_equal(SteamLobby.lobby_of_friend({"id": 9, "lobby": 77}, 480), 0, "another game")


func test_addresses() -> void:
	assert_equal(
		HostAddresses.private_ipv4(["127.0.0.1", "192.168.1.42", "fe80::1", "10.0.0.2", "8.8.8.8"]),
		PackedStringArray(["10.0.0.2", "192.168.1.42"]),
		"the home network's"
	)
	assert_true(HostAddresses.is_public_ipv4("84.25.13.7"), "public")
	assert_true(not HostAddresses.is_public_ipv4("192.168.1.1"), "private")
	assert_true(not HostAddresses.is_public_ipv4("<b>hi</b>"), "not an address")


func test_ping_is_a_pc_speaker_sound() -> void:
	var divisors := PingSound.divisors()
	assert_equal(divisors.size(), PingSound.TONES.size() * PingSound.STEPS_PER_TONE, "length")
	assert_true(divisors[0] > divisors[-1], "rising")
	assert_true(PingSound.render().data.size() > 0, "it renders")


func test_level_fingerprint_needs_files() -> void:
	assert_equal(LevelFingerprint.of(null), "", "nothing without files")


func _session(rows: PackedStringArray) -> LevelSession:
	var border := Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)
	var session := (
		LevelSession
		. create(
			Fixtures.create_level(rows),
			Fixtures.create_properties(),
			Inventory.new(),
			Vector2((START_CELL + border) * EgaGraphics.TILE_SIZE),
		)
	)
	for tick in SETTLE_TICKS:
		session.step(KeenInput.new())
	return session


## [param message] as the other side gets it.
func _over_the_wire(message: Array) -> Array:
	return bytes_to_var(var_to_bytes(message))
