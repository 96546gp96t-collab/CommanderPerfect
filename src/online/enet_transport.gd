class_name EnetTransport
extends NetworkTransport
## ENet over UDP: hosting and joining by IP address, on the local network
## or over the internet with [constant OnlineProtocol.GAME_PORT] forwarded.

## ENet throws unreliable packets away by itself when a link looks slower
## than a moment ago (its packet throttle). The picture of every tick is
## unreliable; with no deceleration the throttle stays fully open and only
## the network itself loses anything (measured in Together Around).
const THROTTLE_INTERVAL_MS := 5000
const THROTTLE_ACCELERATION := 2
const THROTTLE_DECELERATION := 0
## Events and the picture of every tick each have a channel.
const CHANNELS := 2

var _peer: ENetMultiplayerPeer = null


func create_server(port: int) -> Error:
	var made := ENetMultiplayerPeer.new()
	var error := made.create_server(port, OnlineProtocol.MAX_CLIENTS, CHANNELS)
	if error != OK:
		return error
	_use(made)
	return OK


func create_client(address: String, port: int) -> Error:
	var made := ENetMultiplayerPeer.new()
	var error := made.create_client(address, port, CHANNELS)
	if error != OK:
		return error
	_use(made)
	return OK


func peer() -> MultiplayerPeer:
	return _peer


func identity_of(peer_id: int) -> String:
	if _peer == null:
		return ""
	var link := _peer.get_peer(peer_id)
	return link.get_remote_address() if link != null else ""


func close() -> void:
	if _peer == null:
		return
	_peer.close()
	_peer = null


func _use(made: ENetMultiplayerPeer) -> void:
	_peer = made
	_peer.peer_connected.connect(_keep_every_packet)


func _keep_every_packet(peer_id: int) -> void:
	if _peer == null:
		return
	var link := _peer.get_peer(peer_id)
	if link != null:
		link.throttle_configure(THROTTLE_INTERVAL_MS, THROTTLE_ACCELERATION, THROTTLE_DECELERATION)
