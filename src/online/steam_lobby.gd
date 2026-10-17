class_name SteamLobby
extends RefCounted
## What a Steam lobby says about the game in it, and what to believe of it.
##
## Lobby data is public: anybody on Steam can read it, and anybody can write
## it into a lobby of his own. So it never carries the password, only
## whether there is one, and everything read back is treated as a
## stranger's string. No Steam calls here, so the rules can be tested
## without the plug-in.

const GAME_KEY := "game"
const VERSION_KEY := "version"
const HOST_KEY := "host"
const PASSWORD_KEY := "password"
## A lobby holds the host and the one player who can join.
const SEATS := OnlineProtocol.MAX_CLIENTS + 1
## Longer values are somebody playing games with the list.
const MOST_TEXT := 64


## What a host writes into his lobby. Never the password, only whether
## there is one.
static func data_for(
	host_name: String, locked: bool, game_id := OnlineProtocol.GAME_ID
) -> Dictionary:
	return {
		GAME_KEY: game_id,
		VERSION_KEY: str(OnlineProtocol.VERSION),
		HOST_KEY: host_name.left(MOST_TEXT),
		PASSWORD_KEY: "yes" if locked else "no",
	}


## True for a lobby of this game ([param game_id]) and this version. App ID
## 480 (Spacewar) is shared by every developer without an App ID of his own,
## so a friend may well be in somebody else's game.
static func is_ours(data: Dictionary, game_id := OnlineProtocol.GAME_ID) -> bool:
	return (
		str(data.get(GAME_KEY, "")) == game_id
		and str(data.get(VERSION_KEY, "")) == str(OnlineProtocol.VERSION)
	)


## True for a lobby of any of our games, of this version: a friend who
## hosts another Keen is listed too (joining him switches games).
static func is_any_ours(data: Dictionary) -> bool:
	return is_ours(data, game_of(data))


## The game a lobby is of, as it says.
static func game_of(data: Dictionary) -> String:
	var game := str(data.get(GAME_KEY, ""))
	return game if game in OnlineProtocol.GAME_IDS else ""


static func is_locked(data: Dictionary) -> bool:
	return str(data.get(PASSWORD_KEY, "")) == "yes"


## The host's name as it may be shown.
static func host_name(data: Dictionary) -> String:
	return PlayerName.clean(str(data.get(HOST_KEY, "")).left(MOST_TEXT))


## The lobby a friend is in, if he plays a game of App ID [param app_id],
## or 0. [param playing] is what Steam says he is playing.
static func lobby_of_friend(playing: Dictionary, app_id: int) -> int:
	if int(playing.get("id", 0)) != app_id:
		return 0
	return int(playing.get("lobby", 0))


## One line of the list of games: who hosts, how full it is, and a "*"
## when it wants a password.
static func described(data: Dictionary, members: int) -> String:
	var lock := " *" if is_locked(data) else ""
	return "%s (%d/%d)%s" % [host_name(data), clampi(members, 0, SEATS), SEATS, lock]
