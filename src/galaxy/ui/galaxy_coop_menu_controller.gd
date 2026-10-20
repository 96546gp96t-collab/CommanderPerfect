class_name GalaxyCoopMenuController
extends GalaxyMenuController
## The Galaxy control panel with what two players need (ours, milestone
## D12; docs/keen4/gameplay.md, "Two players"), on top of
## [GalaxyMenuController]. The original's cards stay as they were; the
## Configure card gets two choices at its end:
##   - TWO PLAYERS: a card with Add (Remove) Player 2 (in a game), and the
##     keys of player 1 and of player 2 when two play;
##   - ONLINE GAME: the shared online pages of [MenuController] (hosting,
##     joining by IP or Steam, the name), drawn by [GalaxyOnlinePageView].
## A player who joined somebody's game gets a main card of his own: Return
## to Game, Leave Game, Configure, Quit.

## The Two Players card and its choices.
const TWO_PLAYERS := &"two_players"
const PARTNER := &"partner"
const TWO_PLAYERS_LABEL := "TWO PLAYERS"
const ONLINE_LABEL := "ONLINE GAME"
const ADD_LABEL := "ADD PLAYER 2"
const REMOVE_LABEL := "REMOVE PLAYER 2"
const KEYS_LABEL := "PLAYER %d KEYS"
const LEAVE_LABEL := "LEAVE GAME"
## The menus drawn as online pages rather than as cards of the watch.
const ONLINE_KINDS: Array[StringName] = [ONLINE, HOST_SETUP, HOSTING, STEAM_GAMES, TEXT]

## Whether player 2 plays now (the card offers Remove instead of Add).
var two_players := false
## Whether player 2 may join or leave now (in a game, not online).
var offers_partner := false


## The main card; a player in somebody else's game gets his own.
func open_main(game_running: bool, can_save := true, partner_in := false) -> void:
	if online.role != OnlineMenuInfo.Role.CLIENT:
		super(game_running, can_save, partner_in)
		return
	_stack.clear()
	in_game = game_running
	var menu := Menu.create(MAIN)
	if game_running:
		menu.add(GalaxyMenuPages.MAIN_LABELS[GalaxyMenuPages.RETURN_ROW], CHOICE_RESUME)
	menu.add(LEAVE_LABEL, CHOICE_LEAVE_ONLINE)
	menu.add(GalaxyMenuPages.MAIN_LABELS[3], CONFIGURE)
	menu.add(GalaxyMenuPages.MAIN_LABELS[-1], CHOICE_QUIT)
	_push(menu)


## Whether the menu on top is one of the online pages.
func shows_online_page() -> bool:
	return is_open() and top().kind in ONLINE_KINDS


## The lines of the text being typed (a name, an address, a password),
## with the cursor.
func text_lines() -> PackedStringArray:
	var lines: PackedStringArray
	match _text_purpose:
		TEXT_PLAYER_NAME:
			lines = ["YOUR NAME", "The other player sees this name."]
		TEXT_ADDRESS:
			lines = ["JOIN VIA IP", "The host's address:"]
		TEXT_HOST_PASSWORD:
			lines = ["YOUR PASSWORD", "Your friend types this to join.", "Capitals count."]
		_:
			lines = ["PASSWORD", "The host's password (empty if none):"]
	lines.append(_typed_text + ("_" if cursor_shown else " "))
	return lines


func _pick(menu: Menu, item: Menu.Item) -> void:
	if menu.kind != TWO_PLAYERS:
		super(menu, item)
		return
	match item.id:
		PARTNER:
			_choose(CHOICE_SECOND_PLAYER, 0)
		KEY_SET:
			_key_set = item.value
			_push(GalaxyMenuPages.keys(_key_set))


func _pick_main(id: StringName) -> void:
	if id == CONFIGURE:
		_push(_configure_card())
	else:
		super(id)


func _pick_configure(item: Menu.Item) -> void:
	match item.id:
		TWO_PLAYERS:
			_push(_two_players_card())
		ONLINE:
			_push(_online_menu())
		_:
			super(item)


func _key_set_menu() -> Menu:
	return GalaxyMenuPages.keys(_key_set)


## The original's Configure card with Two Players and Online Game after a
## gap.
func _configure_card() -> Menu:
	var menu := GalaxyMenuPages.configure()
	menu.add(GAP + TWO_PLAYERS_LABEL, TWO_PLAYERS)
	menu.add(ONLINE_LABEL, ONLINE)
	return menu


func _two_players_card() -> Menu:
	var menu := Menu.create(TWO_PLAYERS, [TWO_PLAYERS_LABEL])
	menu.add(REMOVE_LABEL if two_players else ADD_LABEL, PARTNER, 0, offers_partner)
	for player in KeyBindings.PLAYER_ACTIONS.size():
		menu.add(KEYS_LABEL % (player + 1), KEY_SET, player + 1)
	menu.cursor = 0 if offers_partner else 1
	return menu
