class_name OnlineSession
extends Node
## One online game, as host or as the player who joins: getting in through
## [JoinHandshake], and carrying messages both ways once in.
##
## It owns its own [SceneMultiplayer] and polls it itself ([method poll]),
## so that it needs nothing from the scene tree: the tests run a host and a
## joiner side by side in one process. Messages are arrays (see
## [enum OnlineProtocol.Message]) sent as bytes; objects are never decoded.
## Everything that arrives is a stranger's data: too large, malformed or
## from the wrong peer, it is dropped unread.

## Hosting has begun; others can join from now on.
signal hosting_started
## (Joiner) the host let us in.
signal joined(host_name: String)
## (Joiner) we could not get in; [param reason] is one of [JoinHandshake]'s
## reasons or [constant NO_ANSWER].
signal join_failed(reason: String)
## (Host) a player joined, or left again.
signal partner_joined(player_name: String)
signal partner_left(player_name: String)
## (Joiner) the host has gone; the session is over.
signal host_left
## A message from the other side: an array whose first element is one of
## [enum OnlineProtocol.Message].
signal received(message: Array)

enum Role { OFFLINE, HOST, CLIENT }

## The host does not answer at all: a wrong address, a closed port, or a
## game that is full.
const NO_ANSWER := "no_answer"
## A joiner who sends more messages than this in one second is cut off.
const MAX_MESSAGES_PER_SECOND := 400

var api := SceneMultiplayer.new()
var role := Role.OFFLINE
## The game played ([constant OnlineProtocol.GAME_ID] for Keen 1): only a
## player of the same game can join.
var game_id := OnlineProtocol.GAME_ID
## The other player's name: the joiner's for the host, the host's for the
## joiner.
var partner_name := ""
var _transport: NetworkTransport
var _gate := JoinGate.new()
var _ticket: JoinTicket
## (Host) the peer id of the player who joined, or 0.
var _partner := 0
var _admitted: Dictionary[int, String] = {}
## (Joiner) seconds left for the host to answer, while still knocking.
var _waiting := 0.0
var _answered := false
var _failed := false
var _connected := false
var _leave_requested := false
## Peers to cut off when their seconds run out (after a refusal).
var _to_cut: Dictionary[int, float] = {}
## (Host) peers that knocked and are not in or gone yet.
var _knocking: Dictionary[int, bool] = {}
var _message_count := 0
var _count_time := 0.0


func _init() -> void:
	api.allow_object_decoding = false
	# Raw bytes need no node to call, but SceneMultiplayer refuses to work
	# without a root path; nothing is ever looked up under it.
	api.root_path = ^"/root"
	api.server_relay = false
	api.auth_timeout = OnlineProtocol.AUTH_TIMEOUT_S
	api.peer_authenticating.connect(_on_peer_authenticating)
	api.peer_authentication_failed.connect(_on_authentication_failed)
	api.peer_connected.connect(_on_peer_connected)
	api.peer_disconnected.connect(_on_peer_disconnected)
	api.connected_to_server.connect(_on_connected_to_server)
	api.connection_failed.connect(_on_connection_failed)
	api.server_disconnected.connect(_on_server_disconnected)
	api.peer_packet.connect(_on_packet)


func _process(delta: float) -> void:
	poll(delta)


func is_active() -> bool:
	return role != Role.OFFLINE


func is_host() -> bool:
	return role == Role.HOST


func is_client() -> bool:
	return role == Role.CLIENT


## (Host) whether a player has joined; (joiner) whether we are in.
func has_partner() -> bool:
	return _partner != 0 if is_host() else _connected


## Starts hosting over [param transport] on [param port] as
## [param host_name]. With a [param password] only players who know it can
## join. [param fingerprint] is that of our levels ([LevelFingerprint]).
func host(
	transport: NetworkTransport,
	host_name: String,
	password: String,
	fingerprint: String,
	port := OnlineProtocol.GAME_PORT
) -> Error:
	leave()
	var error := transport.create_server(port)
	if error != OK:
		return error
	_transport = transport
	_gate = JoinGate.new()
	_gate.game_id = game_id
	_gate.host_name = PlayerName.clean(host_name)
	_gate.password = password
	_gate.fingerprint = fingerprint
	api.auth_callback = _on_host_auth
	api.multiplayer_peer = transport.peer()
	role = Role.HOST
	hosting_started.emit()
	return OK


## Joins the host at [param address] over [param transport].
func join(
	transport: NetworkTransport,
	address: String,
	player_name: String,
	password: String,
	fingerprint: String,
	port := OnlineProtocol.GAME_PORT
) -> Error:
	leave()
	var error := transport.create_client(address, port)
	if error != OK:
		return error
	_transport = transport
	_ticket = JoinTicket.new()
	_ticket.game_id = game_id
	_ticket.player_name = PlayerName.clean(player_name)
	_ticket.password = password
	_ticket.fingerprint = fingerprint
	_answered = false
	_failed = false
	_connected = false
	_waiting = OnlineProtocol.JOIN_TIMEOUT_S
	api.auth_callback = _on_client_auth
	api.multiplayer_peer = transport.peer()
	role = Role.CLIENT
	return OK


