class_name NetworkTransport
extends RefCounted
## What [OnlineSession] needs from a connection, and nothing more: ENet for
## an IP address ([EnetTransport]) or Steam ([SteamTransport]). Everything
## above it talks to Godot's high-level multiplayer only.
##
## Subclasses override every method; this base only documents the contract.


func create_server(_port: int) -> Error:
	return ERR_UNCONFIGURED


func create_client(_address: String, _port: int) -> Error:
	return ERR_UNCONFIGURED


func peer() -> MultiplayerPeer:
	return null


## How this transport tells players apart, for limiting password attempts:
## an IP address for ENet, a SteamID for Steam. Only ever compared.
func identity_of(_peer_id: int) -> String:
	return ""


func close() -> void:
	pass
