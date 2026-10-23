class_name Keen5Inventory
extends GalaxyInventory
## What Keen carries in Keen 5: the Galaxy inventory ([GalaxyInventory]:
## score, lives, charges, Vitalin, gems) and the keycard, the 13th item
## (Omni ck_gameState.ep.ck5.securityCard; docs/keen5/research.md §4-§5):
## taking it (item 12, no points) sets it, a security door uses it up
## ([Keen5Keen]), and it is lost at the end of every level and at every
## death, with the gems ([method drop_gems]). The fuses still to break in
## the level played (Omni ck_gameState.ep.ck5.fusesRemaining) are kept
## here too: the game's state, counted again at every level's start
## ([Keen5Fuses], milestone E5).

## The keycard's item number (Omni).
const KEYCARD_ITEM := 12
## A new game (Omni `ck_game.c`, the same as Keen 4): 3 lives, 5 charges,
## the first extra life at 20,000 points, 5 charges in a stunner.
const START_LIVES := 3
const START_SHOTS := 5
const FIRST_EXTRA_LIFE := 20000
const STUNNER_CHARGES := 5

var keycard := false
## The fuses of the level played that are not broken yet.
var fuses_remaining := 0


## The inventory of a new game.
static func new_game() -> Keen5Inventory:
	var inventory := Keen5Inventory.new()
	inventory.lives = START_LIVES
	inventory.shots = START_SHOTS
	inventory.next_life_at = FIRST_EXTRA_LIFE
	inventory.charges_per_stunner = STUNNER_CHARGES
	return inventory


## Takes item [param item]: the keycard sets [member keycard] (Omni
## CK_KeenColFunc); the others as in every Galaxy episode.
func collect(item: int, as_tile := false) -> bool:
	if item == KEYCARD_ITEM:
		keycard = true
		return false
	return super(item, as_tile)


## At a level's end and at a death the gems and the keycard are gone
## (Omni CK_GameLoop).
func drop_gems() -> void:
	super()
	keycard = false
