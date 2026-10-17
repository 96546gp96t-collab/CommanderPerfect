class_name JoinTicket
extends RefCounted
## The joining player's side of [JoinHandshake]: answers the host's
## challenge, and reads the verdict.


## The answer to send, or empty when the challenge is not one we can answer
## ([member problem] says why).
class Step:
	extends RefCounted
	var reply := PackedByteArray()
	var problem := ""


## The reasons a host may give; anything else reads as a plain refusal.
const KNOWN_REASONS: Array[String] = [
	JoinHandshake.NOT_OURS,
	JoinHandshake.OTHER_GAME,
	JoinHandshake.OTHER_VERSION,
	JoinHandshake.OTHER_DATA,
	JoinHandshake.WRONG_PASSWORD,
	JoinHandshake.FULL,
	JoinHandshake.TOO_MANY_TRIES,
]

var player_name := "Keen"
## The game played ([constant OnlineProtocol.GAME_ID] for Keen 1).
var game_id := OnlineProtocol.GAME_ID
var password := ""
var fingerprint := ""
## The host's name, once he let us in.
var host_name := ""
## The game the host plays, when it is another game of ours.
var host_game_id := ""


## The answer to [param data], the host's challenge.
func answer(data: PackedByteArray) -> Step:
	var step := Step.new()
	var challenge := JoinHandshake.unpack(data, 4)
	if challenge.is_empty():
		step.problem = JoinHandshake.NOT_OURS
		return step
	if str(challenge[0]) != game_id:
		step.problem = JoinHandshake.game_problem(str(challenge[0]))
		if step.problem == JoinHandshake.OTHER_GAME:
			host_game_id = str(challenge[0])
		return step
	if not challenge[1] is int or challenge[1] != OnlineProtocol.VERSION:
		step.problem = JoinHandshake.OTHER_VERSION
		return step
	if not challenge[2] is PackedByteArray:
		step.problem = JoinHandshake.NOT_OURS
		return step
	var locked: bool = challenge[3] is bool and challenge[3]
	if locked and password.is_empty():
		step.problem = JoinHandshake.NEEDS_PASSWORD
		return step
	var proof := (
		JoinHandshake.proof(challenge[2], password, game_id) if locked else PackedByteArray()
	)
	step.reply = var_to_bytes([game_id, OnlineProtocol.VERSION, fingerprint, player_name, proof])
	return step


## Reads the host's verdict: empty when we are in (and [member host_name]
## is known), otherwise why not.
func read_verdict(data: PackedByteArray) -> String:
	var verdict := JoinHandshake.unpack(data, 2)
	if verdict.is_empty() or not verdict[0] is bool:
		return JoinHandshake.REFUSED
	if not verdict[0]:
		var reason := str(verdict[1])
		return reason if reason in KNOWN_REASONS else JoinHandshake.REFUSED
	host_name = PlayerName.clean(str(verdict[1]))
	return ""
