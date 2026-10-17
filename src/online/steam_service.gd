class_name SteamService
extends Node
## The one place in the game that calls Steam: starting it, opening a lobby
## that only this player's Steam friends can see, finding the lobbies his
## friends host, and entering one.
##
## Steam comes from the GodotSteam plug-in (addons/godotsteam, macOS and
## Windows only). Nothing else names a Steam class, and this script only
## talks to the "Steam" singleton through Engine: without the plug-in (on
## Linux, in the tests) every file still loads, and Steam is simply not
## available. App ID 480 is Spacewar, Valve's open test game, until the
## game has an App ID of its own.

## Our lobby exists; the game can be hosted in it.
signal lobby_opened(lobby_id: int)
## Steam let us into a friend's lobby.
signal lobby_entered(lobby_id: int)
## The friends' games found so far: each [lobby_id, data, members].
signal games_listed(games: Array)
## Something did not work; [param reason] is shown to the player.
signal failed(reason: String)

const SINGLETON := "Steam"
const APP_ID := 480
## k_EFriendFlagImmediate: the people on the player's friends list.
const FRIENDS := 4
## k_ELobbyTypeFriendsOnly.
const FRIENDS_ONLY_LOBBY := 1
## k_EResultOK and k_EChatRoomEnterResponseSuccess.
const RESULT_OK := 1
const NO_PLUGIN := "The Steam plug-in is not in this build."
const NOT_RUNNING := "Steam is not running, or you are not logged in."

static var _started := false
static var _tried := false
static var _why := NO_PLUGIN

## The game whose lobbies are opened and listed (Keen 1's by default).
var game_id := OnlineProtocol.GAME_ID
var _lobby := 0
var _pending_lock := false
var _asked: Dictionary[int, bool] = {}
var _found: Array = []


## Starts Steam, once per run. True when it is running and logged in;
## otherwise [method reason] says why not.
static func start() -> bool:
	if _tried:
		return _started
	_tried = true
	if not Engine.has_singleton(SINGLETON):
		_why = NO_PLUGIN
		return false
	var answer: Dictionary = Engine.get_singleton(SINGLETON).steamInitEx(APP_ID, true)
	_started = int(answer.get("status", 1)) == 0
	_why = "" if _started else NOT_RUNNING
	return _started


static func is_ready() -> bool:
	return _started


static func reason() -> String:
	return _why


## The name this player has on Steam.
static func player_name() -> String:
	if not _started:
		return ""
	return str(Engine.get_singleton(SINGLETON).getPersonaName())


func _ready() -> void:
	if not Engine.has_singleton(SINGLETON):
		return
	var steam := Engine.get_singleton(SINGLETON)
	steam.lobby_created.connect(_on_lobby_created)
	steam.lobby_data_update.connect(_on_lobby_data)
	steam.lobby_joined.connect(_on_lobby_joined)


## Opens a lobby that only this player's Steam friends can see.
func open_lobby(locked: bool) -> void:
	if not _usable():
		return
	_pending_lock = locked
	Engine.get_singleton(SINGLETON).createLobby(FRIENDS_ONLY_LOBBY, SteamLobby.SEATS)


## Asks which friends are in a lobby of this game. A friends-only lobby is
## not in Steam's public lobby list, so it is found through the friend:
## what is he playing, and what does that lobby say about itself. The
## answers arrive one by one in [signal games_listed].
func ask_for_games() -> void:
	if not _usable():
		return
	var steam := Engine.get_singleton(SINGLETON)
	_asked.clear()
	_found.clear()
	games_listed.emit(_found)
	for index in int(steam.getFriendCount(FRIENDS)):
		var friend := int(steam.getFriendByIndex(index, FRIENDS))
		var playing: Dictionary = steam.getFriendGamePlayed(friend)
		var lobby_id := SteamLobby.lobby_of_friend(playing, APP_ID)
		if lobby_id == 0 or _asked.has(lobby_id):
			continue
		_asked[lobby_id] = true
		steam.requestLobbyData(lobby_id)


func enter_lobby(lobby_id: int) -> void:
	if _usable():
		Engine.get_singleton(SINGLETON).joinLobby(lobby_id)


func leave() -> void:
	if _lobby != 0 and is_ready():
		Engine.get_singleton(SINGLETON).leaveLobby(_lobby)
	_lobby = 0


func _usable() -> bool:
	if start():
		return true
	failed.emit(reason())
	return false


func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != RESULT_OK:
		failed.emit("Steam could not open a lobby.")
		return
	_lobby = lobby_id
	var steam := Engine.get_singleton(SINGLETON)
	var data := SteamLobby.data_for(player_name(), _pending_lock, game_id)
	for key: String in data:
		steam.setLobbyData(lobby_id, key, str(data[key]))
	lobby_opened.emit(lobby_id)


func _on_lobby_data(success: int, lobby_id: int, _member_id: int) -> void:
	if success == 0 or not _asked.has(lobby_id):
		return
	_asked.erase(lobby_id)
	var steam := Engine.get_singleton(SINGLETON)
	var data := {}
	for key in [
		SteamLobby.GAME_KEY, SteamLobby.VERSION_KEY, SteamLobby.HOST_KEY, SteamLobby.PASSWORD_KEY
	]:
		data[key] = str(steam.getLobbyData(lobby_id, key))
	if not SteamLobby.is_ours(data, game_id):
		return
	_found.append([lobby_id, data, int(steam.getNumLobbyMembers(lobby_id))])
	games_listed.emit(_found)


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != RESULT_OK:
		failed.emit("Steam could not let you into that game.")
		return
	_lobby = lobby_id
	lobby_entered.emit(lobby_id)
