extends "res://tests/test_case.gd"
## Tests for getting into an online game: the handshake on its own (no
## network), and a real host and joiner over ENet on this machine, each with
## its own [OnlineSession] in one process.

## A port next to the game's, so that a running game does not get in the way.
const TEST_PORT := OnlineProtocol.GAME_PORT + 7
const FINGERPRINT := "0123456789abcdef"
## Polls to wait for something to happen over the local network.
const MAX_POLLS := 400
const POLL_MS := 5
const POLL_DELTA := 0.005


func test_handshake_admits_a_player_with_the_password() -> void:
	var gate := _gate("secret")
	var ticket := _ticket("secret", "Billy")
	var verdict := gate.judge(2, "a", ticket.answer(gate.begin(2)).reply)
	assert_true(verdict.admit, "the right password lets the player in")
	assert_equal(verdict.player_name, "Billy", "the name comes along")
	assert_equal(ticket.read_verdict(verdict.reply), "", "the joiner reads that he is in")
	assert_equal(ticket.host_name, "Host", "and learns the host's name")


func test_handshake_without_a_password() -> void:
	var gate := _gate("")
	var ticket := _ticket("", "Billy")
	assert_true(gate.judge(2, "a", ticket.answer(gate.begin(2)).reply).admit, "no password needed")


func test_handshake_refuses_a_wrong_password() -> void:
	var gate := _gate("secret")
	var verdict := gate.judge(2, "a", _ticket("guess", "B").answer(gate.begin(2)).reply)
	assert_true(not verdict.admit, "a wrong password is refused")
	assert_equal(verdict.reason, JoinHandshake.WRONG_PASSWORD, "and says so")


func test_joiner_without_password_is_told_one_is_needed() -> void:
	var step := _ticket("", "B").answer(_gate("secret").begin(2))
	assert_equal(step.problem, JoinHandshake.NEEDS_PASSWORD, "asks for the password")


func test_handshake_keeps_out_who_keeps_guessing() -> void:
	var gate := _gate("secret")
	for attempt in JoinGate.MAX_WRONG:
		gate.judge(2, "guesser", _ticket("wrong", "B").answer(gate.begin(2)).reply)
	var verdict := gate.judge(2, "guesser", _ticket("secret", "B").answer(gate.begin(2)).reply)
	assert_equal(verdict.reason, JoinHandshake.TOO_MANY_TRIES, "locked out, even when right")
	assert_true(
		gate.judge(3, "other", _ticket("secret", "C").answer(gate.begin(3)).reply).admit,
		"another player is not",
	)
	gate.advance(JoinGate.LOCKOUT_S + 1.0)
	verdict = gate.judge(2, "guesser", _ticket("secret", "B").answer(gate.begin(2)).reply)
	assert_true(verdict.admit, "after the lockout he may try again")


func test_handshake_refuses_other_levels_and_a_full_game() -> void:
	var gate := _gate("")
	var ticket := _ticket("", "B")
	ticket.fingerprint = "something else"
	var verdict := gate.judge(2, "a", ticket.answer(gate.begin(2)).reply)
	assert_equal(verdict.reason, JoinHandshake.OTHER_DATA, "other levels")
	gate.full = true
	verdict = gate.judge(3, "b", _ticket("", "C").answer(gate.begin(3)).reply)
	assert_equal(verdict.reason, JoinHandshake.FULL, "a full game")


func test_handshake_refuses_garbage() -> void:
	var gate := _gate("")
	gate.begin(2)
	assert_equal(
		gate.judge(2, "a", PackedByteArray([1, 2, 3])).reason, JoinHandshake.NOT_OURS, "junk"
	)
	assert_equal(
		gate.judge(4, "a", _ticket("", "B").answer(gate.begin(3)).reply).reason,
		JoinHandshake.NOT_OURS,
		"an answer to somebody else's challenge",
	)
	var other_version := var_to_bytes(["commanderperfect", OnlineProtocol.VERSION + 1, "", "B", []])
	gate.begin(5)
	assert_equal(gate.judge(5, "a", other_version).reason, JoinHandshake.OTHER_VERSION, "version")


