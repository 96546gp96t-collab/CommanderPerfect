class_name GalaxyMenuCards
extends RefCounted
## The pictures of a Galaxy episode's control panel (the wrist-watch menu)
## and where each card puts its choices (Omni `ck_us_2.c`, the US_Card
## records: x, y, picture; facts only). The places are the engine's, the
## same in Keen 4, 5 and 6; the picture numbers are the episode's
## ([method Keen4Episode.menu_cards]).


## A card: its title picture and the offset of its choices.
class Card:
	extends RefCounted
	## The card's title picture (of the picture range); -1: none.
	var picture := -1
	## Added to the choices' place (Omni US_Card x, y).
	var offset := Vector2i.ZERO


## The offsets of the cards by the menu's kind (Omni: main 32, 4; new game,
## sound, music, options, keyboard 8, 0; load and save 4, 3; the keys 0, 0; seen in
## v1.0: configure 8, 0, not Omnispeak's 0, 0).
const OFFSETS: Dictionary[StringName, Vector2i] = {
	MenuController.MAIN: Vector2i(32, 4),
	GalaxyMenuController.NEW_GAME: Vector2i(8, 0),
	MenuController.SLOTS_LOAD: Vector2i(4, 3),
	MenuController.SLOTS_SAVE: Vector2i(4, 3),
	GalaxyMenuController.CONFIGURE: Vector2i(8, 0),
	GalaxyMenuController.SOUND_CARD: Vector2i(8, 0),
	GalaxyMenuController.MUSIC_CARD: Vector2i(8, 0),
	MenuController.OPTIONS: Vector2i(8, 0),
	MenuController.KEY_SET: Vector2i(0, 0),
}

## The whole wrist watch (Omni PIC_WRISTWATCH).
var watch := -1
## The watch's screen alone, a masked picture (Omni MPIC_WRISTWATCHSCREEN):
## it clears the screen under a dialog.
var watch_screen := 0
## The font of the panel (Omni FON_WATCHFONT).
var font := 1
## Paddle War's title picture (Omni PIC_PADDLEWAR), and its sprites: the
## paddle and the ball on an even and on an odd column (Omni SPR_PADDLE,
## SPR_BALL0, SPR_BALL1).
var paddle_war_picture := -1
var paddle_sprite := 0
var ball_sprites := PackedInt32Array([1, 2])
## By the menu's kind ([member Menu.kind]).
var cards: Dictionary[StringName, Card] = {}


## Cards with the title pictures [param pictures] (by the menu's kind) on
## the watch [param watch_picture].
static func create(watch_picture: int, pictures: Dictionary[StringName, int]) -> GalaxyMenuCards:
	var made := GalaxyMenuCards.new()
	made.watch = watch_picture
	for kind in pictures:
		var card := Card.new()
		card.picture = pictures[kind]
		card.offset = OFFSETS.get(kind, Vector2i.ZERO)
		made.cards[kind] = card
	return made


## The card for [param kind]; one without a picture when there is none.
func card(kind: StringName) -> Card:
	if cards.has(kind):
		return cards[kind]
	var plain := Card.new()
	plain.offset = OFFSETS.get(kind, Vector2i.ZERO)
	return plain
