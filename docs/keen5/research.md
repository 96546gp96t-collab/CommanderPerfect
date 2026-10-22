# Keen 5 ("The Armageddon Machine"): research

Research notes for adding episode 5 to CommanderPerfect, collected in
milestone E1 (see [roadmap.md](roadmap.md)). Written for the developer of
E2 and later: look here before searching again. When a fact is checked
against the original, update it here; facts that end up as code get their
final, short description in [file-formats.md](file-formats.md) and a
`gameplay.md` (written from E3 on).

Keen 5 is the second **Galaxy** episode. Everything in
[../keen4/research.md](../keen4/research.md) §2-§4 (time, units, the
action system, physics and tiles) holds unchanged; this page lists what
is different or new. Keen's own moves are Keen 4's (§1, "Keen").

Every fact names its source:

- **(files)**: checked in the user's own files (v1.4, §0) with scratch
  scripts that ran our Galaxy readers; every dump stayed in the scratchpad.
- **(Omni)**: Omnispeak (github.com/sulix/omnispeak, commit 144f21e, the
  same as for Keen 4), a GPL reimplementation of Keen 4-6 v1.4.
  References are `file:function` under `src/`, or its text tables in
  `data/keen5/` (`ACTION.CK5`, `EPISODE.CK5`, `GFXCHUNK.CK5`,
  `STRINGS.CK5`). The user decided for Keen 4 (19-10-2026) that its facts
  and numbers may be used, marked `(Omni)`; never its code. Whether that
  holds for Keen 5 is question 2 in §13 (advice: yes).
- **(CG)**: Commander Genius (`src/engine/keen/galaxy/ep5`, `src/fileio`),
  documentation only; where it disagrees with Omnispeak, Omnispeak wins.
- **uncertain**: inferred, contradictory, or memory.

Units: 16 units = 1 pixel, 256 = 1 tile, a tic is 1/70 s (Keen 4 §2).

## 0. Versions: the user has 1.4

The user uploaded their Keen 5 on 22-10-2026 (a zip): `KEEN5E.EXE`
(106,417 bytes), `EGAGRAPH.CK5` (573,664), `GAMEMAPS.CK5` (73,721),
`AUDIO.CK5` (101,990), `CONFIG.CK5`, `KEEN5.VIF`. Copied to
`game_data/keen5/` (ignored by git) for this session only.

- `KEEN5E.EXE` is **LZEXE 0.91** (`LZ91`); `DosExecutable` unpacks it to
  an image of **254,832 bytes = 0x3E370**, which is CG's v1.4 image (CG
  `CExeFile.cpp`: unpacked v1.4 266,096 bytes with a 0x2C00 header; v1.0
  262,176 bytes). So the user has **v1.4** (files + CG), the version
  Omnispeak and CG describe. Unlike Keen 4 (1.0 against sources of 1.4),
  the sources and the files agree here.
- There is **no "(v1.4)" sign-on text** in the image (files): Keen 4's way
  to read the version does not work. `Keen5Episode.EXECUTABLE_SIZES`
  names it by the program size (E2): `{"1.4": 106417}` for the packed
  file the user has; the unpacked 1.4 (266,096) and 1.0 (262,176) from CG.
- The help and end pages have the **red frame** (pictures 22-26, files),
  as Keen 4 v1.4.
- Nothing is known about Keen 5 **v1.0** (offsets, counts, behaviour). It
  is found by content like 1.4; it can only be tested if the user has it.
- Keen 5 was **never shareware**: no free copy exists; every real-data
  test needs the user's files.

## 1. Files, the EXE, the engine (files, Omni)

The readers of Keen 4 (`src/galaxy/data/`) read Keen 5 almost unchanged
(files, E1): see [file-formats.md](file-formats.md) for the header places,
the chunk ranges, the maps and the sound chunks, and the **two additive
changes** they need (the tile border 1512, texts before misc chunks).

Counts (files, agreeing with Omni `GFXINFOE.CK5` and CG): 3 fonts, 93
pictures, 3 masked pictures, 346 sprites, 104 + 20 8×8 tiles, 1512 + 2952
16×16 tiles, 7 texts (HELPMENU, CONTROLS, STORY, ABOUTID, END,
**SECRETEND**, ORDER), 5 misc (ORDERSCREEN, COMMANDER, KEEN, OUTOFMEM,
**GALAXY**: the 4000 stars of the game-over scene), 5 demos; 4931 chunks.
Audio: 64 PC sounds, 64 AdLib sounds, 64 empty digitised slots, 14 songs;
206 chunks.

### Where Omnispeak branches per episode

The episode definition (`ck_ep.h`) has only the extension, the episode
file and `scanInfoLayer` (`CK5_ScanInfoLayer`). Everything else is in
`EPISODE.CK5` or an `if (ep == EP_CK5)` in shared code.