## Ends the session, as host or as joiner. Never call this from inside one
## of the multiplayer signals: tearing the peer down there crashes the
## engine; use [method leave_soon].
func leave() -> void:
	_leave_requested = false
	if role == Role.OFFLINE:
		return
	# Close before detaching: otherwise the goodbye never leaves the machine.
	if _transport != null:
		_transport.close()
	api.multiplayer_peer = null
	_transport = null
	_ticket = null
	_gate = JoinGate.new()
	_partner = 0
	_admitted.clear()
	_to_cut.clear()
	_knocking.clear()
	partner_name = ""
	_connected = false
	_waiting = 0.0
	role = Role.OFFLINE


## Ends the session at the next poll.
func leave_soon() -> void:
	_leave_requested = true


## Handles the network for [param delta] seconds.
func poll(delta: float) -> void:
	if _leave_requested:
		leave()
	if role == Role.OFFLINE:
		return
	_gate.advance(delta)
	_count_messages(delta)
	_cut_refused(delta)
	api.poll()
	if is_client() and not _connected and not _failed:
		_waiting -= delta
		if _waiting <= 0.0:
			_fail(NO_ANSWER)


## Sends [param message] to the other player; [param reliable] ones always
## arrive, in order; the others may get lost.
func send(message: Array, reliable := true) -> void:
	var target := _partner if is_host() else OnlineProtocol.HOST_PEER_ID
	if not has_partner() or target == 0:
		return
	var mode := (
		MultiplayerPeer.TRANSFER_MODE_RELIABLE
		if reliable
		else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	)
	var channel := OnlineProtocol.CHANNEL_EVENTS if reliable else OnlineProtocol.CHANNEL_STATE
	api.send_bytes(var_to_bytes(message), target, mode, channel)


func _on_peer_authenticating(peer_id: int) -> void:
	if not is_host():
		return
	_knocking[peer_id] = true
	_gate.full = _partner != 0
	api.send_auth(peer_id, _gate.begin(peer_id))


func _on_host_auth(peer_id: int, data: PackedByteArray) -> void:
	var identity := _transport.identity_of(peer_id) if _transport != null else ""
	var verdict := _gate.judge(peer_id, identity, data)
	api.send_auth(peer_id, verdict.reply)
	if not verdict.admit:
		_to_cut[peer_id] = OnlineProtocol.REJECT_FLUSH_S
		return
	_admitted[peer_id] = verdict.player_name
	api.complete_auth(peer_id)


func _on_client_auth(peer_id: int, data: PackedByteArray) -> void:
	if peer_id != OnlineProtocol.HOST_PEER_ID or _ticket == null or _failed:
		return
	if not _answered:
		var step := _ticket.answer(data)
		if not step.problem.is_empty():
			_fail(step.problem)
			return
		_answered = true
		api.send_auth(peer_id, step.reply)
		return
	var refusal := _ticket.read_verdict(data)
	if not refusal.is_empty():
		_fail(refusal)
		return
	partner_name = _ticket.host_name
	api.complete_auth(peer_id)


func _on_authentication_failed(peer_id: int) -> void:
	if is_host():
		_gate.forget(peer_id)
		_admitted.erase(peer_id)
		_knocking.erase(peer_id)
	elif is_client():
		_fail(JoinHandshake.REFUSED)


func _on_peer_connected(peer_id: int) -> void:
	_knocking.erase(peer_id)
	if not is_host() or not _admitted.has(peer_id):
		return
	if _partner != 0:
		api.disconnect_peer(peer_id)
		return
	_partner = peer_id
	partner_name = _admitted[peer_id]
	_admitted.erase(peer_id)
	partner_joined.emit(partner_name)


func _on_peer_disconnected(peer_id: int) -> void:
	_to_cut.erase(peer_id)
	_admitted.erase(peer_id)
	_knocking.erase(peer_id)
	if not is_host() or peer_id != _partner:
		return
	var player_name := partner_name
	_partner = 0
	partner_name = ""
	partner_left.emit(player_name)


func _on_connected_to_server() -> void:
	if not is_client() or _failed:
		return
	_connected = true
	joined.emit(partner_name)


func _on_connection_failed() -> void:
	_fail(NO_ANSWER)


func _on_server_disconnected() -> void:
	if not is_client():
		return
	if _connected:
		_connected = false
		leave_soon()
		host_left.emit()
	else:
		_fail(JoinHandshake.REFUSED)


func _on_packet(peer_id: int, packet: PackedByteArray) -> void:
	var expected := _partner if is_host() else OnlineProtocol.HOST_PEER_ID
	if peer_id != expected or not has_partner():
		return
	_message_count += 1
	if is_host() and _message_count > MAX_MESSAGES_PER_SECOND:
		api.disconnect_peer(peer_id)
		return
	if packet.size() > OnlineProtocol.MAX_MESSAGE_SIZE:
		return
	var message: Variant = bytes_to_var(packet)
	if message is Array and not message.is_empty() and message[0] is int:
		received.emit(message)


## Joining did not work: say why once, and end the session.
func _fail(reason: String) -> void:
	if not is_client() or _failed:
		return
	_failed = true
	leave_soon()
	join_failed.emit(reason)


func _count_messages(delta: float) -> void:
	_count_time += delta
	if _count_time >= 1.0:
		_count_time = 0.0
		_message_count = 0


func _cut_refused(delta: float) -> void:
	for peer_id in _to_cut.keys():
		_to_cut[peer_id] -= delta
		if _to_cut[peer_id] <= 0.0:
			_to_cut.erase(peer_id)
			if api.multiplayer_peer != null and _knocking.has(peer_id):
				_knocking.erase(peer_id)
				api.disconnect_peer(peer_id)
