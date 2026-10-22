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

## The flow for now (E3)

As Keen 4 had it in D4; the original's flow (the world map, the boxes,
the title, the menus) comes in E6-E9.

| What | Then |
|---|---|
| Keen 5 picked on the start screen, or `-- --game=5` | Level 1 at once (a new game: 3 lives, 5 charges, the first extra life at 20,000) |
| `-- --game=5 --level=N` | Map N at once: 1-13 and 15 (the high-score map) played; 0 (the world map) shown with Keen standing, the arrows look around (E6 plays it); 14 does not exist: a message |
| The exit door (target 0xB1B1), the door to Korath III (0x0000) or walking out of the level | The next level: 1 … 13, then 1 again (14 skipped); from 15 to 1 |
| Keen dies | One life less, the gems and the keycard gone, the level again; with fewer than 0 lives the start screen |
| Escape | The start screen |
| Shift+N / Shift+P | The next or previous map, over the missing 14, round from 15 to 0 |
| Shift+G | God mode (as the original's F10+G: nothing kills Keen but falling out of the level) |
| Shift+I | All four gems, the keycard and at least 99 charges |
| F1 | The help line; F2-F6 as in Keen 1-4 |

The fuse levels (4, 6, 8, 10 and 12) have no exit door: they end when
their fuses are broken (E5). Until then they can only be left by
Shift+N.

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
- Riding a platform (KEENONPLAT) and landing on a fuse come in E5. The
  Ampton and the Korath knocking him off a pole came in E4 (below).

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

Not built yet: the teleport lightning when Keen starts into a door whose
info at his head row is 0 (research.md §4; E6), and the "pole-door
glitch" (it is kept by Keen 4's code as it is).

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

What later milestones place: platforms, GoPlats (their start arrows are
written now, so Voltefaces sharing their paths find them), the fuse
counter and the QED (E5); Keen on the world map and Korath III's arrival
(E6). The sound names are listed with their numbers in
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
