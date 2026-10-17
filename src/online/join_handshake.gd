class_name JoinHandshake
extends RefCounted
## The three messages that let a player in, before he can send or receive
## anything else (Godot's authentication step):
##
##   host -> joiner   challenge: game, version, a random nonce, password or not
##   joiner -> host   answer: game, version, fingerprint of his levels, name,
##                    and the proof that he knows the password
##   host -> joiner   verdict: admitted with the host's name, or why not
##
## The password itself never travels: the proof is a hash of the nonce and
## the password, and a new nonce is made for every attempt. Everything that
## arrives is a stranger's data and is checked before it is believed. The
## host side ([JoinGate]) and the joiner's side ([JoinTicket]) use this.

## Why a player is not let in (shown by [OnlineText]).
const NOT_OURS := "not_ours"
## One of ours, but another game (Keen 1 against Keen 2).
const OTHER_GAME := "other_game"
const OTHER_VERSION := "other_version"
const OTHER_DATA := "other_data"
const WRONG_PASSWORD := "wrong_password"
const NEEDS_PASSWORD := "needs_password"
const FULL := "full"
const TOO_MANY_TRIES := "too_many_tries"
const REFUSED := "refused"
const NONCE_SIZE := 16
## Anything shorter is not an encoded value at all.
const MIN_VARIANT_SIZE := 4


## The challenge the host of [param game_id] sends to a player who knocks.
static func challenge(
	nonce: PackedByteArray, locked: bool, game_id := OnlineProtocol.GAME_ID
) -> PackedByteArray:
	return var_to_bytes([game_id, OnlineProtocol.VERSION, nonce, locked])


## The proof that whoever made it knows [param password].
static func proof(
	nonce: PackedByteArray, password: String, game_id := OnlineProtocol.GAME_ID
) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(game_id.to_utf8_buffer())
	context.update(nonce)
	context.update(password.to_utf8_buffer())
	return context.finish()


## Compares two proofs in the same time whatever they hold, so that timing
## tells nothing about how much of a guess was right.
static func same_proof(a: PackedByteArray, b: PackedByteArray) -> bool:
	if a.size() != b.size():
		return false
	var difference := 0
	for index in a.size():
		difference |= a[index] ^ b[index]
	return difference == 0


## The message as an array, or empty when it is not a sane message of ours:
## too large, not an array, or with fewer than [param least] elements.
static func unpack(data: PackedByteArray, least: int) -> Array:
	if data.size() < MIN_VARIANT_SIZE or data.size() > OnlineProtocol.MAX_AUTH_SIZE:
		return []
	var value: Variant = bytes_to_var(data)
	if not value is Array or (value as Array).size() < least:
		return []
	return value


## Why a message of [param their_game] cannot be answered by a player of
## another game: another game of ours, or not ours at all.
static func game_problem(their_game: String) -> String:
	return OTHER_GAME if their_game in OnlineProtocol.GAME_IDS else NOT_OURS


## A new random nonce.
static func make_nonce() -> PackedByteArray:
	return Crypto.new().generate_random_bytes(NONCE_SIZE)