`EPISODE.CK5` values that differ from Keen 4 (Omni):

| Variable | Keen 5 | Keen 4 | Meaning |
|---|---|---|---|
| `CK_activeLimit` | **6** | 4 | Tiles beyond the view where objects fall asleep (`GalaxyWorld.SLEEP_MARGIN`) |
| `CK_highScoreLevel` | 15 | 19 | The high-score map |
| High-score margins | top 0x23, left 0x28, right 0x118 | 0x33, 0x18, 0x128 | |
| `CK_highScoreFontColour` | 12 | 15 | |
| `CK_EndingMusicLevel` | 14 | 7 | Song of the end |
| `CK_StarWarsMusicLevel` | 17 | 12 | Song of the story |
| `LASTSOUND` | 64 | 52 | |

The same in both: the warp/enter range 1-18, done levels 1-17, world map
0, the easy-jump gravity, the menu tiles (items 92-97, scroll icons
98/99/102/103; files: the 8×8 tiles sit where Keen 4's do: digits 41/42,
gems 36-39).

### The game state (Omni `ck_def.h:CK_GameState`, `ck_game.c`)

Keen 4's `wetsuit` and `membersRescued` become **`securityCard`**, an
unused word, and **`fusesRemaining`**. `levelsDone[]` is **not a
boolean**: a normal exit stores 1, a level ended by breaking its fuse 14
(`LS_KorathFuse`); the secret end checks `levelsDone[13] == 14`.

New level states: 13 `LS_TeleportToKorath`, 14 `LS_KorathFuse`, 15
`LS_DestroyedQED`.

Keen-5-only branches in shared code (Omni):

- `CK_GameLoop`: after every level (also a death) the gems **and the
  keycard** are taken away. `LS_TeleportToKorath` ends like a completed
  level (sound 13, done, back to the map). `LS_KorathFuse`: sound 13,
  done = 14, the fuse message (§4), back to the map. `LS_DestroyedQED`:
  the end (§9). Game over is `CK5_ExplodeGalaxy` (§9).
- `CK_LoadLevel`: on map 0 with Keen below row 100 the loading box says
  "Keen steps out\nonto Korath III".
- `CK_MapLevelMarkAsDone`: **no thrown flag**; every 0xF0nn place gets a
  waving flag at once.
- `CK_PlayLoop` free-items cheat also gives the keycard; E+N+D gives
  `LS_DestroyedQED`.
- The status window: "KEYCARD" instead of the wetsuit, no "RESCUED" (§10).
- The high-score table has no extra column (Keen 4 draws the council
  members).
- `CK_PhysFullClipToWalls`: the box-clipped classes are the Slicestar
  and the Sphereful (2 × 2 tiles).
- `CK_BasicDrawFunc4`: stun stars at Sparky +0x40 x, Ampton −0x80 y,
  Korath −0x80 y.

### Keen

`ACTION.CK5` against `ACTION.CK4` (offsets and sprites masked): Keen's
actions are **identical**, so walking, the jump (−40 for 18 tics), the pogo
(−48 for 24 tics), poles, ledges and shooting are Keen 4's (Omni). The
differences:

- no moon (`keenMoon1-3`; misc 16 exists on two tiles but nothing uses it);
- **`keenRidePlatform`**: standing on a platform (`topTI == 0x19`) Keen
  shows the "surfing" sprite KEENONPLAT (UnscaledFrame, stick 1, 4 tics,
  velY 32, think `CK_HandleInputOnGround`);
- **`keenEnterSecurityDoor`** (step, 45 tics, velY −64, then the door
  chain) and **`keenEnteredDoor`** (invisible, 9 tics, then
  `CK_KeenEnterDoor`); an unused `keenCantEnterDoor`;
- touching an **Ampton or Korath** while on a pole or hanging makes Keen
  fall (`keenFall1`, no push);
- landing on a **fuse** (§4);
- the **13th item**, the keycard (§5).

The action records in the 1.4 EXE are at the data segment 0x30340 + their
`ACTION.CK5` offset (CG); we do not read them (they hold code addresses),
as for Keen 4.

## 2. Time and units

As Keen 4 (35 logic frames a second, 2 tics; demos 3).

## 3. The action system

As Keen 4. `ACTION.CK5` has 312 actions (Keen 4: 370); the line format
and the five types are Keen 4's.

## 4. Mechanics that Keen 4 does not have

### The keycard and the security door (Omni `ck_keen.c`, `ck_obj.c`)

- The **keycard** is info 70, item 12 (sprite SECURITYCARD, 0 points,
  sound 55); taking it sets `securityCard`. It is lost at the end of every
  level and at a death.
