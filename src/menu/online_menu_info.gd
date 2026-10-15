class_name OnlineMenuInfo
extends RefCounted
## What the menus need to know about playing online: whether this player
## hosts or joined, who the other player is, what a friend needs to join,
## and the friends' games found on Steam. The game screen fills it in; the
## [MenuController] only shows it.

enum Role { OFFLINE, HOST, CLIENT }

## Characters allowed in a password a host makes up: none that look alike.
const PASSWORD_CHARACTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const PASSWORD_LENGTH := 6

var role := Role.OFFLINE
## The other player's name, once someone joined.
var partner_name := ""
## Lines that tell how to join this host (addresses, port, password).
var host_lines := PackedStringArray()
## The friends' games on Steam, one line each, and whether each wants a
## password.
var steam_games := PackedStringArray()
var steam_locked: Array[bool] = []


## A new password for a host.
static func make_password() -> String:
	var password := ""
	var bytes := Crypto.new().generate_random_bytes(PASSWORD_LENGTH)
	for byte in bytes:
		password += PASSWORD_CHARACTERS[byte % PASSWORD_CHARACTERS.length()]
	return password