func test_names_are_cleaned() -> void:
	assert_equal(PlayerName.clean("  Billy\néBlaze  "), "BillyBlaze", "odd characters go")
	assert_equal(PlayerName.clean("ABCDEFGHIJKLMNOPQ"), "ABCDEFGHIJKL", "cut to length")
	assert_equal(PlayerName.clean("\t"), PlayerName.FALLBACK, "nothing left")


func test_host_and_joiner_over_enet() -> void:
	var host := OnlineSession.new()
	var client := OnlineSession.new()
	var events: Array[String] = []
	host.partner_joined.connect(func(who: String) -> void: events.append("joined " + who))
	host.partner_left.connect(func(who: String) -> void: events.append("left " + who))
	client.joined.connect(func(who: String) -> void: events.append("in at " + who))
	var host_got: Array[Array] = []
	var client_got: Array[Array] = []
	host.received.connect(func(message: Array) -> void: host_got.append(message))
	client.received.connect(func(message: Array) -> void: client_got.append(message))
	assert_equal(
		host.host(EnetTransport.new(), "Hosty", "pw", FINGERPRINT, TEST_PORT), OK, "hosting starts"
	)
	assert_equal(
		client.join(EnetTransport.new(), "127.0.0.1", "Joiny", "pw", FINGERPRINT, TEST_PORT),
		OK,
		"joining starts",
	)
	_poll_until([host, client], func() -> bool: return events.size() >= 2)
	assert_true(events.has("joined Joiny"), "the host hears who joined")
	assert_true(events.has("in at Hosty"), "the joiner learns the host's name")
	assert_true(host.has_partner() and client.has_partner(), "both are connected")

	client.send([OnlineProtocol.Message.INPUT, 5])
	host.send([OnlineProtocol.Message.SNAPSHOT, "state"], false)
	_poll_until([host, client], func() -> bool: return host_got.size() + client_got.size() >= 2)
	assert_equal(host_got, [[OnlineProtocol.Message.INPUT, 5]], "the host receives")
	assert_equal(client_got, [[OnlineProtocol.Message.SNAPSHOT, "state"]], "the joiner receives")

	client.leave()
	_poll_until([host], func() -> bool: return events.has("left Joiny"))
	assert_true(events.has("left Joiny"), "the host hears that he left")
	host.leave()
	host.free()
	client.free()


func test_wrong_password_over_enet() -> void:
	var host := OnlineSession.new()
	var client := OnlineSession.new()
	var reasons: Array[String] = []
	client.join_failed.connect(func(reason: String) -> void: reasons.append(reason))
	host.host(EnetTransport.new(), "Hosty", "pw", FINGERPRINT, TEST_PORT)
	client.join(EnetTransport.new(), "127.0.0.1", "J", "nope", FINGERPRINT, TEST_PORT)
	_poll_until([host, client], func() -> bool: return not reasons.is_empty())
	assert_equal(reasons, [JoinHandshake.WRONG_PASSWORD], "the joiner hears why")
	assert_true(not host.has_partner(), "nobody joined")
	_poll_until([host, client], func() -> bool: return not client.is_active())
	assert_true(not client.is_active(), "the joiner's session is over")
	host.leave()
	host.free()
	client.free()


func test_nobody_answers() -> void:
	var client := OnlineSession.new()
	var reasons: Array[String] = []
	client.join_failed.connect(func(reason: String) -> void: reasons.append(reason))
	client.join(EnetTransport.new(), "127.0.0.1", "J", "", FINGERPRINT, TEST_PORT + 1)
	client.poll(OnlineProtocol.JOIN_TIMEOUT_S + 1.0)
	assert_equal(reasons, [OnlineSession.NO_ANSWER], "gives up")
	client.poll(0.0)
	assert_true(not client.is_active(), "and ends the session")
	client.free()


func _gate(password: String) -> JoinGate:
	var gate := JoinGate.new()
	gate.host_name = "Host"
	gate.password = password
	gate.fingerprint = FINGERPRINT
	return gate


func _ticket(password: String, player_name: String) -> JoinTicket:
	var ticket := JoinTicket.new()
	ticket.password = password
	ticket.player_name = player_name
	ticket.fingerprint = FINGERPRINT
	return ticket


func _poll_until(sessions: Array, done: Callable) -> void:
	for attempt in MAX_POLLS:
		for session: OnlineSession in sessions:
			session.poll(POLL_DELTA)
		if done.call():
			return
		OS.delay_msec(POLL_MS)
