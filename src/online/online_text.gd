class_name OnlineText
extends RefCounted
## What the player reads when something about playing online did not work,
## as lines for a window of the game (short enough for its font).


## Why joining did not work, for [param reason] from [JoinHandshake] or
## [OnlineSession].
static func join_failed(reason: String) -> PackedStringArray:
	var lines: PackedStringArray
	match reason:
		OnlineSession.NO_ANSWER:
			lines = [
				"The host does not answer.", "Is the address right, and", "is there still room?"
			]
		JoinHandshake.WRONG_PASSWORD:
			lines = ["Wrong password."]
		JoinHandshake.NEEDS_PASSWORD:
			lines = ["This game needs a password."]
		JoinHandshake.OTHER_VERSION:
			lines = ["The host plays another", "version of CommanderPerfect."]
		JoinHandshake.OTHER_DATA:
			lines = ["The host has other level", "files: another version of", "the game data."]
		JoinHandshake.FULL:
			lines = ["Somebody already plays", "along with the host."]
		JoinHandshake.TOO_MANY_TRIES:
			lines = ["Too many wrong passwords.", "Wait a minute."]
		JoinHandshake.NOT_OURS:
			lines = ["That is not a", "CommanderPerfect game."]
		_:
			lines = ["The host did not let you in."]
	return _with_prompt(lines)


static func host_left() -> PackedStringArray:
	return _with_prompt(["The host has left the game."])


## Hosting could not start: [param error] from the transport.
static func host_failed(error: Error) -> PackedStringArray:
	if error == ERR_ALREADY_IN_USE or error == ERR_CANT_CREATE:
		return _with_prompt(
			["Could not host: port %d" % OnlineProtocol.GAME_PORT, "is already in use."]
		)
	return _with_prompt(["Could not host:", error_string(error)])


## Something Steam said, as one or more lines.
static func steam(reason: String) -> PackedStringArray:
	var lines := PackedStringArray(["Steam:"])
	var line := ""
	for word in reason.split(" "):
		if not line.is_empty() and line.length() + 1 + word.length() > MenuController.TEXT_WIDTH:
			lines.append(line)
			line = ""
		line = word if line.is_empty() else line + " " + word
	lines.append(line)
	return _with_prompt(lines)


static func _with_prompt(lines: PackedStringArray) -> PackedStringArray:
	lines.append_array(["", "   Press a key"])
	return lines
