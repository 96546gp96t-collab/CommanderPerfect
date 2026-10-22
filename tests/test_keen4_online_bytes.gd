extends "res://tests/test_case.gd"
## Milestone D12 adds Keen 4 to playing online; Keen 1, 2 and 3's messages
## must stay byte for byte as they were. Every one of their messages
## (snapshots by hand and by [SnapshotMaker], every scene and event kind
## they had, a tile, the buttons, the view, the handshake's challenge and
## proof) is built from fixed numbers and compared with its bytes from the
## start of D12 (tests/keen4_online_golden.gd). The old enum values keep
## their numbers, and what Keen 4 adds comes after them.

const Golden := preload("res://tests/keen4_online_golden.gd")
## The kinds Keen 1-3 had at the start of D12.
const OLD_SCENES := 6
const OLD_EVENTS := 8
const OLD_MESSAGES := 6
const OLD_GAMES := 3


func test_keen_1_to_3_messages_are_byte_for_byte_the_same() -> void:
	var now := Golden.hex_of_all()
	assert_equal(Golden.GOLDEN.size(), 29, "every golden message is there")
	for name in Golden.GOLDEN:
		assert_true(now.has(name), "%s is still made" % name)
		if now.has(name):
			assert_equal(now[name], Golden.GOLDEN[name], "the bytes of %s" % name)


func test_the_old_messages_are_read_back() -> void:
	var messages := Golden.build()
	for name in messages:
		var message: Array = messages[name]
		if name.begins_with("snapshot"):
			assert_true(Snapshot.from_message(message) != null, "%s is read" % name)
		elif name.begins_with("scene"):
			assert_equal(OnlineMessages.read_scene(message).size(), 4, "%s is read" % name)
		elif name.begins_with("event"):
			assert_equal(OnlineMessages.read_event(message).size(), 3, "%s is read" % name)


func test_old_enum_values_keep_their_numbers() -> void:
	var scenes := OnlineMessages.Scene
	assert_true(scenes.size() >= OLD_SCENES, "no scene taken away")
	assert_equal(
		[scenes.WAITING, scenes.MAP, scenes.LEVEL, scenes.GAME_OVER, scenes.ENDING],
		[0, 1, 2, 3, 4],
		"the scenes"
	)
	assert_equal(scenes.EARTH_EXPLODES, 5, "Keen 2's")
	var events := OnlineMessages.Event
	assert_true(events.size() >= OLD_EVENTS, "no event taken away")
	var old := [
		events.HINT,
		events.KEENS_LEFT,
		events.SHIP_MISSING,
		events.MESSAGE,
		events.LIGHTS,
		events.SHIP_MESSAGE,
		events.MORTIMER,
		events.BORDER_FLASH,
	]
	assert_equal(old, [0, 1, 2, 3, 4, 5, 6, 7], "the events")
	var kinds := OnlineProtocol.Message
	assert_true(kinds.size() >= OLD_MESSAGES, "no message kind taken away")
	assert_equal(
		[kinds.SCENE, kinds.TILE, kinds.EVENT, kinds.SNAPSHOT, kinds.INPUT, kinds.VIEW],
		[0, 1, 2, 3, 4, 5],
		"the message kinds"
	)
	assert_equal(OnlineProtocol.VERSION, 1, "the same version: old hosts still meet")


func test_the_old_games_keep_their_places() -> void:
	var ids := OnlineProtocol.GAME_IDS
	assert_true(ids.size() >= OLD_GAMES, "three or more")
	assert_equal(
		ids.slice(0, OLD_GAMES),
		[OnlineProtocol.GAME_ID, OnlineProtocol.GAME_ID_KEEN_2, OnlineProtocol.GAME_ID_KEEN_3],
		"Keen 1-3 first, in their order"
	)
	assert_equal(OnlineProtocol.GAME_PORT, 24800, "the same port")
	assert_equal(Snapshot.PARTS, 7, "the snapshot's parts")
	assert_equal(Snapshot.MAX_EXTRA, 32, "the room for a game's own numbers")
