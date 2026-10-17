class_name JoinGate
extends RefCounted
## The host's side of [JoinHandshake]: decides whether a player may join.
##
## Pure logic without the network, so that the tests can knock on it. A
## player who keeps guessing the password is kept out for a while, keyed
## by what the transport knows him by (his IP address or SteamID).

## Wrong passwords allowed before a player is kept out.
const MAX_WRONG := 5
## Seconds a player is kept out after that.
const LOCKOUT_S := 60.0


## What to do with a player, after his answer.
class Verdict:
	extends RefCounted
	var admit := false
	## Why not, one of the reasons in [JoinHandshake].
	var reason := ""
	var player_name := ""
	## The message to send back.
	var reply := PackedByteArray()


var host_name := "Keen"
## The game hosted ([constant OnlineProtocol.GAME_ID] for Keen 1).
var game_id := OnlineProtocol.GAME_ID
var password := ""
## Fingerprint of the host's levels; a player with other levels cannot join.
var fingerprint := ""
## Whether a player has already joined: then the game is full.
var full := false
var _nonces: Dictionary[int, PackedByteArray] = {}
var _wrong: Dictionary[String, int] = {}
var _locked_until: Dictionary[String, float] = {}
var _clock := 0.0


## Lets [param seconds] pass, for the lockouts.
func advance(seconds: float) -> void:
	_clock += seconds


## A player knocks: the challenge to send him.
func begin(peer_id: int) -> PackedByteArray:
	var nonce := JoinHandshake.make_nonce()
	_nonces[peer_id] = nonce
	return JoinHandshake.challenge(nonce, not password.is_empty(), game_id)


## Judges the answer [param data] of [param peer_id], known to the transport
## as [param identity].
func judge(peer_id: int, identity: String, data: PackedByteArray) -> Verdict:
	var nonce: PackedByteArray = _nonces.get(peer_id, PackedByteArray())
	_nonces.erase(peer_id)
	var answer := JoinHandshake.unpack(data, 5)
	var problem := _problem(answer, nonce, identity)
	var verdict := Verdict.new()
	if not problem.is_empty():
		verdict.reason = problem
		verdict.reply = var_to_bytes([false, problem])
		return verdict
	_wrong.erase(identity)
	verdict.admit = true
	verdict.player_name = PlayerName.clean(str(answer[3]))
	verdict.reply = var_to_bytes([true, host_name])
	return verdict


## The player went before he was let in.
func forget(peer_id: int) -> void:
	_nonces.erase(peer_id)


## Why [param answer] (to the challenge with [param nonce]) cannot join,
## or empty when it can.
func _problem(answer: Array, nonce: PackedByteArray, identity: String) -> String:
	var problem := ""
	if nonce.is_empty() or answer.is_empty():
		problem = JoinHandshake.NOT_OURS
	elif str(answer[0]) != game_id:
		problem = JoinHandshake.game_problem(str(answer[0]))
	elif not answer[1] is int or answer[1] != OnlineProtocol.VERSION:
		problem = JoinHandshake.OTHER_VERSION
	elif _locked_until.get(identity, -1.0) > _clock:
		problem = JoinHandshake.TOO_MANY_TRIES
	elif not password.is_empty() and not _knows_password(answer[4], nonce):
		_count_wrong(identity)
		problem = JoinHandshake.WRONG_PASSWORD
	elif str(answer[2]) != fingerprint:
		problem = JoinHandshake.OTHER_DATA
	elif full:
		problem = JoinHandshake.FULL
	return problem


func _knows_password(given: Variant, nonce: PackedByteArray) -> bool:
	if not given is PackedByteArray:
		return false
	return JoinHandshake.same_proof(given, JoinHandshake.proof(nonce, password, game_id))


func _count_wrong(identity: String) -> void:
	var count: int = _wrong.get(identity, 0) + 1
	_wrong[identity] = count
	if count >= MAX_WRONG:
		_wrong.erase(identity)
		_locked_until[identity] = _clock + LOCKOUT_S
