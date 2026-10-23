# Keen 5: the rules of a level in our engine

What a Keen 5 level does in CommanderPerfect so far, and where its numbers
come from. Started in milestone E3 (the shared Galaxy game, a level played
without creatures); later milestones add to it, as
[../keen4/gameplay.md](../keen4/gameplay.md) grew from D3 on. Everything
that is the same as in Keen 4 (Keen's moves, the camera, the score box,
drawing, widescreen) is described there and not repeated here. The facts
and their sources are in [research.md](research.md), the code layout in
[architecture.md](architecture.md), the files in
[file-formats.md](file-formats.md). Numbers from Omnispeak are marked
(Omni), what was seen in the user's v1.4 in js-dos "(seen)".

All positions are the original's **global units**: 16 per pixel, 256 per
tile. Times are **tics** of 1/70 s.

## The flow of a game (E3, E6)

E3 played the levels one after another, as Keen 4 did in D4; since E6 the
game goes round the world map as the original's does (Omni
`ck_game.c:CK_GameLoop`, `CK_LoadLevel`, `CK_TryAgainMenu`; seen in the
original, E6). The title, the menus and the end come in E7-E9.

| What | Then |
|---|---|
| Keen 5 picked on the start screen, or `-- --game=5` | A new game (3 lives, 5 charges, the first extra life at 20,000): the box "Keen purposefully wanders about the Omegamatic" with Keen counting down, a fade, the world map with Keen on info 3 (28, 95) |
| `-- --game=5 --level=N` | Map N at once: 0 the world map (played), 1-13 and 15 (the high-score map) played; 14 does not exist: a message |
| On the map: jump, pogo or fire on an entrance (0xC000 + n) | "One moment" (28 tics), the level's "Keen ..." box with the count-down, the fade, the level |
| The exit door (0xB1B1) or walking out of a level | Done with 1; the level-exit sound; the map's box, the fade, the map with Keen where he entered |
| The last fuse broken | Done with 14; the fuse message (two screens, each 30 tics and then a key), then the map's box and the map |
| The door to Korath III (0x0000, level 11) | Done with 1; the box "Keen steps out onto Korath III"; the map with Keen on info 26 (37, 107) facing west |
| Back on the map on Korath III (Keen's place below row 100, as after level 13) | The map's box is "Keen steps out onto Korath III" too |
| The QED destroyed (map 12) | For now the start screen (the end pages and the high scores come in E7) |
| Keen dies | One life less, the gems and the keycard gone; the box "You didn't make it past" the level with Try Again (the level again) and Exit to Armageddon (the map); up and down choose, the frame blinks every 16 tics; jump, pogo, Enter or Space take it; Escape is the map |
| No life left | The start screen (the galaxy explodes in E7: Keen 5 has no "Game Over!" box) |
| Enter | The status window (below) over the level or the map |
| Escape | The start screen |
| Shift+N / Shift+P | The next or previous map, over the missing 14, round from 15 to 0 |
| Shift+G | God mode (as the original's F10+G: nothing kills Keen but falling out of the level) |
| Shift+I | All four gems, the keycard and at least 99 charges, in a level or on the map |
| F1 | The help line; F2-F6 as in Keen 1-4 |

What each level counts as is kept in `Keen5Progress` (the original's
levelsDone: 1, or 14 by its fuse); the world map reads it (its flags,
gates and the upper shaft) and E7's secret end will (level 13 with 14).

## The world map (E6)

Map 0, the Omegamatic, a space station of three parts joined by elevator
shafts, with Korath III's surface below it (rows beyond 100). Omni
`ck_map.c`, `ck5_map.c`, `ck5_misc.c:CK5_ScanInfoLayer`, facts and
numbers; the places checked in the map, the rides watched in the original.

| What | Rule |
|---|---|
| Keen | Keen 4's map Keen: 24 units a tic on each axis, eight directions, waving after 360 tics; no water, no Foot |
| Entrances | Info 0xC001-0xC00D under his box when jump, pogo or fire is pressed: the level; his place is kept for the way back |
| Done levels | Every info word whose low byte is the level is cleared; 0xD0nn also clears its foreground tile (the gates of levels 1, 2, 3, 5, 7, 9, 11, 13); 0xF0nn gets a waving flag (FLAGFLAP1-4, 10 tics each, from a random point) at (−0x50, −0x1E0) from the holder's corner. No flag is thrown |
| Teleporter (misc 20, tile 0x427; one, on Korath III at (44, 106), to (20, 30)) | The game stops: Keen walks onto the tile, 2 units a tic per axis, at most 130 tics, his walking-north pictures by the clock (every 8 tics), the tile flashing 0xA7F/0xA80 (every 4 tics); the tile is 0x427 again; Keen stands at the info word's target (x high byte, y low byte & 0x7F), facing south; the view is put on him, sleeping objects in it wake up; sound 41; he walks out south 3 units a tic for 90 tics (walking-south pictures), the target tile flashing; it becomes tile 0 |
| Elevator going in (misc 33 left half, 34 right half) | The game stops: Keen walks onto the tile as onto a teleporter, the view following; sound 63; the door (2 × 2 tiles, one row up, from the right half one column left) closes: pictures 5 … 0 of the template in the map's corner ((2n, 0)-(2n + 1, 1)), 8 tics each; then the game goes on with Keen flying unseen and unclipped: 64 units a tic up or down, 12 sideways until the target column |
| Elevator coming out | Past the target's row (x = high byte, y = (low byte & 0x7F) + 1) he stands there facing south; the game stops again: the view follows his last flight box once more, sound 63, Keen a tile up in the door above, the door opens (pictures 0 … 5, 8 tics each), he walks out south 8 units a frame for 32 frames; then he is clipped again |
| The shafts (set when the map starts, by Keen's row) | Above row 75 or on Korath III (below 100): the bottom door (24, 76) closes, the middle-left door (22, 55) opens. Levels 4, 6, 8 and 10 all done and below row 39: the middle-right door (26, 55), to the top, opens. Above row 39 or on Korath III: the top door (24, 30) opens. In the file only the bottom door is open |
| The elevators (files) | (24, 77) bottom → (22, 57) middle-left; (22, 56) → (24, 78); (26, 56) middle-right → (24, 32) top; (24, 31) → (26, 57) |
| Korath III | After the door in level 11 Keen stands on info 26 (37, 107) facing west, not on info 3 |

**Widescreen** (ours): the map is filled with a plain yellow background
tile (850) around the station's star field, where the original's view
never comes; a wider view would show it, so it is drawn as black space
(tile 0) above row 100. Korath III's yellow ground stays. In 4:3 nothing
changes.

## The status window (E6)

Enter drops it over a level or the map, a key lifts it (Keen 4's
`GalaxyStatusDrop`; the game waits). Keen 4's window (D7) with Keen 5's
own row and labels; compared with the original v1.4 to the pixel (E6):

| Part | Keen 5 |
|---|---|
| LOCATION | The map's name; on the world map on Korath III (Keen below row 100) Korath III's base, level 13's name (seen in the original; Omnispeak always names the map) |
| SCORE, EXTRA, LEVEL | As Keen 4's |
| KEYCARD | The label printed from (80, 92), a black square (135, 91) of 10 × 10, the card (8×8 tile 40) at (136, 92) while Keen has it (the original draws this row one pixel lower than Omnispeak's numbers) |
| KEYS, AMMO, KEENS, VITALIN | As Keen 4's (VITALIN instead of DROPS) |
| Below | No wetsuit, no rescued members; the "press a key" tiles (72-91) from (120, 140) (Keen 4: 160) |

## Keen's moves (E3)

Keen 4's, unchanged: the actions in `ACTION.CK5` are the same as in
`ACTION.CK4` (Omni; research.md §1). What Keen 5 changes:

- **No moon.** Misc 16 is on two Keen 5 tiles but means nothing; Keen
  5's Keen has no moon actions and never shows it.
- **His sprites are numbered differently** from looking down on (looking
  down one earlier, then KEENONPLAT, dying as Keen 4's, from shooting on
  one further): see `Keen5Sprites`, from
  Omnispeak's `GFXCHUNK.CK5` (index = chunk − 102), checked in js-dos
  (level 1's first frame is the original's to the pixel, Keen included)
  and by eye in our screenshots of levels 1-3, 5, 9, 11-13 and 15.
- Riding a platform he "surfs" (KEENONPLAT) and landing on a fuse plays
  its sound or breaks it (E5, below). The Ampton and the Korath knocking
  him off a pole came in E4 (below).

## Items and tiles (E3)

As in Keen 4 (docs/keen4/gameplay.md, "Items and tiles"), with one item
more:

| Info value | Item | Points | Sound name |
|---|---|---|---|
| 57-60 | the gems red, yellow, blue, green (items 0-3) | | `got_gem` |
| 61-66 | 100, 200, 500, 1000, 2000, 5000 points (items 4-9) | as named | `got_item` |
| 67 | the Keg o' Vitalin: a life (item 10) | | `got_extra_life` |
| 68 | a stunner (item 11): 5 charges, 8 on Easy | | `got_stunner` |
| 69 | a stunner, only while Keen has fewer than 5 charges | | |
| **70** | **the keycard (item 12)** | 0 | `got_keycard` |

Info 70 is item 70 − 58 = 12, not 70 − 57 (Omni `CK5_ScanInfoLayer`): the
game rules map it with `more_item_infos`. The keycard lies as a sprite in
the seven levels with a security door (2, 3, 5, 7, 9, 11, 13; files), one
each.

- **Vitalin** (misc 4, the drops): 100 make a life, as Keen 4's lifewater.
  Its splash has **four pictures of 8 tics** (Omni
  `CK_ACT_CentilifeNotify1-4`); Keen 4's lifewater has three of 10.
- Item tiles (misc 21-28) as in Keen 4: Keen 5 has 21-26 (points) and 28
  (stunner), no 27 (files).
- **The keycard and the gems are lost** at the end of every level and at
  every death (Omni `CK_GameLoop`): `Keen5Inventory.drop_gems`.

## Doors (E3)

| Tile | Up at it |
|---|---|
| A door (misc 2) | Keen walks to its spot (as Keen 4's) and goes in: 5 pictures of 9 tics, 64 units up each; safe for 110 tics; at the end he is put at the target in the info plane under him (x high byte, y low byte), one tile above it + 15 units, the view on him |
| A security door (misc 32), **without the keycard** | The sound `need_keycard` (14); he stands, and with up held looks up; nothing opens |
| A security door **with the keycard** | The card is used, the sound `open_security_door` (18); a door opener (`Keen5SecurityDoor`) at tile (Keen's middle column − 2, his bottom row − 4) puts in each of the 4 × 4 foreground tiles there the tile 4 before it, three times 15 tics apart (at 15, 30 and 45 tics from the start of the frame it is placed in); Keen steps in for 45 tics (64 units up) and then goes through as through a door (not safe for 110 tics: the original does not set it) |
| Target **0xB1B1** | The level is done (the exit); Keen is out of sight for the last 9 tics (`entered_door`) |
| Target **0x0000** | The level is done as the way to Korath III (`Keen5Keen.KORATH_ENDING`); for now it goes to the next level like the exit (E6: to the world map, on Korath III) |

Checked in the files (E3, `test_keen5_level`): every security door is two
tiles wide in the middle of a 4 × 4 door picture, its target is the exit
(0xB1B1), and after the three steps its two tiles are a plain door (misc
2: tiles 1741/1742 become 1729/1730). Level 1's exit is a plain door; the
other levels with an exit have a security door.

**The teleport lightning (E5)**: when Keen starts into a plain door whose
info at his head row is 0, two bolts appear in front of everything with
the sound `teleport` (41): across (TELEPORTSPARK1/2, 6 tics each) at
(his left column's tile − 0x80, his bottom row's tile − 0x500) and down
over him (TELEPORTZAP1/2) at (his left column's tile, his top row's tile
− 0x80); they flicker until the level ends (Omni CK5_SpawnLightning).
In the files a door's target lies in its own tiles' row, which is Keen's
head row at the door, so only a door with target 0x0000 shows it: the
**one door to Korath III, in level 11 at (7, 33) and (8, 33)** (the glass
teleporter at the left of the level). Seen in js-dos: the bolts at the
same pixels as ours.

Kept as the original: the "pole-door glitch" (Keen 4's code as it is),
and a door does not lift Keen when a ceiling is over him: the door
actions move him up 64 units a step with the normal clipping, so in the
low teleporter of level 11 he stays where he is and the target is read
in his own row (Omni CK_KeenEnterDoor).

## The camera (E3)

Keen 4's rules (docs/keen4/gameplay.md, "The camera"), with **only one
kind of scroll block**: info 25, a row the view never scrolls over. Keen
5's info 26 is the arrival on Korath III on the world map (one, map 0),
not a column block.

## The score box (E3)

Keen 4's: the episode's own score box sprite (Keen 5: sprite 133) with
the digits in it, top left of the view, in 4:3 and widescreen; hidden on
a map that is only looked at.

## Pictures behind the levels (E3)

The machinery is Keen 4's (widescreen only, on by default), but Keen 5
names **no sky tiles yet**, so no level shows a picture and every level
looks as in the original (E10 makes Keen 5's own pictures).

## The creatures (E4)

Placed from the info plane by `Keen5Creatures` for the difficulty (Normal
until the menus exist): most kinds have a value for Easy and up, one from
Normal and one for Hard only (research.md §6). Objects fall asleep **6
tiles** beyond the view (Keen 4: 4); shots and lasers are gone there.
"Deadly" means: Keen dies, a stunner shot is absorbed. Speeds are units a
tic (16 units a pixel); every number is Omnispeak's (Omni) unless marked
(seen).

| Creature (info) | Moves | Keen | The stunner |
|---|---|---|---|
| Sparky (4/5/6) | 128 a step of 8 tics (16 a tic); at each walk cycle 64 in 256 to search: 8 pictures of 6 tics, looking left at the 4th and right at the 8th; Keen that way with his bottom within a tile of its own: sound `sparky_prepare_charge`, 3 × 4 pictures of 4 tics on the spot, then charges at 32 a tic (footsteps). Walls and ledges: steps back, turns (3 × 8 tics), waits 0-7 frames | Dies on touch | Stunned for good (stars +0x40 x) |
| Little Ampton (42/43/44) | Walks as the Sparky (`ampton_walk_1/_2`). Between two tiles: a computer (misc 31) at its top row → works it 5 × 12 tics; a pole (misc 1), 196 in 256 → grabs it (2 × 8 tics), climbs or slides at 32 a tic (unclipped), getting off through a pole hole (always with fewer than 4 pole tiles above, else a coin toss) or onto a floor (a coin toss at a hole); turns at the pole's ends | Pushed sideways; killed only while it is on the pole; on a pole or ledge Keen is knocked off | Stunned for good (`ampton_stun`) |
| Slicestar straight (10-12 up, 22-24 right) | As a red platform: 12 a tic, turns at B-blocks (31) | Deadly; never ridden | 20 hit points, then bursts (20 tics) |
| Slicestar diagonal (19-21) | 24 / 24 a tic, a 2 × 2 tile box kept out of walls, bounces (`slice_bump`); starts left-up, right-down or left-down, **never right-up** (the original's table) | Deadly | 50 hit points |
| Shelley (74/75/76) | Walks 16 a tic, turns at walls; at a ledge waits up to 100 tics and dives (16, −24, gravity high) when Keen is below and 1-3 tiles ahead, else turns | Pushed sideways; his middle inside its box sets it off | A stunner **or an enemy shot** sets it off |
| … exploding | Sound `shelley_explode`; its last picture 8 tics, two pieces (±32, −24, bouncing, deadly), a blast of 4 × 20 tics (deadly) | | |
| Volteface (71/72/73) | Always awake, unclipped; follows the path arrows (91-98) at 32 a tic; its first way from the arrow beside it, written into its own tile | Deadly | Stunned 300 tics, harmless, then on |
| Shikadi mine (7/8/9) | Unclipped, 10 a tic tile by tile towards Keen (nearer axis first, never back unless nothing else is free; a way is free with no solid tile in the 3 × 2 tiles ahead); its eye moves to the middle and the new side first (4 a tic). Keen near (two zones): `mine_explode`, 4 × 10 tics pulsing, six bouncing pieces, 2 × 20 tics blast | The mine is harmless; blast and pieces deadly | Absorbed |
| Robo Red (13/14/15) | 64 a step of 6 tics; with x bit 0x40 clear, Keen beside it and 16 in 256: faces him and fires 10 shots (40 tics, then 4 + 6 tics a shot; 60 sideways, 8 up/down by turns, recoil 64; `enemy_shoot`) | Deadly, and its shots | Absorbed, and it fires at once |
| Spirogrip (16/17/18) | Clings 150 tics, lets go (64 tics at 16), spins 8 × 8 tics; at a straight picture 21 in 256 flies that way at 48 (`spiro_fly`) to the next wall (`spiro_slam`) | Deadly | Absorbed |
| Spindred (77/78/79) | Its own gravity 3 on odd tics, at most 70; slams back at 40 (`spindred_slam`), every third time across at 68, falling the other way (`spindred_fly_up/_down`) | Deadly | Absorbed |
| Shikadi Master (88/89/90) | Stands 4 × 8 tics; then (192 in 256) throws a ball (48, −16, gravity mid, bouncing off walls; on a floor two sparks at ±48) or, by turns, teleports: 2 × 20 tics, two sparks, a spot up to 16 tiles round Keen (the first inside the map's edges: the original's wall check does nothing), falls, stands 60 tics | Deadly; ball and sparks too | Absorbed; it throws at once, facing right unless Keen's x is its own (kept bug) |
| Shikadi (99/100/101) | Stands 4 × 8, walks 16 a tic; with Keen holding on or at its height it goes after him and zaps the pole ahead under him; otherwise rests (16 in 256) or zaps a pole ahead on the screen. Zap: 2 × 20 tics, a spark along the pole towards Keen at 48 a **frame** (`pole_zap`) | Deadly; the spark too | 4 hit points: 3 white flashes, the 4th stuns |
| Shockshund (102/103/104) | Runs 16 a tic; every 32 tics faces Keen: 16 in 256 sits 256 tics; Keen at another height → jumps (±40, −40) — but 128 in 256 barks instead (wins, kept); bark shot 60 sideways (`shockshund_bark`), stopped by a stunner shot. At a ledge it jumps when facing Keen | Deadly; its shot too | 2 hit points: a flash, then stunned |
| Sphereful (105/106/107) | 2 × 2 tile box; every 16th tic speed +1 down (≤ 8) and ±1 towards Keen (≤ 8); walls and ceilings bounce it (`sphereful_ceiling`), floors up at 4-12 (`spindred_fly_up`); four diamonds circle it, drawn only, two in front and two behind by turns | Deadly | Absorbed |
| Korath (124; map 13) | Walks 16 a tic; 10 in 256 a step: waits 30 tics facing a random way | Harmless: pushed sideways, knocked off poles | Stunned for good |
| Laser turret (45-48 / 49-52 / 53-56: up, right, down, left) | Unseen; fires every 120 tics while awake (`enemy_shoot`); the laser 64 a tic, 4 × 8 tics, stops at walls (`enemy_shot_hit`, 2 × 10 tics) | The laser is deadly | Passes the laser |

The platforms, the GoPlats (their start arrows are written while the
level is scanned, so Voltefaces sharing their paths find them), the fuse
counter and the QED came in E5 (below); Keen on the world map and Korath
III's arrival come in E6. The sound names are listed with their numbers in
`Keen5Creatures.SOUNDS` for E8.

### The stun and the flash (E4)

As Keen 4 (docs/keen4/gameplay.md, "The stun"): the shot stops, the
creature hops (−24, at most −48), falls with the stars over it and stays
stunned. Stars: the Sparky's +0x40 across, the Ampton's and Korath's
−0x80 up, others at its position. Keen 5's two creatures with hit points
(Shikadi 4, Shockshund 2) flash **white** for two drawings at each shot
but the last (`GalaxyObject.flash_white`): every pixel of the sprite that
is not see-through is drawn in white; they are drawn when they move or
change their picture, so a standing one stays white until then.

## Platforms (E5)

Placed from the info plane by `Keen5Platforms` (Omni CK5_ScanInfoLayer);
all are drawn behind everything (priority 0) and Keen rides them as in
Keen 4 (docs/keen4/gameplay.md, "Platforms and switches"). Speeds are
units a tic.

| Info | Platform | How it moves |
|---|---|---|
| 27-30 | Red axis platform (up, right, down, left) | Keen 4's rule (`GalaxyPlatform`): 12 a tic, clipped, always awake; it turns when its leading edge enters a tile with a B-block (info 31) on its first row (column); going up or down a second B-block two tiles back holds it. No jets in Keen 5 |
| 84-87 | Purple axis platform | The same, placed 0x40 right of and below its tile's corner; going up or down it looks for the B-block **one column right** of its box's left column (its box starts 12 pixels left of its place, in the column before); its stop rule still looks at the left column. It shows PURPLEPLAT1 only: its action's timer is 0, so PURPLEPLAT2 never comes (seen in js-dos: 204 frames, never the second picture) |
| 32 | Falling platform | Keen 4's (`GalaxyFallingPlatform`) |
| 33 / 34 / 35 | Standing platform | Never moves; sleeps far from the view. **Reversed difficulty**: 33 only on Easy, 34 on Easy and Normal, 35 always (files: level 3's four 33s, levels 6, 11, 13's 35s, level 8 and 12's 33) |
| 36-39 / 80-83 | Red / purple GoPlat (starting up, right, down, left) | Always awake, never clipped, 12 a tic along the path arrows (info 91-98, diagonals too) a whole tile at a time (`GalaxyPathArrows`); at each tile it reads the arrow at its position (the purple one, placed 0x40 into its tile, 0x40 further: the same tile). Its start arrow is written into its own tile while the level is scanned |
| 40 | Sneak platform (level 1) | Waits; when a Keen is in the first picture of a jump facing it, his front 0-4 tiles from its near side and within 6 tiles up or down, it slides his way 32 a tic for 48 tics, back at 16 for 96 tics, and waits |

Standing on any of them Keen **surfs** (Omni CK_ACT_keenRidePlatform: the
picture KEENONPLAT, 4 tics again and again, the buttons work as when he
stands; he is never bored there).

**Switches** (misc 5/6) as Keen 4's, with one addition: when the target
holds a path arrow, it turns round (up ↔ down, right ↔ left, up-right ↔
down-left, down-right ↔ up-left; Omni {2,3,0,1,6,7,4,5}), so a GoPlat
goes back when it reaches that tile; any other target gets a B-block on
or off. In the files the platform switches of levels 3, 6, 8, 11, 12 and
13 all point at arrows (a GoPlat's way), level 2's at a B-block. Bridge
switches (misc 15) extend the energy bridges (misc 18) as Keen 4's; all
nine in levels 2-12 point at a bridge.

**Force fields**: the deadly tiles (misc 3: 19 tiles, 1126-1133 an
8-picture animation) are never switched off in Keen 5: no switch of
levels 1-13 points at one (files), and the bridge rule only changes tiles
with an animation offset from the target on. They kill as Keen 4's
deadly tiles.

## Fuses and the QED (E5)

A **fuse** is the foreground tile with top 57 (tile 1948, under its upper
half 1930; a flat floor, not deadly). Info 41 counts them while the level
is scanned (levels 4: 2, 6: 3, 8: 1, 10: 4, 13: 1; files: each count
matches the fuse tiles); the count is Keen's
(`Keen5Inventory.fuses_remaining`, saved with the game from E9).

| Keen comes down on a fuse | Then |
|---|---|
| From a jump or a fall | Sound `keen_land_on_fuse` (57), he lands as on any floor |
| On the pogo, slower than 48 a tic | The same sound, he bounces |
| On the pogo, 48 a tic or faster | It breaks: an explosion one tile left of his middle column at his bottom row (FUSEFLASH1 10 tics, 2 20 tics, 3 10 tics, in front; sound `fuse_break`, 52), one fuse fewer, the 1 × 2 tiles from his feet down become the map's (0, 0) and (0, 1) (the rubble, 1932 and 1950), and he goes on falling (no bounce) |

A pogo jump from the fuse itself comes back at 60 a tic and breaks it
(seen in js-dos, level 8: the fuse broke after 30 frames, ours 31; Keen
then bounced off the thin floor beside the hole, as ours by the corner
rule). With no fuse left an unseen object waits 60 tics and ends the
level as a fuse's (`Keen5LevelEnd`; the level counts 14); then the
**fuse message**: a window of 26 × 8 cells with Keen talking at its right
and "One of the four / machines protecting the / main elevator shaft-- /
toast!" (level 13, Korath III: "I wonder what that / fuse was for....")
12 pixels down, centred left of the picture; 30 tics, a key, then his
thumb up in the same box, 30 tics, a key (`Keen5Messages`). Both screens
equal the original's to the pixel (js-dos, level 8). The original waits
for the level-exit sound to end before the box (about 2.3 s in js-dos);
that comes with the sounds (E8).

**The QED** (map 12): info 41 there sets the count to 4 and places the
QED, an unseen object whose box is 0x220 units square from 0x10 left of
and above its tile (17, 12). Map 12 has no fuse tile (files), so only
the QED ends it. A **Shikadi mine's piece** touching it (a Shelley's
does not) destroys it: four fuse explosions at its tile and the tiles
right of and below it (four sounds), the 4 × 2 blocks at (16, 11) and
(16, 13) become the map's blocks at (0, 0) and (4, 0) in all three
planes (the broken machine), and 60 tics later the level ends as the
QED's (since E7 the end pages follow). The sound names of the
fuses and the lightning are listed with their numbers in
`Keen5Fuses.SOUNDS` for E8.

## The title loop (E7)

Without `--level` Keen 5 starts with its title loop, the same order as
Keen 4's (Omni CK_DemoLoop; seen in the user's v1.4, a whole round
recorded): the intro credits (the two words in red, light red where they
overlap; the four credit pictures; the zoom; the title fizzling in, 420
tics), the "DEMO" box and demo 0 (map 1), the story (the Star Wars crawl
in light cyan over its picture), demo 1 (map 3), the high scores (demo 4 on
map 15 behind the table), demo 2 (map 10), demo 3 (map 11), and round
again (a round takes about 345 s). The demos play on Normal, 3 tics a
frame, from the start of the random table, with the DEMO sign; each plays
all its recorded input (842, 1024, 1381, 1267 and 703 frames).

A key starts a new game on the world map (until E9's control panel),
Escape goes back to the start screen, F1 opens the help.

## Help (E7)

F1, in the title loop or in a game (a game waits under it): the menu
(picture 0 at (96, 8)) in the red frame (pictures 22-26), the pointing hand
(picture 18) at (48, 48 + 24 × topic); five topics: ComputerWrist (13
pages), The Game (21), The Story (4), Order Info (15), About Id (2). Up and
down choose, Enter, jump or pogo open, the arrows and page keys turn the
pages ("pg 1 of 13" in the frame's bar), Escape goes back to the menu and
leaves the help. To the pixel as the original (seen).

## The end (E7)

The QED destroyed (map 12) or E, N and D held while Keen plays (Omni
LS_DestroyedQED): the end pages, TEXT_END, or **TEXT_SECRETEND** when level
13 was done by breaking Korath III's fuse (its value 14); 9 pages each,
laid out as help pages in the frame without the bar; a page waits with the
arrow (pictures 20 and 21 at (296, 184)) dim and bright for 70 tics each;
a key goes on. After the last page the score is put on the table. All 9
pages of the normal end equal the original's to the pixel (seen).

## Game over (E7)

No life left (Omni CK5_ExplodeGalaxy; seen frame by frame): the game fades
to black and the Milky Way (picture 83) fades in, both by the EGA fade
palettes (6 tics a step: level 2 makes the dark colours black, level 1
also the bright ones their dark twins); 18 steps of 10 tics in which
palette entries 7 and 8 flash (entry 7 by the second row of the table,
entry 8 by the first; values 0x08 and 0x00 black, 0x07 and 0x0F light
grey); the screen goes black and 4000 stars fly out, 60 frames of 4 tics,
each star one step a frame until it would pass the right or bottom edge;
then GAMEOVER (picture 92) at (32, 80) for 24 s or a key. A key during the
flashing or the stars goes straight to GAMEOVER. Then the high scores.

## The high scores (E7)

Map 15 ("The Keenest"), the original's table from the program (Id Software
- '91, an empty name, Jason Blochowiak, Adrian Carmack, John Carmack, Tom
Hall, John Romero, an empty name; all 10,000), printed from (0x28, 0x23),
16 pixels a row, the score right-aligned at 0x118, XOR colour 12, no extra
column. A score that makes the table: the map's tiles behind the table,
the name typed in at its row with the blinking cursor (to the pixel as the
original, seen), kept in `user://keen5/high_scores.json` (never Keen 4's
file); then the high scores (demo 4), the title picture and the title
loop.

## The cheats (E7)

As the original's (Omni CK_PlayLoop, CK_ItemCheat): E+N+D the end; B+A+T a
box "Cheat Option! ..." until a key, then all four gems, 99 charges, a life
and the keycard. Ours from Keen 1-4: Shift+G god mode, Shift+I the gems,
the keycard and 99 charges.

## Watched in E7 (js-dos, the user's v1.4)

The title loop recorded whole and each demo frame by frame (details in
[research.md](research.md), "Watched in E7"): every frame of ours that the
recorder caught equals the original's in all five demos, once four causes
were found (the shared step on landing on a platform and when an Ampton
pushes Keen, platforms stopping on the tile's edge, a spent mine piece
drawn once more, the sprites' order); the intro's scroll, the story, the
DEMO box, the help, the 9 end pages, the name entry and the whole game
over (fade-in, flashes, stars, GAMEOVER) to the pixel.

## Watched in E6 (js-dos, the user's v1.4)

With map 0's start moved onto Korath III (details in
[research.md](research.md), "Watched in E6"): the box "Keen steps out onto
Korath III" and its count-down, both status windows (on Korath III and at
the top) and every frame of the teleporter from the jump on are equal to
ours to the pixel; the elevator's walk-in and door too; after its flight
the original's view stands 8 pixels lower (its frames run 2-4 tics, so
the last flight step overshoots further than ours).

## Watched in E5 (js-dos, the user's v1.4)

A scratch copy of `GAMEMAPS.CK5` with Keen's start moved (the E4 way;
details in research.md, "Watched in E5"), on Normal in god mode:

| What | The original | Ours |
|---|---|---|
| Red GoPlats (level 1) | Round their octagon of arrows | All 280 recorded frames at the places ours shows at one frame offset (±1 frame) |
| Purple axis platform (level 10) | Along its rail between two B-blocks, always PURPLEPLAT1 | All 204 frames where it is whole at ours' places; never the second picture |
| A fuse (level 8), a pogo from on top of it | Broke after ~856 ms, explosion one tile left, Keen bounced off the floor beside; the box after the level-exit sound | Broke after 31 frames (886 ms), the same; both message screens equal to the pixel |
| The door to Korath III (level 11) | The two bolts over the teleporter, then the world map with Keen on Korath III | The same bolts at the same pixels (72, 45) and (80, 105); the level ends for Korath III (the arrival on the map is E6) |
| The QED (map 12), a mine put beside it | The mine burst, four explosions on the QED, the machine broken (Keen fell through), about 60 tics later the end pages | The same: the QED hit 22 frames in, the level ended 30 frames (60 tics) later |

## Watched in E4 (js-dos, the user's v1.4)

A scratch copy of `GAMEMAPS.CK5` (scratchpad only) with one creature put
near Keen's start in levels 3, 4, 5, 7, 12 and 13 (Normal values; the new
info planes appended, the map headers pointing at them), played in js-dos
on Normal in god mode (F10+G) with Keen standing still, and the same files
in ours with `--data-dir-keen5=`. Details in research.md, "Watched in E4".

| Creature | The original | Ours |
|---|---|---|
| Sparky (level 3) | Searched, ran on the spot ~100 tics, charged at Keen 8 px every 4 tics (32 a tic), walked back 8 px every 8 tics (16 a tic) | The same rules and speeds |
| Little Ampton (level 5) | 8 px every 8 tics, a face picture for 8 tics at the turn, back and forth in 258 tics (sampled every ~6 tics) | 256 tics, the right turn 96 px right of Keen (original ~93) |
| Robo Red (level 12) | 4 px every 6 tics, back and forth in its 4-tile room, volleys at Keen | The same |
| Shikadi (level 13) | Stood 4 pictures, walked 8 px every 8 tics, then back and forth round Keen, about 2 tiles each way, in 128 tics | The same: ±32 px round Keen, 128 tics |
| Shelley (level 4) | Walked, turned, and exploded when Keen's middle came inside it (god mode), a blast and pieces | The same rules |
| Sphereful (level 7) | Bounced round Keen's head with its diamonds, some hidden behind it | The same (diamonds in front and behind by turns) |

## Watched in E3 (js-dos, the user's v1.4)

Headless js-dos as in D3 (docs/keen4/research.md, "Watched in D3"):
`KEEN5E`, a key, the title, New Game, Begin Normal Game; A+2 held with
Enter gives "Debug keys active", F10 held with W the warp ("Warp to which
level(1-18):"). Our 4:3 World viewport (320 × 200) compared pixel by
pixel:

- **Level 1's first view is the original's to the pixel**: two frames of
  the recording right after the fade-in equal ours with 0 pixels
  different (view, all three tile layers, Keen standing facing left, the
  score box). The other frames differ only where a creature moves (E4)
  or a tile animates.
- **Level 11 and the world map**: the same view and tiles; only the
  Little Ampton (E4), the score box (on the world map ours is hidden
  until E6) and an animated tile differ.
- The security door was not reached in js-dos: the levels' doors are far
  from Keen's start behind creatures, and a scripted walk did not get
  there quickly. Its rules are Omnispeak's and the files'
  (`test_keen5_level` opens every security door of the real levels).
