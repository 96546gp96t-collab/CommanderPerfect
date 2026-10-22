extends RefCounted
## Fixture for tests/test_keen4_online_bytes.gd: Keen 1, 2 and 3's online
## messages built from fixed numbers, and their bytes as they were at the
## start of milestone D12 (commit 1a95c95, made by running [method build]
## there). D12 adds Keen 4's messages; these must stay byte for byte the
## same. Nothing here comes from the game files.

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
const NONCE_BYTE := 7
const SCENE_ID := 9
const LEVEL_NUMBER := 4

## The bytes (hex of var_to_bytes) of each message of [method build] at
## commit 1a95c95; filled in by running the builder there.
const GOLDEN: Dictionary[String, String] = {
	"snapshot_keen1_hand":
	(
		"1c00000007000000020000000300000002000000090000001e00000004000000a87a000005000000"
		+ "06000000930000001d0000000200000005030000200000000a000000000028410000a2410000a040"
		+ "000040410000000000004a420000a2410000c040000040410000803f200000000400000000000040"
		+ "0000f04100002042000010411e000000070000000300000040000000600000001400000002000000"
		+ "0700000008000000"
	),
	"snapshot_keen2_progress":
	(
		"1c00000007000000020000000300000002000000090000001e00000004000000a87a000005000000"
		+ "06000000931600001d0000000200000005030000200000000a000000000028410000a2410000a040"
		+ "000040410000000000004a420000a2410000c040000040410000803f200000000400000000000040"
		+ "0000f04100002042000010411e000000070000000300000040000000600000001400000002000000"
		+ "0700000008000000"
	),
	"snapshot_keen3_extra":
	(
		"1c00000008000000020000000300000002000000090000001e00000004000000a87a000005000000"
		+ "06000000930000001d0000000200000005030000200000000a000000000028410000a2410000a040"
		+ "000040410000000000004a420000a2410000c040000040410000803f200000000400000000000040"
		+ "0000f04100002042000010411e000000070000000300000040000000600000001400000002000000"
		+ "07000000080000001e00000009000000058000000c0000005901000001000000000a000000060000"
		+ "000300000005000003000000"
	),
	"snapshot_keen1_level":
	(
		"1c00000007000000020000000300000002000000090000001e00000004000000d204000004000000"
		+ "00000000000000001d0000000100000005000000200000000a000000000000430000684300000000"
		+ "0000804100000000000028430000684300000000000080410000000020000000040000000000803f"
		+ "00000043000068430000d8421e000000070000000200000030000000400000002000000002000000"
		+ "0700000007000000"
	),
	"snapshot_keen1_map":
	(
		"1c00000007000000020000000300000002000000090000001e000000040000000000000002000000"
		+ "00000000000000001d0000000000000020000000050000000000f041000020420000104200008041"
		+ "0000000020000000000000001e00000000000000"
	),
	"snapshot_nothing":
	(
		"1c00000007000000020000000300000002000000090000001e000000040000000000000002000000"
		+ "00000000000000001d0000000200000001020000200000000000000020000000000000001e000000"
		+ "00000000"
	),
	"scene_0":
	(
		"1c000000050000000200000000000000020000000900000002000000000000000200000004000000"
		+ "1e0000000600000003000000040000008f0000000a0000000200000000000000"
	),
	"scene_1":
	(
		"1c000000050000000200000000000000020000000900000002000000010000000200000004000000"
		+ "1e0000000600000003000000040000008f0000000a0000000200000000000000"
	),
	"scene_2":
	(
		"1c000000050000000200000000000000020000000900000002000000020000000200000004000000"
		+ "1e0000000600000003000000040000008f0000000a0000000200000000000000"
	),
	"scene_3":
	(
		"1c000000050000000200000000000000020000000900000002000000030000000200000004000000"
		+ "1e0000000600000003000000040000008f0000000a0000000200000000000000"
	),
	"scene_4":
	(
		"1c000000050000000200000000000000020000000900000002000000040000000200000004000000"
		+ "1e0000000600000003000000040000008f0000000a0000000200000000000000"
	),
	"scene_5":
	(
		"1c000000050000000200000000000000020000000900000002000000050000000200000004000000"
		+ "1e0000000600000003000000040000008f0000000a0000000200000000000000"
	),
	"tile":
	(
		"1c0000000500000002000000010000000200000009000000020000000c0000000200000005000000"
		+ "02000000c9000000"
	),
	"event_0": "1c000000040000000200000002000000020000000900000002000000000000000200000002000000",
	"event_1": "1c000000040000000200000002000000020000000900000002000000010000000200000002000000",
	"event_2": "1c000000040000000200000002000000020000000900000002000000020000000200000002000000",
	"event_3":
	(
		"1c000000040000000200000002000000020000000900000002000000030000000400000011000000"
		+ "4261747465727920696e20706c61636521000000"
	),
	"event_4": "1c000000040000000200000002000000020000000900000002000000040000000200000002000000",
	"event_5": "1c000000040000000200000002000000020000000900000002000000050000000200000002000000",
	"event_6": "1c000000040000000200000002000000020000000900000002000000060000000200000002000000",
	"event_7": "1c000000040000000200000002000000020000000900000002000000070000000200000002000000",
	"input": "1c000000020000000200000004000000020000000d000000",
	"view":
	(
		"1c00000005000000020000000500000003000000000080410300000000000042030000000000a043"
		+ "0300000000004843"
	),
	"challenge_commanderperfect":
	(
		"1c000000010000001d000000480000001c000000040000000400000010000000636f6d6d616e6465"
		+ "727065726665637402000000010000001d0000001000000007070707070707070707070707070707"
		+ "0100000001000000"
	),
	"proof_commanderperfect":
	(
		"1c000000010000001d000000200000006d077770bec5096b7108a595e2c48a1d1e6f3226b009996f"
		+ "c29b6346bae39c83"
	),
	"challenge_commanderperfect-keen2":
	(
		"1c000000010000001d000000500000001c000000040000000400000016000000636f6d6d616e6465"
		+ "72706572666563742d6b65656e32000002000000010000001d000000100000000707070707070707"
		+ "07070707070707070100000001000000"
	),
	"proof_commanderperfect-keen2":
	(
		"1c000000010000001d0000002000000077b93880a92d773f44fccef149bc0f29d19881b88ad170e2"
		+ "85d5333d4db4e347"
	),
	"challenge_commanderperfect-keen3":
	(
		"1c000000010000001d000000500000001c000000040000000400000016000000636f6d6d616e6465"
		+ "72706572666563742d6b65656e33000002000000010000001d000000100000000707070707070707"
		+ "07070707070707070100000001000000"
	),
	"proof_commanderperfect-keen3":
	(
		"1c000000010000001d000000200000007852b8fdfbce9e053954fff263f0192ea0816e9505b2d37c"
		+ "d27e5b8dc3621747"
	),
}


