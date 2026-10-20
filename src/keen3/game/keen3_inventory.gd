class_name Keen3Inventory
extends Inventory
## What Keen carries in Keen 3. The rules are Keen 1's ([Inventory]): 4
## lives, an extra life every 20,000 points, 5 charges per raygun found,
## keycards that only count in the current level. What differs: Keen has the
## pogo stick from the start and 5 charges in a new game, and Keen 3 has no
## ship parts. A single charge (behaviour 28) adds one charge
## ([Keen3LevelSession]). The ankh's time is Keen's own ([Keen3Body]), not
## carried from level to level. See docs/keen3/gameplay.md.

## Raygun charges at the start of a game (Choco; also seen in js-dos in C1:
## a new game's status screen shows 5).
const START_CHARGES := 5


func _init() -> void:
	has_pogo = true
	charges = START_CHARGES
