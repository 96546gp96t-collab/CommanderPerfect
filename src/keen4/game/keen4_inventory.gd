class_name Keen4Inventory
extends GalaxyInventory
## What Keen carries in Keen 4: the Galaxy inventory ([GalaxyInventory]:
## score, lives, charges, lifewater drops, gems) with Keen 4's new-game
## numbers. The rescued council members and the wetsuit follow with the
## world map (D7).

## A new game (Omni `ck_game.c`): 3 lives, 5 charges, the first extra
## life at 20,000 points.
const START_LIVES := 3
const START_SHOTS := 5
const FIRST_EXTRA_LIFE := 20000
## A stunner item holds 5 charges (8 on Easy, D10) (Omni).
const STUNNER_CHARGES := 5


## The inventory of a new game.
static func new_game() -> Keen4Inventory:
	var inventory := Keen4Inventory.new()
	inventory.lives = START_LIVES
	inventory.shots = START_SHOTS
	inventory.next_life_at = FIRST_EXTRA_LIFE
	inventory.charges_per_stunner = STUNNER_CHARGES
	return inventory