## Every message of Keen 1-3 by name, built from fixed numbers.
static func build() -> Dictionary[String, Array]:
	var messages: Dictionary[String, Array] = {}
	messages["snapshot_keen1_hand"] = _hand_snapshot(0, PackedInt32Array()).to_message()
	messages["snapshot_keen2_progress"] = _hand_snapshot(0b1011, PackedInt32Array()).to_message()
	var keen3 := Keen3OnlineState.new()
	keen3.done_levels = 0b1000000000000101
	keen3.ankh_ticks = PackedInt32Array([12, 345])
	keen3.sounds = PackedStringArray([Keen3Sounds.ANKH])
	keen3.view_center = Vector2(160, 96)
	keen3.messie_position = Vector2(48, 80)
	keen3.messie_sprite = 3
	messages["snapshot_keen3_extra"] = _hand_snapshot(0, keen3.to_numbers()).to_message()
	messages["snapshot_keen1_level"] = _level_snapshot()
	var map_keen := MapKeen.create(Fixtures.create_collision(FIELD), Vector2(30, 40))
	var inventory := Inventory.new()
	inventory.lives = 2
	messages["snapshot_keen1_map"] = (
		SnapshotMaker.new().of_map(map_keen, SCENE_ID, inventory, PackedByteArray()).to_message()
	)
	messages["snapshot_nothing"] = (
		SnapshotMaker.new().of_nothing(SCENE_ID, inventory, PackedByteArray([1, 2])).to_message()
	)
	var tiles := PackedInt32Array([3, 4, 143, 10, 2, 0])
	for kind: int in OnlineMessages.Scene.values():
		messages["scene_%d" % kind] = OnlineMessages.scene(SCENE_ID, kind, LEVEL_NUMBER, tiles)
	messages["tile"] = OnlineMessages.tile(SCENE_ID, Vector2i(12, 5), 201)
	for kind: int in OnlineMessages.Event.values():
		var value: Variant = "Battery in place!" if kind == OnlineMessages.Event.MESSAGE else 2
		messages["event_%d" % kind] = OnlineMessages.event(SCENE_ID, kind, value)
	messages["input"] = OnlineMessages.input(
		OnlineInput.to_bits(KeenInput.create(-1, true, false, true))
	)
	messages["view"] = OnlineMessages.view(Rect2(16, 32, 320, 200))
	var nonce := PackedByteArray()
	nonce.resize(JoinHandshake.NONCE_SIZE)
	nonce.fill(NONCE_BYTE)
	for game_id in [
		OnlineProtocol.GAME_ID, OnlineProtocol.GAME_ID_KEEN_2, OnlineProtocol.GAME_ID_KEEN_3
	]:
		messages["challenge_" + game_id] = [JoinHandshake.challenge(nonce, true, game_id)]
		messages["proof_" + game_id] = [JoinHandshake.proof(nonce, "secret", game_id)]
	return messages


