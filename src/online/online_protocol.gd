class_name OnlineProtocol
extends RefCounted
## What the host and the player who joins agree on: the port, the version of
## the messages, how many may join, and the kinds of message. One place, so
## that the two sides cannot drift apart.
##
## The host runs the game; the player who joins only sends the buttons he
## holds and draws what the host sends back (see docs/online.md).

## Kinds of message, the first element of each.
enum Message {
	## host -> joiner: what is on the screen now (see [enum OnlineMessages.Scene]).
	SCENE,
	## host -> joiner: one tile of the map changed.
	TILE,
	## host -> joiner: something to show, such as a statue's message.
	EVENT,
	## host -> joiner: the state of one tick ([Snapshot]).
	SNAPSHOT,
	## joiner -> host: the buttons he holds now.
	INPUT,
	## joiner -> host: the part of the level he sees, to wake the enemies.
	VIEW,
}

## Marks a session as one of ours, in the handshake and in Steam lobbies:
## Keen 1's. Each game has its own, so that a Keen 1 host and a Keen 2
## player cannot play together (milestone B9).
const GAME_ID := "commanderperfect"
const GAME_ID_KEEN_2 := "commanderperfect-keen2"
const GAME_IDS: Array[String] = [GAME_ID, GAME_ID_KEEN_2]
## Raised whenever a message changes: a host and a player with another
## version cannot play together.
const VERSION := 1

## UDP, the same port as Together Around, so that one forwarded port on the
## router serves both games. Only this one needs forwarding to host over the
## internet.
const GAME_PORT := 24800
## The host plays too; one more Keen can join (two Keens, like two players
## on one keyboard).
const MAX_CLIENTS := 1
## Godot always gives the host this peer id.
const HOST_PEER_ID := 1

## Seconds a joining player has to answer the handshake.
const AUTH_TIMEOUT_S := 3.0
## Seconds to wait for a host that does not answer at all: a full host or a
## wrong address simply stays quiet.
const JOIN_TIMEOUT_S := 10.0
## Seconds between telling a player why he was refused and cutting the line:
## cutting at once loses the message.
const REJECT_FLUSH_S := 0.2

## Messages larger than this are not ours and are thrown away unread. A
## scene with every changed tile of a big map stays well below it.
const MAX_MESSAGE_SIZE := 65536
const MAX_AUTH_SIZE := 1024

## ENet and Steam channels: events must all arrive, in order; the picture
## of every tick may get lost, the next one replaces it.
const CHANNEL_EVENTS := 0
const CHANNEL_STATE := 1