- The **security door**: foreground misc **32** (two tiles, 1741 and 1742,
  animation offset −4; Omni `TILEINFO.CK5`). Up at it: Keen moves to the
  middle of the door as at a normal door. Without the card: sound 14,
  nothing else. With it: the card is used, sound 18, a door opener is
  placed at tile (Keen's middle column − 2, Keen's bottom row − 4) that
  every 15 tics replaces the 4×4 foreground tiles there by "tile − 4",
  three times (`CK_SecurityDoorOpen`); Keen plays
  `keenEnterSecurityDoor` (45 tics) and then the normal door chain.
- **Gem holders** (misc 7-10) as in Keen 4.

### Doors and the exit (Omni `CK_KeenPressUp`, `CK_KeenEnterDoor`)

- A normal door (misc 2) as in Keen 4: its target is the info word under
  Keen's feet (x high byte, y low byte).
- Target **0xB1B1** ends the level (the exit door). Keen 5 has no exits by
  walking off the side (files: 0xB1B1 appears twice in most levels, the
  two halves of the exit door).
- Target **0x0000** gives `LS_TeleportToKorath` (§8). Which level holds it
  is to be read from the maps (uncertain; E6). A Keen knocked off a pole
  into a door can read a wrong target too (a real bug of the original,
  Omni `ck_poleDoorGlitch`, kept by default).