## The hex of the bytes of every message of [method build].
static func hex_of_all() -> Dictionary[String, String]:
	var hex: Dictionary[String, String] = {}
	var messages := build()
	for name in messages:
		hex[name] = var_to_bytes(messages[name]).hex_encode()
	return hex


static func _hand_snapshot(progress: int, extra: PackedInt32Array) -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.scene = SCENE_ID
	snapshot.inventory.score = 31400
	snapshot.inventory.lives = 5
	snapshot.inventory.charges = 6
	snapshot.inventory.has_pogo = true
	snapshot.inventory.keycards[0] = true
	snapshot.inventory.keycards[3] = true
	snapshot.inventory.ship_parts[2] = true
	snapshot.progress_bits = progress
	snapshot.extra = extra
	snapshot.sounds = PackedByteArray([Sound.Id.KEEN_JUMP, 3])
	for index in 2:
		var keen := Snapshot.Figure.new()
		keen.position = Vector2(10.5 + index * 40, 20.25)
		keen.sprite = 5 + index
		keen.width = 12.0
		keen.dead = index == 1
		snapshot.keens.append(keen)
	var actor := Snapshot.Figure.new()
	actor.id = 2
	actor.position = Vector2(30, 40)
	actor.sprite = 9
	snapshot.actors.append(actor)
	var door := Snapshot.Figure.new()
	door.id = 3
	door.position = Vector2(64, 96)
	door.height = 20
	door.tiles = PackedInt32Array([7, 8])
	snapshot.doors.append(door)
	return snapshot


static func _level_snapshot() -> Array:
	var border := Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)
	var session := (
		LevelSession
		. create(
			Fixtures.create_level(FIELD),
			Fixtures.create_properties(),
			Inventory.new(),
			Vector2((START_CELL + border) * EgaGraphics.TILE_SIZE),
		)
	)
	for tick in SETTLE_TICKS:
		session.step(KeenInput.new())
	session.add_player(session.keen.position + Vector2(40, 0))
	session.inventory.score = 1234
	session.add_actor(RaygunShot.create(session.keen.position, 1))
	session.add_actor(OpeningDoor.create(Vector2i(3, 4), PackedInt32Array([7, 7])))
	var maker := SnapshotMaker.new()
	var sounds := PackedByteArray([Sound.Id.KEEN_JUMP])
	return maker.of_level(session, SCENE_ID, session.inventory, sounds).to_message()
