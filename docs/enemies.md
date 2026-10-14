# Enemies and items

How `LevelSession` and the classes in `src/actors/` play a level: what Keen
picks up, what the enemies do, and where the numbers come from. Speeds are in
pixels per tick (1/60 s), written as multiples of 1/32 pixel like in
`docs/keen-physics.md`.

## Sources

The original code is not decompiled (see `CLAUDE.md`). Sprite numbers, sizes
and hitboxes come from the sprite table in `EGAHEAD.CK1`; tile behaviors from
the table in `KEEN1.EXE`. Speeds and timings are the published constants of
Commander Genius, used as documentation only. Values marked *estimate* in the
code are guesses that still have to be compared with the original.

## Items

| Behavior | Item | Effect |
|---|---|---|
| 6 | Pizza | 500 points |
| 7 | Lollipop | 100 points |
| 8 | Soda | 200 points |
| 9 | Book | 1000 points |
| 10 | Teddy bear | 5000 points |
| 11-14 | Joystick, battery, vacuum cleaner, whiskey | Ship part, 10,000 points |
| 15 | Raygun | 5 charges |
| 16 | Pogo stick | Keen can use the pogo stick from now on |
| 18-21 | Keycard (yellow, red, green, blue) | Opens one door of that color |
| 17 | Exit | Keen walks through the door, then the level is complete |

A picked-up item leaves the gray background tile 143 behind. Keen gets an extra
life at every 20,000 points and starts with 4 lives and no charges.

**The exit** only works while Keen stands on the ground, without the pogo
stick and without firing. He then walks right by himself at 12/32 pixel per
tick, through everything, and disappears behind a line 30 pixels to the right
of the exit tile he touched. The level is over 200 ticks after he touched
it; meanwhile nothing can kill him.

**Statues** (behavior 22) show a message from `KEEN1.EXE` the first time
Keen touches them (see `docs/file-formats.md`); the game pauses until Enter.

**Doors** (behaviors 2-5) are two tiles high and solid. When Keen touches one
with the matching keycard, the keycard is used up, the door tiles become tile
143 and the door sinks into the floor (`OpeningDoor`). Every level with a door
also has a keycard of its color; a test checks that against the real data.

**Dying** loses a life and the ship parts found in that level; the level then
starts again with all its items. Keycards never carry over to another level.
After the last life the game starts over.

## Enemies

The info layer of a level says where every enemy starts (top left of its
sprite at the top left of the cell). Because a Yorp is 24 pixels high, that
can leave it a few pixels above the floor, so every enemy drops onto the
floor below it when the level starts. An enemy waits until it comes into
view (plus one tile around it, in the original 4:3 view as well as in
widescreen) and stays active from then on. Their random choices use a fixed
seed, so every attempt at a level starts out the same.

| Info | Enemy | Touching it | Shots | Behavior |
|---|---|---|---|---|
| 1 | Yorp | Pushes Keen back; landing on it stuns it | 1 | Looks around, walks towards Keen, hops now and then |
| 2 | Garg | Deadly | 1 | Looks around; charges when Keen is at its height, jumping gaps |
| 3 | Vorticon | Deadly | 4 *estimate* | Walks, turns towards Keen, jumps high at random |
| 4 | Butler robot | Pushes Keen | Immune | Walks back and forth, turns at walls and ledges |
| 5 | Tank robot | Pushes Keen gently | Immune | Like the butler; stops now and then to fire a deadly shot |
| 6-9 | Ice cannon | — | — | Invisible; fires an ice chunk every 64 ticks (up-right, up, down, up-left) |
| 10 | Chain | — | 1 | Level 16: holds a stone above the Vorticon commander |

The Vorticon in level 16 is the commander, with 105 health *estimate*.

**Ice chunks** fly at 60/32 (diagonal) or 80/32 (straight) until they hit a
wall or Keen, and then shatter into four shards. Keen is frozen for 250 ticks
and pushed in the chunk's direction; he cannot use any button until he thaws.

**The chain** in level 16: one shot breaks it, and the 9x2-tile stone below it
drops four rows, one every 6 ticks, crushing whatever is underneath. The row
it leaves behind is filled with the tiles that were above the stone.

**Pushes** from Yorps and robots move Keen on top of his own movement and die
down by 2/32 per tick *estimate*; while being pushed Keen cannot walk.

### Speeds and timings

| What | Value |
|---|---|
| Yorp walking | 19/32 |
| Garg walking / charging | 19/32 / 68/32 |
| Garg jump | 96/32 |
| Vorticon walking | 28/32 |
| Vorticon jump | 90/32 to 150/32 |
| Robots walking | 28/32 |
| Butler / tank push | 60/32 / 16/32 |
| Robots turning | 10 / 25 ticks |
| Tank aiming, then firing | 30 ticks, then 14 still |
| Raygun shot | 124/32 |
| Enemy gravity | 4/32 per tick, at most 104/32 |

## Still to compare with the original

- Vorticon and commander health, and how often Vorticons jump and turn.
- How long Yorps look around and stay stunned; how often they hop.
- The speed at which an opened door sinks and the length of the shot splash.
- How fast a push dies down, and how far Keen drifts when he flies off the
  screen after dying.
- Whether ship parts really give 10,000 points.
- Butler and tank sprites: the names in `EGAHEAD.CK1` say `CANLEFT` and
  `TANKLEFT` for the frames that face right; the frames are used by what they
  show.