- When Keen starts into a door whose info at his **head** row is 0, a
  **teleport lightning** appears (sound 41): a horizontal bolt at (tile x
  of Keen·256 − 0x80, Keen's bottom row·256 − 0x500) and a vertical one at
  (Keen's tile x·256, Keen's top row·256 − 0x80); TELEPORTSPARK1/2 and
  TELEPORTZAP1/2, 6 tics each. Which doors show it (exit doors only?) is
  to be checked in the maps (uncertain).

### Fuses and the Quantum Explosion Dynamo

- A **fuse** is a foreground tile with top value **57** (tiles 1948 and
  1949; 57 & 7 = 1: a flat floor, not deadly). Landing on it from a jump
  only plays sound 57. A **pogo landing with velY ≥ 48** breaks it
  (`CK_KeenBreakFuse`): a fuse explosion (FUSEFLASH1 10 tics, 2 20 tics,
  3 10 tics, sound 52, one tile left of the fuse), `fusesRemaining` − 1,
  and the fuse's 1 × 2 tiles become the foreground tiles at map (0,0) and
  (0,1). At 0 a level-end object waits 60 tics and ends the level:
  `LS_DestroyedQED` on map 12, else `LS_KorathFuse`.
- `fusesRemaining` is counted from **info 41** at every level load (on map
  12 info 41 sets it to 4 and places the QED); a loaded game takes the
  saved value.
- **The fuse message** (`CK5_FuseMessage`): a window 26 × 8 with the
  picture KEENTALK1 on the right: "One of the four\nmachines protecting
  the\nmain elevator shaft--\ntoast!\n" (level 13: "I wonder what that\nfuse
  was for....\n"); 30 tics and a key; then KEENTALK2 (thumbs up), 30 tics
  and a key.
- **The QED** (map 12) is an invisible object with a box of 0x220 units
  from 0x10 left of and above its tile. Only the **shrapnel of a Shikadi
  mine** touches it: four fuse explosions at its corners, the 4 × 2 tile
  blocks at the fixed places (16,11) and (16,13) are replaced by the ones
  at map (0,0) and (4,0), the level-end object, the QED removed.
  Omnispeak would also let four broken fuses end map 12; CG only the mine
  (uncertain whether map 12 has fuse tiles: E5 reads it from the map).

### Switches, bridges, platforms on paths

- Switches (misc 5/6) as in Keen 4: they toggle the **B-block** (info 31)
  at their target, or, when the target holds a **path arrow** (info
  91-98), turn the arrow round with the table {2,3,0,1,6,7,4,5} (Keen 5
  only, Omni `CK_KeenPressSwitchThink`).
- Bridge switches (misc 15) and bridges (misc 18, 59 tiles with
  animation offset ±4: the energy bridges) as in Keen 4.
- Deadly tiles: misc 3 (19 tiles, some animated: likely the force fields)
  and top value 9 (deadly floor, 12 tiles). Whether a switch turns a
  force field off: check in the maps (uncertain; E5).
- **Not in Keen 5**: darkness, conveyor belts, zappers (Keen 6), water and
  swimming (misc 11-14 unused), the moon.

### Map templates in the top-left corner

Several replacements copy tiles from the map's top-left corner (rows 0-1,
outside the scroll area): the fuse rubble (0,0)/(0,1), the QED rubble
(0..7, 0..1), the elevator door frames (0..11, 0..1) on the world map.
`set_tile` must also update the xBRZ and HD layers (as Keen 4's gem doors).

## 5. Items, score and the inventory

As Keen 4 (Omni `ck_keen.c`), with one item more:

| Info | Item | Note |
|---|---|---|
| 57-60 | gems (items 0-3) | red, yellow, blue, green |
| 61-66 | 100, 200, 500, 1000, 2000, 5000 points (items 4-9) | Gum, Marshmallow, Chocolate milk, Tart Stix, Sugar Stoopies, Bag of Sugar (help pictures; order uncertain) |
| 67 | extra life (item 10), the Keg o' Vitalin | |
| 68 | stunner (item 11) | |
| 69 | stunner, only with fewer than 5 charges | |
| **70** | **keycard (item 12)** | sound 55, 0 points |

Vitalin (misc 4, the drops): 100 give a life, as Keen 4's drops.
Item objects with `user1 > 12` are ignored (Keen 4: > 11).

## 6. The info plane in levels (Omni `ck5_misc.c:CK5_ScanInfoLayer`; CG agrees; checked against the files)

"a / b / c" is Easy and up / Normal and up / Hard only. The y offsets of
the spawns are in `EPISODE.CK5`.

| Value | Spawns | Note |
|---|---|---|
| 1 / 2 | Keen facing right / left | and the score box |
| 3 | Keen on the world map | skipped after `LS_TeleportToKorath` |
| 4 / 5 / 6 | Sparky | y −0x100 |
| 7 / 8 / 9 | Shikadi mine | y −0x1F1 |
| 10 / 11 / 12 | Slicestar, vertical | moves like an axis platform |
| 13 / 14 / 15 | Robo Red | y −0x400 |
| 16 / 17 / 18 | Spirogrip | y −0x100 |
| 19 / 20 / 21 | Slicestar, diagonal | |
| 22 / 23 / 24 | Slicestar, horizontal | |
| 25 | scroll block (a row; as Keen 4's 25) | |
| **26** | **not a scroll block**: on the world map Keen's arrival on Korath III | Keen 4 and 6: a column block. Files: one 26, on map 0 |
| 27-30 | red axis platform up / right / down / left | |
| 31 | B-block: turn point of platforms and straight Slicestars, stop of falling platforms | switches toggle it |
| 32 | falling platform | as Keen 4 |
| **33 / 34 / 35** | **standing platform**, difficulty **reversed**: 33 Easy only, 34 Easy and Normal, 35 always | |
| 36-39 | red GoPlat, start up / right / down / left | follows the arrows |
| 40 | sneak platform | |
| 41 | fuse counter; on map 12 the QED | |
| 42 / 43 / 44 | Little Ampton | y −0x80 |
| 45-48 / 49-52 / 53-56 | laser turret up / right / down / left | |
| 57-70 | items (§5) | |
| 71 / 72 / 73 | Volteface | needs an arrow next to it |
| 74 / 75 / 76 | Shelley | |
| 77 / 78 / 79 | Spindred | y −0x80 |
| 80-83 | purple GoPlat | +0x40 in x and y |
| 84-87 | purple axis platform | +0x40 |
| 88 / 89 / 90 | Shikadi Master | y −0x180 |
| 91-98 | **path arrows** up, right, down, left, up-right, down-right, down-left, up-left | not spawned; read by GoPlats and Voltefaces |
| 99 / 100 / 101 | Shikadi | y −0x100 |
| 102 / 103 / 104 | Shockshund | y −0x80 |
| 105 / 106 / 107 | Sphereful | y −0x100 |
| 124 | Korath | y −0x80; files: 25 of them, all on map 13 |
| 125 | nothing (loads the lightning sprites) | |

Values 108-123 are unused; values ≥ 0x100 are targets (x high byte, y
low byte) for doors, gem holders, switches, teleporters and elevators.
After the scan every object is put to sleep except Volteface, the
platforms, Keen and the score box. In the files (E1) every value in a
level falls in this table or is ≥ 0x100.

## 7. Creatures and objects (Omni `ck5_obj1/2/3.c`, `ck_obj.c`, `ACTION.CK5`)

How stuns work: as Keen 4 (a stunned creature falls with stars and stays
stunned). "Deadly" is Omni `CK_DeadlyCol`: a stunner shot is absorbed,
Keen dies. Most of Keen 5's cast **cannot be stunned**.

| Creature (class) | Moves | Kills Keen | Stunner |
|---|---|---|---|
| **Sparky** (9) | Walks 16 units/tic (4 × 8 tics, +128 a step). On each first frame with chance 0x40/256 it searches (8 × 6 tics, looking left at frame 3 and right at frame 7: Keen within ±0x100 of its bottom on that side). Then sound 58, 3 × (4 × 4 tics) in place, and charges at 32 units/tic (step sounds on frames 1 and 3). At walls and ledges it turns (3 × 8 tics) after a random 0-7 tics | Touch | Stunned for good (stars +0x40 x) |
| **Little Ampton** (14) | Walks like Sparky (sounds 31/32 on frames 0 and 2). In front of a computer (misc 31): 5 × 12 tics at it. At a pole (misc 1), chance 0xC4/256: climbs up or slides down at 32 units/tic (dismount rules with 50 % chances, Omni `CK5_AmptonPoleThink`). Turns at walls and ledges | **Only while on a pole**; otherwise it pushes Keen; knocks Keen off poles | Stunned for good (sound 33) |
| **Slicestar** (11) | Straight (info 10-12, 22-24): 12 units/tic, turns at B-blocks, **20 hit points**. Diagonal (19-21): 24/24 units per tic, box-clipped (2 × 2 tiles), bounces (sound 6), **50 hit points**, starts left-up, right-down or left-down (never right-up: an original bug) | Touch | Each shot is absorbed and costs one hit point; at 0 it bursts (20 tics) |
| **Shelley** (9, Sparky's class number) | Walks; at a ledge waits up to 100 tics and dives (vx ±16, vy −24, gravity) when Keen is below and 1-3 tiles ahead | Its explosion and its two pieces | It **explodes** (sound 36) when a stunner **or enemy** shot hits it, when it lands from a dive, or when Keen's middle is inside its box (else Keen is pushed). The explosion (4 × 20 tics) and two bouncing pieces (vx ±32, vy −24) are deadly |
| **Volteface** (16) | Always awake, unclipped; follows the path arrows at 32 units/tic (the GoPlat rule); 4 × 6 tics | Touch | Stunned **300 tics** (harmless meanwhile), then moves on; cannot be killed |
| **Shikadi mine** (10) | Unclipped, 10 units/tic, picks a direction towards Keen at each tile (a free direction: no tile with a side in the 3 × 2 tiles ahead), the eye moves first. Explodes when Keen is close (two zones, Omni `CK5_MineMove`): sound 5, 4 × 10 tics pulsing, then six bouncing pieces (table in Omni `CK5_MineExplode`) and 2 × 20 tics of blast | The blast and the pieces; **the mine itself is harmless** | Absorbed; invincible. Its pieces destroy the QED |
| **Robo Red** (12) | Walks 64 units per 6-tic step; with Keen at its height and chance 0x10/256 it faces him and fires 10 shots (40 tics, then 4 + 6 tics per shot; shot vx ±60, vy ∓8 alternating, recoil 0x40) | Touch and shots | Absorbed, and it **fires** its 10 shots; invincible |
| **Spirogrip** (13) | Clings to a wall 150 tics, lets go (64 tics at 16 units/tic), spins (8 × 8 tics); on a straight frame, chance 21/256, flies that way at 48 units/tic (sound 61) to the next wall (sound 27) | Touch | Absorbed; invincible |
| **Spindred** (18) | Bounces up and down: vy changes by 3 on odd tics (at most 70); bounces with ∓40 (sound 28), every third bounce turns round with ∓68 (sounds 16/37) | Touch | Absorbed; invincible |
| **Shikadi Master** (19) | Stands (4 × 8 tics); then shoots (a ball, vx ±48, vy −16, gravity, bouncing off walls; on the floor two sparks vx ±48) or teleports (2 × 20 tics with sparks and sound 39, a spot near Keen: x = RndT/8 + Keen's middle column − 16, y likewise, up to 9 tries inside the map; falls; 60 tics) | Touch, ball, sparks | Absorbed and it shoots at once (bug: faces right unless Keen's x is its own); invincible |
| **Shikadi** (20) | Walks; near Keen's height or with Keen on a pole it follows him and zaps the pole in front (2 × 20 tics; a spark runs along the pole at 48 units/tic towards Keen, sound 40) | Touch, spark | **4 hit points**: three shots flash it white (2 frames), the fourth stuns it for good |
| **Shockshund** (21) | Runs (+128 a step); every 32 tics faces Keen; chance 0x10/256 sits 256 tics; jumps (vx ±40, vy −40) when Keen is at another height; chance 0x80/256 barks a shot instead (vx ±60) | Touch, shot | **2 hit points**: flash, then stunned for good |
| **Sphereful** (22) | Box-clipped (2 × 2 tiles); every 16 tics drifts ±1 towards Keen (at most 8); bounces off walls and ceiling (sound 59) and floors (sound 16); four diamonds circle it (drawn only, a 16-step table in Omni `CK5_SpherefulDraw`) | Touch | Absorbed; invincible |
| **Korath** (23) | Walks; chance 10/256 a step to wait 30 tics facing a random way | Harmless: pushes Keen, knocks him off poles | Stunned for good |
| **Laser turret** (15) | Waits 120 tics, fires at 64 units/tic (LASER1-4, 8 tics; on a wall sound 30, LASERHIT 2 × 10 tics); shots exist only on screen | Shot | — |

Platforms (Omni `ck_obj.c`, `ck5_misc.c`):

- **Red axis platform** (27-30) as Keen 4's (12 units/tic, turns at a
  B-block). **Purple** (84-87): the same, checks one tile further right
  when moving vertically, two sprites (whether they animate is uncertain).
- **GoPlat** (36-39 red, 80-83 purple): always awake, unclipped,
  12 units/tic; at each tile it reads the arrow at its position + 0x40 and
  goes that way (diagonals too); a GoPlat on a tile without arrow is an
  error in the original. It writes its start arrow into its own tile.
- **Falling platform** (32) as Keen 4.
- **Standing platform** (33-35): never moves.
- **Sneak platform** (40): when Keen starts a jump facing it, his front
  0-4 tiles away and within ±6 tiles in height, it slides away in his
  direction 48 tics at 32 units/tic, and back 96 tics at 16 units/tic.
- Keen on a platform: `keenRidePlatform` (§1).

Sprites (Omni `GFXCHUNK.CK5`; these are **chunk** numbers of v1.4, the
sprite index is chunk − 102, files): Keen standing right 108 (sprite 6,
as Keen 4), score box 235, map Keen 242-267, flags 268-278, Korath
294-303, Master 304-319, Shikadi 320-336, Shockshund 337-357, Sphereful
358-365, Sparky 366-377, mine 378-384, Slicestar 385-386, Robo Red
387-392, Spirogrip 393-404, Ampton 405-416, Volteface 417-421, purple
platform 422-423, Spindred 424-427, Shelley 428-445, platform 446, mini
platform 447. E2 checks a few by eye in the data viewer.

## 8. The world map (map 0, the Omegamatic; Omni `ck_map.c`, `ck5_map.c`, `ck5_misc.c`)

- **Map Keen** as Keen 4 (24 units/tic, the walk, waving after 360 tics),
  **no water, no Foot, no thrown flag**.
- **Entering a level**: jump, pogo or fire on 0xC000 + n (files: 0xC001 to
  0xC00D, levels 1-13), sound 12.
- **Done levels** (1-17): their info words are cleared; 0xD0nn also clears
  the foreground tile (a gate opens); 0xF0nn gets a waving flag (FLAGFLAP
  1-4, 10 tics) at (−0x50, −0x1E0) (Keen 4: +0x60). Files: 13 0xF0nn, and
  0xD0nn for levels 1, 2, 3, 5, 7, 9, 11, 13.
- **Teleporters** (misc 20, tile 1063): sound 41, Keen walks onto the tile
  (2 units/tic, at most 130 tics), the tile flashes (0xA7F/0xA80 every 4
  tics), Keen jumps to the info target, objects there wake, sound 41,
  Keen walks out south (3 units/tic, 90 tics); the tile is cleared.
- **Elevators** (misc 33 left, 34 right; tiles 1864/1865): Keen walks in,
  sound 63, the door closes (6 frames × 8 tics, from the templates at map
  (frame·2, 0..1)), Keen flies invisibly (64 units/tic vertically, 12
  horizontally) to the target (x = high byte, y = (low byte & 0x7F) + 1),
  sound 63, the door opens, Keen walks out south (32 × 8 units).
- **The shafts** (set when the map loads, by Keen's row): rows 0-38 the
  top, 39-74 the middle, 75-100 the bottom (the start), > 100 Korath III.
  The upper shaft opens when levels **4, 6, 8 and 10** (the four fuse
  levels) are done. Fixed places: (24,76), (22,55), (26,55), (24,30)
  (Omni `CK5_ScanInfoLayer`; to be checked in the map in E6).
- **Korath III**: after `LS_TeleportToKorath` the map loads without the
  info-3 Keen, Keen stands on info 26 facing west, the box says "Keen
  steps out onto Korath III".

## 9. Levels, the story and the end (Omni `STRINGS.CK5`, `EPISODE.CK5`; names checked in the files)

| Map | Name (Omni) | Note | Song |
|---|---|---|---|
| 0 | Omegamatic (files: "Armageddon Mach") | world map | 11 Robo Red Rock |
| 1 | Ion Ventilation System | the start | 5 Wednesday at the Beach |
| 2 | Security Center | | 7 Almost Out of Breath |
| 3 | Defense Tunnel Vlook | | 9 Be Very Sphereful With My Diamonds |
| 4 | Energy Flow Systems | **fuse** | 10 Spiro Grip Me Tighter |
| 5 | Defense Tunnel Burrh | | 9 |
| 6 | Regulation Control Center | **fuse** | 10 |
| 7 | Defense Tunnel Sorra | | 9 |
| 8 | Neutrino Burst Injector | **fuse** | 10 |
| 9 | Defense Tunnel Teln | | 9 |
| 10 | Brownian Motion Inducer | **fuse** | 10 |
| 11 | Gravitational Damping Hub | | 3 Just Snoopin' Around |
| 12 | Quantum Explosion Dynamo | **the last level** | 13 Mars, the Bringer of War |
| 13 | Korath III Base | **secret**, with a fuse | 4 Playing Bagpipes Nearly Kilt Me! |
| 14 | BWBMegarocket | **not in GAMEMAPS** (files) | 12 Fanfare (the end) |
| 15 | High Scores | | 2 Skating O'er the Ice |

The song is the map number; 16 Rock Me (unused), 17 Having Tea With
Little Ampton (the story), 18 This Is Where I Came In! (game over), 19 A
Shikadi Aire (help) (Omni). The death box: "You didn't make it past" /
"Try Again" / **"Exit to Armageddon"**.

- **The end** (`LS_DestroyedQED`, or E+N+D): the end text pages (TEXT_END,
  or **TEXT_SECRETEND** when the Korath III fuse was broken), the
  blinking arrow every 70 tics, the Fanfare; then the high-score entry and
  the title loop. No scene of its own.
- **Game over** (`CK5_ExplodeGalaxy`): fade, the picture MILKYWAY, sound
  54; 18 steps of 10 tics that flash palette entries 7 and 8; sound 53 and
  60 frames of 4000 stars flying out (the misc chunk GALAXY: x, dx, y, dy
  in 1/128 px); the normal palette, song 18, GAMEOVER at (32,80) for 24 s
  or a key; the high-score entry. A whole scene, not Keen 4's box.
- **High scores**: map 15; default names "Id Software - '91", "", "Jason
  Blochowiak", "Adrian Carmack", "John Carmack", "Tom Hall", "John
  Romero", "", all 10,000; no extra column.
- **Help** (F1, song 19): HELPMENU, CONTROLS, STORY, ORDER, ABOUTID.
- **Demos**: five chunks; the title loop plays demos 0-3 (Keen 4's loop:
  intro, demo 0, story, demo 1, high scores, demo 2, demo 3).

## 10. Screens, menus, sound

- **The status window**: as Keen 4's, with "KEYCARD" at print (80,91), a
  black box at (135,90) 10 × 10 and 8×8 tile 40 at (136,91) when Keen has
  the card; no wetsuit, no rescued members (Omni `ck_play.c`).
- **The control panel, Paddle War, the menus**: shared code; the menu
  card pictures are counted from the end of the picture range in Keen 4:
  check Keen 5's in E9 (93 pictures).
- **Sounds** (Omni `EPISODE.CK5`, CG names where Omni says UNKNOWN): 5 mine
  explodes, 6 Slicestar bump, 11 item, 12 enter level, 13 level done, 14
  need keycard, 16 Spindred up, 18 security door, 21 no ammo / switch, 27
  Spirogrip slams, 28 Spindred slams, 29 enemy shoots, 30 enemy shot hits,
  31/32 Ampton walks, 33 Ampton stunned, 36 Shelley explodes, 37 Spindred
  down, 38 Master shoots, 39 Master teleports, 40 pole zap, 41 teleport,
  42 bark, 45 bark shot dies, 46-50 Paddle War, 52 fuse breaks, 53/54
  galaxy explodes, 55 keycard, 56 elevating, 57 landing on a fuse, 58
  Sparky charges, 59 Sphereful bump, 60 gem door, 61 Spirogrip flies, 63
  elevator door. Keen's own sounds keep Keen 4's numbers where the
  actions match (E9 checks each name).
- **Music**: 14 songs, the table in §9; the OPL synthesiser and the cache
  are shared.

## 11. Things an implementer will trip over

1. **Info 26 is no scroll block** in Keen 5; only 25 (rows) is.
2. **Standing platforms 33-35 have their difficulty reversed.**
3. **Shelley has Sparky's class number**; a check for one hits both.
4. **`levelsDone` holds 1 or 14**; the secret end and the shaft read it.
5. **Fixed places and templates**: the elevator doors, the QED rubble,
   the fuse rubble come from the map's top-left corner and fixed tiles.
6. **Door targets 0x0000 and 0xB1B1 are special**; the lightning reads
   the head row's info.
7. **A fuse breaks only from a pogo landing with velY ≥ 48**; top 57 is a
   flat floor.
8. **`fusesRemaining`** is counted at every load; a loaded save wins.
9. **The keycard and the gems are lost after every level and death.**
10. **Objects sleep 6 tiles beyond the view** (Keen 4: 4); turret and
    enemy shots exist only on screen.
11. **Path arrows** drive GoPlats and Voltefaces; spawning writes an arrow;
    switches turn arrows round.
12. **Most creatures cannot be stunned**; Robo Red and the Master answer a
    shot; Shikadi and Shockshund flash white (a "draw white" sprite mode
    in `GalaxyObjectLayer`, additive).
13. **Original bugs** to keep (Keen 4's rule: as the original): the
    diagonal Slicestar never starts right-up; the Master's teleport wall
    check does nothing; the shot Master faces right; the Shockshund's
    bark overrides its jump; the pole-door glitch.
14. **Extra sprites per object**: the Sphereful's four diamonds and the
    mine's eye (drawn, no boxes).
15. **Game over is a scene** (the galaxy explodes), not a box.
16. **Map 14 is missing**; names and entry texts have 16 entries (0-15);
    the warp range 1-18 includes missing maps.
17. **Help has music** in Keen 5 only.
18. **Never hard-code chunk numbers** (v1.0 is unknown).
19. **No free Keen 5**: real-data tests need the user's files.

## 12. Only the original can answer

To be checked in js-dos with the user's v1.4 while building (Keen 4's
lesson: during each milestone, not only at the end):

1. Which level holds the 0x0000 door to Korath III, and which doors show
   the lightning (E5/E6; the maps answer the first part).
2. Whether map 12 has fuse tiles, or only the mine route (E5).
3. Force fields: deadly tiles that a switch turns off? (E5)
4. Do the purple platforms animate? (E5)
5. The Spirogrip's release distance (64 tics × 16 units = 4 tiles) (E4).
6. The game-over galaxy scene, frame by frame (E8).
7. The status window and the menu cards to the pixel (E7, E9).
8. Each creature's speed and frames, with Keen standing still or in god
   mode, as in D5 (E4).

## 13. Questions for the user

Asked as a menu (AskUserQuestion) at the end of E1; the answers go below.

1. **The game around the engine**: way 3 of architecture.md (new generic
   classes in `src/galaxy/game/` made from Keen 4's, Keen 4 frozen), way
   1 (copy Keen 4 to `src/keen5/`) or way 2 (refactor Keen 4)? *Advice:
   way 3.*
2. **Keen 4's decisions for Keen 5 too**: Omnispeak's numbers `(Omni)`,
   35 logic frames per second, scroll blocks covered in widescreen, the
   score box as HUD, our own OPL2 with AdLib on by default, up/down for
   two players, Paddle War, intro and demos, no Real-ESRGAN, the
   original's bugs kept. *Advice: yes, all.*
3. **Proof that Keen 4 stays the same**: the Keen 4 regression and its
   real-data suites need the Keen 4 files. Upload Keen 1-4 to each Keen 5
   cloud session, or run the proof on the Mac? *Advice: upload once per
   session (as in D), so every milestone proves it.*
4. **Exceptions**: `test_keen4_online.gd:26` changes (Keen 4 is no longer
   the last online game), and the additive changes in `src/galaxy/`
   (architecture.md, "The seams"). *Advice: approve.*
5. **Pictures behind the levels** in widescreen (our own, as Keen 4's
   ten): Keen 5 plays inside a space station. *Advice: yes, in E10.*
6. **Later**: move Keen 4 onto the shared Galaxy game (E13) once Keen 5 is
   done? *Advice: decide after E12.*

### The user's answers (22-10-2026)

1. **Way 3**: new generic classes in `src/galaxy/game/`, made from Keen
   4's; Keen 4 stays frozen.
2. **Yes, all of Keen 4's decisions hold for Keen 5**, with one demand
   added: **Keen 4 and Keen 5 must also play as the original. With every
   option off (4:3, no pictures behind the levels, no xBRZ, no smooth
   motion, PC speaker or AdLib as the player sets it) the game looks and
   plays exactly like the original.** The defaults stay as for Keen 1-4
   (widescreen and the pictures behind the levels on); an option that
   cannot be switched off is not allowed. E12 proves it for Keen 5 (the
   demos frame for frame, the screens to the pixel, all options off);
   Keen 4 already proved it in D13 (its five demos 100 % equal in 4:3).
3. **The user uploads Keen 2, 3 and 4** to every Keen 5 cloud session
   (Keen 1 comes from `tools/get_shareware.sh`), so every milestone runs
   the full proof.
4. **Both exceptions approved**: the one line in
   `tests/test_keen4_online.gd:26` (E11), and additive changes in
   `src/galaxy/` that keep Keen 4's behaviour by their defaults.
5. Pictures behind the levels: yes (part of answer 2), in E10.
6. Not asked yet: moving Keen 4 onto the Galaxy game (E13) is decided
   after E12.
