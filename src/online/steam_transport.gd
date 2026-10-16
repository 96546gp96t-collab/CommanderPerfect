class_name SteamTransport
extends NetworkTransport
## The session over Steam instead of ENet: Steam's relay finds the way, so
## no IP address is shown and no port has to be opened on a router.
##
## Where ENet has an address and a port, Steam has a lobby. The peer is made
## through ClassDB rather than by name, so that this file also loads without
## the Steam plug-in (on Linux, in the tests); see [SteamService].

const PEER_CLASS := "SteamMultiplayerPeer"

## The lobby this session runs in: ours when hosting, the friend's when
## joining.
var lobby := 0

var _peer: MultiplayerPeer = null


static func on(lobby_id: int) -> SteamTransport:
	var transport := SteamTransport.new()
	transport.lobby = lobby_id
	return transport


## Opens the game in the lobby this machine owns; the port means nothing to
## Steam.
func create_server(_port: int) -> Error:
	return _open("host_with_lobby", lobby)


## Joins the lobby: Steam has already let us in ([method SteamService.enter_lobby]).
func create_client(_address: String, _port: int) -> Error:
	return _open("connect_to_lobby", lobby)


func peer() -> MultiplayerPeer:
	return _peer


func identity_of(peer_id: int) -> String:
	if _peer == null:
		return ""
	return "steam:%d" % int(_peer.call("get_steam_id_for_peer_id", peer_id))


func close() -> void:
	if _peer == null:
		return
	_peer.close()
	_peer = null


func _open(how: String, lobby_id: int) -> Error:
	if lobby_id == 0:
		return ERR_INVALID_PARAMETER
	if not ClassDB.class_exists(PEER_CLASS):
		return ERR_UNAVAILABLE
	var made: MultiplayerPeer = ClassDB.instantiate(PEER_CLASS)
	if made == null:
		return ERR_CANT_CREATE
	var error: Error = made.call(how, lobby_id)
	if error != OK:
		return error
	_peer = made
	return OK
