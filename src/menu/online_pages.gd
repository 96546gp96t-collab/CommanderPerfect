class_name OnlinePages
extends RefCounted
## The menus of playing online in Keen 1-3, for [MenuController], in the
## language in use: the main menu of a player who joined, hosting or
## joining, setting up a host, the window that tells a new host how to
## join, the friends' games on Steam and the windows for typing a name, an
## address or a password. Names, addresses and passwords stay as typed.

## Where the value of the password row starts (as the options menu has
## them); a language with a longer word moves it further right.
const LOCK_VALUE_COLUMN := 14


## The main menu of a player who joined someone else's game: the host
## decides about new games, loading and saving.
static func joined(online: OnlineMenuInfo, in_game: bool, with_story: bool) -> Menu:
	var title := "  " + Lang.text("%s'S GAME") % online.partner_name.to_upper()
	var menu := Menu.create(MenuController.MAIN, [title])
	if in_game:
		menu.add(Lang.text("Return to Game"), MenuController.CHOICE_RESUME)
	menu.add(Lang.text("Leave Game"), MenuController.CHOICE_LEAVE_ONLINE)
	if with_story:
		menu.add(Lang.text("Story"), MenuController.STORY)
	menu.add(Lang.text("Controls"), MenuController.CONTROLS)
	menu.add(Lang.text("Options"), MenuController.OPTIONS)
	menu.add(Lang.text("Quit"), MenuController.CHOICE_QUIT)
	return menu


## Hosting or joining; while hosting, how others can join and stopping.
## [param player_name] is the name the other player sees ("" when none).
static func online_menu(online: OnlineMenuInfo, player_name: String) -> Menu:
	var menu := Menu.create(MenuController.ONLINE, ["  " + Lang.text("ONLINE GAME")])
	if online.role == OnlineMenuInfo.Role.HOST:
		menu.header.append_array(online.host_lines)
		var partner := online.partner_name
		menu.header.append(
			(
				Lang.text("Playing with %s") % partner
				if not partner.is_empty()
				else Lang.text("Nobody joined yet")
			)
		)
		menu.add(Lang.text("Stop Hosting"), MenuController.CHOICE_LEAVE_ONLINE)
	else:
		menu.add(Lang.text("Host via Steam"), &"host_steam")
		menu.add(Lang.text("Host via IP"), &"host_ip")
		menu.add(Lang.text("Join via Steam"), &"join_steam")
		menu.add(Lang.text("Join via IP"), &"join_ip")
	var shown_name := player_name if not player_name.is_empty() else "-"
	menu.add(Lang.text("Your Name: %s") % shown_name, &"name")
	return menu


## Setting up a host [param by_ip] (or through Steam), with [param password]
## when [param locked].
static func host_setup(online: OnlineMenuInfo, by_ip: bool, password: String, locked: bool) -> Menu:
	var header := PackedStringArray(
		["  " + Lang.text("HOST VIA IP" if by_ip else "HOST VIA STEAM")]
	)
	if by_ip:
		header.append_array(online.address_lines())
		header.append(Lang.text("UDP port %d") % OnlineProtocol.GAME_PORT)
	else:
		header.append(Lang.text("Only your Steam friends"))
		header.append(Lang.text("can see the game."))
	header.append(password_line(password if locked else ""))
	var menu := Menu.create(MenuController.HOST_SETUP, header)
	menu.add(Lang.text("Start Hosting"), &"start")
	var word := Lang.text("Password")
	var column := maxi(LOCK_VALUE_COLUMN, word.length() + 1)
	menu.add(word.rpad(column) + OptionsPages.on_off(locked), &"lock")
	menu.add(Lang.text("Type Password"), &"type_password")
	menu.add(Lang.text("Random Password"), &"new_password")
	return menu


## "Password: ..." for a host's [param password]; "none" when it is empty.
static func password_line(password: String) -> String:
	return Lang.text("Password: %s") % (password if not password.is_empty() else Lang.text("none"))


## The friends' games found on Steam, and looking again.
static func steam_games(online: OnlineMenuInfo) -> Menu:
	var menu := Menu.create(
		MenuController.STEAM_GAMES,
		["  " + Lang.text("JOIN VIA STEAM"), Lang.text("Your friends' games:")]
	)
	for index in online.steam_games.size():
		menu.add(online.steam_games[index], &"game", index)
	if online.steam_games.is_empty():
		menu.add(Lang.text("(none found)"), &"none", 0, false)
	menu.add(Lang.text("Look Again"), &"refresh")
	return menu


## Tells a new host how a friend can join; any key closes it.
static func hosting(online: OnlineMenuInfo) -> Menu:
	var lines := PackedStringArray(["  " + Lang.text("HOSTING")])
	lines.append_array(online.host_lines)
	(
		lines
		. append_array(
			[
				"",
				Lang.text("Escape > Online Game shows"),
				Lang.text("this again."),
				"",
				MenuController.press_a_key(),
			]
		)
	)
	return Menu.create(MenuController.HOSTING, lines)


## The lines above a text being typed for [param purpose] (see the TEXT_
## constants of [MenuController]).
static func text_prompt(purpose: StringName) -> PackedStringArray:
	var lines: PackedStringArray
	match purpose:
		MenuController.TEXT_PLAYER_NAME:
			lines = ["  YOUR NAME", "", "The other player sees", "this name.", ""]
		MenuController.TEXT_ADDRESS:
			lines = ["  JOIN VIA IP", "", "The host's address:", ""]
		MenuController.TEXT_HOST_PASSWORD:
			lines = [
				"  YOUR PASSWORD", "", "Your friend types this", "to join. Capitals count.", ""
			]
		_:
			lines = ["  PASSWORD", "", "The host's password", "(empty if none):", ""]
	lines[0] = "  " + Lang.text(lines[0].strip_edges())
	for row in range(1, lines.size()):
		lines[row] = Lang.text(lines[row])
	return lines
