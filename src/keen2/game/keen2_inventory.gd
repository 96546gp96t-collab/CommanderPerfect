class_name Keen2Inventory
extends Inventory
## What Keen carries in Keen 2. The rules are Keen 1's ([Inventory]): 4
## lives, an extra life every 20,000 points, 5 charges per raygun found,
## keycards that only count in the current level. What differs: Keen has the
## pogo stick from the start, and Keen 2 has no ship parts (its eight cities
## come with the world map, milestone B6). See docs/keen2/gameplay.md.

## Raygun charges at the start of a game. estimate: check against the
## original. Commander Genius reads them from a code byte of KEEN2.EXE,
## which we do not read (docs/keen2/research.md, section 6).
const START_CHARGES := 0


func _init() -> void:
	has_pogo = true
	charges = START_CHARGES
