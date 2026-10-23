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

E2 measured in the files (v1.4): the story is one record of 37 lines;
the level names are 16 (maps 0-15, slot 14 included); the high-score
table lies at 0x33D56; the status window's labels are twelve (with
KEYCARD and VITALIN, without RESCUED and the wetsuit); the program has no
"Game Over!" text. The offsets and shapes are in
[file-formats.md](file-formats.md), "Texts in KEEN5E.EXE".

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
- Target **0x0000** gives `LS_TeleportToKorath` (§8). Level 11 holds it:
  the glass teleporter at (7, 33)-(8, 33) (files, E5; seen in js-dos:
  Keen arrives on Korath III). A Keen knocked off a pole
  into a door can read a wrong target too (a real bug of the original,
  Omni `ck_poleDoorGlitch`, kept by default).
- When Keen starts into a door whose info at his **head** row is 0, a
  **teleport lightning** appears (sound 41): a horizontal bolt at (tile x
  of Keen·256 − 0x80, Keen's bottom row·256 − 0x500) and a vertical one at
  (Keen's tile x·256, Keen's top row·256 − 0x80); TELEPORTSPARK1/2 and
  TELEPORTZAP1/2, 6 tics each. A door's target lies in its own tiles'
  row, Keen's head row at the door (files, E5), so only the 0x0000 door
  of level 11 shows it (seen in js-dos, E5).

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
  Omnispeak would also let four broken fuses end map 12; CG only the mine.
  Map 12 has **no fuse tile** (files, E5), so only the mine's piece ends
  it (seen in js-dos, E5).

### Switches, bridges, platforms on paths

- Switches (misc 5/6) as in Keen 4: they toggle the **B-block** (info 31)
  at their target, or, when the target holds a **path arrow** (info
  91-98), turn the arrow round with the table {2,3,0,1,6,7,4,5} (Keen 5
  only, Omni `CK_KeenPressSwitchThink`).
- Bridge switches (misc 15) and bridges (misc 18, 59 tiles with
  animation offset ±4: the energy bridges) as in Keen 4.
- Deadly tiles: misc 3 (19 tiles, some animated: the force fields) and
  top value 9 (deadly floor, 12 tiles). **No switch turns a force field
  off** (files, E5): every platform switch of levels 1-13 points at a
  B-block or a path arrow, every bridge switch at an energy bridge.
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
| **Shikadi** (20) | Walks; near Keen's height or with Keen on a pole it follows him and zaps the pole in front (2 × 20 tics; a spark runs along the pole at 48 units a frame, not a tic (E4), towards Keen, sound 40) | Touch, spark | **4 hit points**: three shots flash it white (2 frames), the fourth stuns it for good |
| **Shockshund** (21) | Runs (+128 a step); every 32 tics faces Keen; chance 0x10/256 sits 256 tics; jumps (vx ±40, vy −40) when Keen is at another height; chance 0x80/256 barks a shot instead (vx ±60) | Touch, shot | **2 hit points**: flash, then stunned for good |
| **Sphereful** (22) | Box-clipped (2 × 2 tiles); every 16 tics drifts ±1 towards Keen (at most 8); bounces off walls and ceiling (sound 59) and floors (sound 16); four diamonds circle it (drawn only, a 16-step table in Omni `CK5_SpherefulDraw`) | Touch | Absorbed; invincible |
| **Korath** (23) | Walks; chance 10/256 a step to wait 30 tics facing a random way | Harmless: pushes Keen, knocks him off poles | Stunned for good |
| **Laser turret** (15) | Waits 120 tics, fires at 64 units/tic (LASER1-4, 8 tics; on a wall sound 30, LASERHIT 2 × 10 tics); shots exist only on screen | Shot | — |

Platforms (Omni `ck_obj.c`, `ck5_misc.c`):

- **Red axis platform** (27-30) as Keen 4's (12 units/tic, turns at a
  B-block). **Purple** (84-87): the same, placed +0x40, checks one tile
  further right when moving vertically (its stop rule not), two sprites
  but its actions' timer is 0, so it **never animates** (E5, seen in
  js-dos).
- **GoPlat** (36-39 red, 80-83 purple): always awake, unclipped,
  12 units/tic; at each tile it reads the arrow at its position (the
  purple one, placed +0x40, at its position + 0x40: the same tile) and
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
  (Omni `CK5_ScanInfoLayer`). **Checked in the map (E6)**: the doors stand
  there (the bottom one open in the file, the other three closed; the
  template's pictures 0 and 5 at (0,0) and (10,0); picture 5's lower row
  is the elevator, tiles 1864/1865 = misc 33/34), and the elevators' info
  words point at them: (24,77) 0x1638 → (22,57), (22,56) 0x184D → (24,78),
  (26,56) 0x181F → (24,32), (24,31) 0x1A38 → (26,57). The one teleporter
  is on Korath III at (44,106), word 0x141E → (20,30) at the top.
- **Korath III**: after `LS_TeleportToKorath` the map loads without the
  info-3 Keen, Keen stands on info 26 facing west, the box says "Keen
  steps out onto Korath III".

- **The status window on Korath III** (seen in E6): on the world map
  with Keen on Korath III the LOCATION reads "Korath III Base" (level 13's
  name), at the top "Omegamatic"; Omnispeak always prints the map's name.
- **The yellow filler** (files, E6): back tile 850 is all EGA yellow; map
  0 is filled with it around the station's star field (1,735 cells, rows
  2-96), where the original's view never comes. Korath III's ground (rows
  beyond 100) has three of them too, and level 13 uses it as its sky.

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
  check Keen 5's in E9 (93 pictures). **Answered in E9**: one less than
  Keen 4's (MAIN MENU 32 … the wrist watch 17), "Watched in E9".
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
   the lightning (E5/E6; the maps answer the first part). **Answered in
   E5**: level 11, its teleporter at (7, 33)-(8, 33); only that door
   shows the lightning (a door's target is in Keen's head row).
2. Whether map 12 has fuse tiles, or only the mine route (E5). **Answered
   in E5**: no fuse tile; only a mine's piece ends it.
3. Force fields: deadly tiles that a switch turns off? (E5) **Answered in
   E5**: no; no switch points at one.
4. Do the purple platforms animate? (E5) **Answered in E5**: no, only
   PURPLEPLAT1 is ever shown.
5. The Spirogrip's release distance (64 tics × 16 units = 4 tiles) (E4).
6. The game-over galaxy scene, frame by frame (E8). **Answered in E7**:
   every recorded frame equals ours ("Watched in E7").
7. The status window and the menu cards to the pixel (E7, E9). **The
   status window answered in E6**: equal to the pixel once its KEYCARD row
   is a pixel lower than Omnispeak's numbers. **The menu cards answered in
   E9**: equal to the pixel ("Watched in E9").
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

## Checked in E3

What the E3 milestone measured (details in [gameplay.md](gameplay.md),
"Watched in E3", and [file-formats.md](file-formats.md), "Checked in E3"):

- In js-dos (v1.4): level 1's first view after the warp equals ours to the
  pixel (view, tiles, Keen, score box); level 11 and the world map show the
  same view and tiles (only creatures, the score box on the map and
  animated tiles differ). The debug keys are A+2 held with Enter, the warp
  F10+W, as in Keen 4.
- In the files: every security door is the exit (0xB1B1) of its level;
  only level 1 exits by a plain door; the fuse levels have no exit door.
  Keen 5's Keen sprites differ from Keen 4's numbers from looking down on.
- Still open for the original: the security door seen opening (not
  reached quickly by script; the rules are Omnispeak's), the teleport
  lightning (§12 question 1).

## Watched in E4

The original v1.4 in headless js-dos (Normal, god mode F10+G, warp
F10+W), with a scratch copy of `GAMEMAPS.CK5` in the scratchpad: one
creature (its Normal value) put near Keen's start, other creatures there
removed (level 3: Sparky at 192,10; level 4: Shelley at 62,34; level 5:
Ampton at 8,12; level 7: Sphereful at 6,5; level 12: Robo Red at 37,75;
level 13: Shikadi at 12,26). The new info planes were appended to the
file as plain Carmack words over RLEW, each map header pointing at its
new plane (our reader and the original both take it). Frames recorded
with Keen standing still; headless js-dos delivers a frame every 4-8 tics,
so times are ±4 tics. Measured by tracking a creature's colours:

- **Sparky**: 8 px every 4 tics while charging (32 units a tic), 8 px
  every 8 tics walking (16 a tic); between seeing Keen and charging it
  stood ~100 tics (search 48 + three rounds of 16 + the turn).
- **Little Ampton**: 8 px every 8 tics, its face picture ~8 tics at each
  turn, a round trip of its 8-tile floor in 258 tics (ours 256); its turn
  96 px from Keen in ours, ~93 px in the original (sprite edges).
- **Robo Red**: 4 px every 6 tics (64 units a 6-tic step), turning in its
  room, volleys towards Keen; the shots' hit pictures where Keen stands.
- **Shikadi**: four standing pictures, then 8 px every 8 tics, and back and
  forth round Keen about two tiles each way, 128 tics a round (ours the
  same).
- **Shelley**: walks and turns; exploded when Keen's middle came inside
  it, with its blast and pieces.
- **Sphereful**: bounced round Keen's head with its four diamonds, two of
  them hidden behind it at a time.
- Sprite names were checked by eye on a sheet of all creature sprites:
  every left/right pair (Robo Red, the Shikadi's grab, the Master's cast,
  the Shockshund, Sparky, Ampton, Shelley, Spirogrip) shows the side its
  name says (unlike Keen 2's guard robot).

Not watched (time): Volteface, Slicestars, the mine, Spirogrip, Spindred,
the Master's teleport, the Shockshund, the turrets' lasers; their rules
are Omnispeak's and tested in mini levels (`test_keen5_creatures*`).

## Watched in E5

The original v1.4 in headless js-dos (Normal, god mode F10+G, warp
F10+W), with a scratch copy of `GAMEMAPS.CK5` (the E4 way: new info
planes appended): Keen's start moved in level 1 to (31, 9) (the GoPlats'
octagon in view), level 8 to (11, 60) (standing on the fuse), level 10 to
(7, 11) (over the purple platform), level 11 to (8, 34) (at the
teleporter), level 12 to (16, 12) with a mine (info 7) put at (17, 13)
beside the QED. Recorded frames were compared with ours run on the same
scratch files (`--data-dir-keen5=`, a session per level, the sprites
found in the frames by their exact pixels):

- **GoPlats** (level 1): the red platform found in all 280 frames of 8 s;
  every place equals ours at one frame offset (±1 frame).
- **Purple axis platform** (level 10): 204 frames with it whole, all at
  ours' places; PURPLEPLAT2 never shown (question 4). Keen missed it
  (it had moved on) and stood in the force field below in god mode.
- **A fuse** (level 8): a pogo from on top of the fuse broke it about
  856 ms later (ours 31 frames, 886 ms; js-dos shows a frame every
  ~28 ms); the explosion one tile left, Keen bounced off the floor beside
  the hole and went on pogoing; 60 tics later the game stood still, and
  the fuse message came ~2.3 s after that (the level-exit sound playing
  out, Omni SD_WaitSoundDone). Both message screens equal ours to the
  pixel (17,312 pixels of window each).
- **The door to Korath III** (level 11): the two bolts at (72, 45) and
  (80, 105) on the screen, flickering, as ours; then the world map with
  Keen on Korath III (E6). In a first try Keen's start was on the door's
  feet row, so the door read that info value (1) as its target and sent
  him to (0, 1): the original reads the target in Keen's own row when a
  ceiling keeps the door's steps from lifting him (ours the same).
- **The QED** (map 12): the mine burst at Keen, its pieces hit the QED:
  four explosions, the machine broken (Keen fell through), about 60 tics
  later the end pages ("Congratulations ..."). With the mine at its own
  place (17, 8) it wandered above and never came down (ours the same).

## Watched in E6

The original v1.4 in headless js-dos (Normal), with a scratch copy of
`GAMEMAPS.CK5` (the E4 way: map 0's info plane appended): the map Keen's
info 3 moved from (28,95) to (44,108) on Korath III, next to the
teleporter. Recorded frames were compared with ours run on the same
scratch files (`--data-dir-keen5=`, 4:3, the World viewport saved):

- **A new game** starts with the box "Keen steps out onto Korath III"
  (Keen's box below row 100 when the map loads): the box and its five
  count-down screens are equal to ours **to the pixel** (17,312 pixels
  each; the count-down picture is the seventh from the end, GAMEOVER comes
  last), each ~300 ms. The map's first view equals ours but for one
  animated tile (26 pixels of 64,000).
- **The status window** (Enter on the map): on Korath III it says
  "Korath III Base", at the top "Omegamatic". Both windows equal ours to
  the pixel (29,184 pixels) after the KEYCARD row was moved a pixel down:
  the original prints the label from (80,92) and draws the square at
  (135,91), not Omnispeak's (80,91) and (135,90).
- **The teleporter** (Up into (44,106)): Keen walks onto it with the
  bolt flashing, ~1.1 s later he stands at (20,30) at the top with the
  view on him and walks out south; every frame from the jump on equals
  ours (0 pixels different, matched by content: the original shows a
  frame every 28-57 ms); while walking in, 32-42 pixels differ (his
  walking picture and the bolt by the clock).
- **An elevator** (the top one, (24,31), down to (26,57)): walking in and
  the door closing equal ours to the pixel; the view then follows the
  unseen Keen down the shaft and the door at (26,55) opens with Keen
  walking out. After the flight the original's view stands 8 pixels lower
  and 2 to the right of ours, with everything in it the same: its last
  flight step overshoots the target by a few tics' worth (js-dos runs 2-4
  tics a frame; ours always 2, which lands exactly), and the view follows
  that last box once more (Omni CK_MapCamera in CK5_MapKeenElevator; ours
  does the same).
- Walking on the map (Keen 4's map Keen) was seen on the way and not
  measured again.


## Watched in E7

The original v1.4 in headless js-dos (no CONFIG.CK5, so the default
high-score table). A whole round of the title loop was recorded every
400 ms (order and timing), then each demo at every changed frame in runs
of their own; the end, the help and the name entry with a CONFIG.CK5
whose last score is −1 (so a score of 0 makes the table); game over with a
scratch copy of `GAMEMAPS.CK5` where level 10's Keen starts over the force
field (warp F10+W 10, then Try Again until no life is left). Our frames
were made in the real view (4:3, xvfb), one per logic frame, and laid on
the recorded ones: the first exact match sets the alignment, then each
recorded frame is compared with our frames from the last match on.

**The title loop** (seen): intro (about 38 s), the DEMO box, demo 0,
story (about 70 s), demo 1, the high scores, demo 2, demo 3; a round is
about 345 s. The intro's words are red, light red where they overlap
(Omni ck_terminatorPalette1: 4, 0x1C), the zoom red, the fizzle white;
the story picture by ck_starWarsPalette, the text light cyan. Every
recorded scroll frame of the intro equals ours (65 of 65, ours stepped 2
tics a frame as the game runs it; with 1-tic steps the credits run 2-4
tics ahead), the story 147 of 156 (the others caught half drawn), the
fizzle frames differ only by its random order.

**The demos** (before E7 Keen died in demo 2 at frame 193 and in demo 3
at 1064):

| Demo | Map | Frames | Recorded frames equal to ours | Others |
|---|---|---|---|---|
| 0 | 1 | 842 | 819 | 1 (the fade after the end) |
| 1 | 3 | 1024 | 990 | 1 (the fade) |
| 2 | 10 | 1381 | 1343 (100 %) | — |
| 3 | 11 | 1267 | 1247 | 27 caught while the original drew (tiles of the next frame already drawn), 1 fade |
| 4 (high scores) | 15 | 703 | 677 | 66 caught half drawn (a sprite cut by a line; the table's screen redraws in place) |

Every frame of ours that the recorder caught is equal; all five play to
their end. The causes found (each fixed; the sync suite fails without
any one of 1-4):

1. **Landing on a platform takes the shared step's x** (demo 2 frame 107:
   the original's Keen lands 8 pixels further left). Omni CK_PhysPushY sets
   only ck_nextY; ck_nextX still holds the last object's step (here an
   Ampton's −128).
2. **Axis platforms stop on the tile's edge when they turn** (demo 2: a
   platform 2-4 pixels behind ours from frame 718 on, after many turns),
   as Omni CK_AxisPlatform; Keen 4 v1.0 was seen to bounce back (D13).
3. **A spent mine piece is drawn once more** at its new place and is gone
   the next frame (demo 4 frame 71).
4. **Pushed sideways by an Ampton, Keen also moves by the shared step's
   y** (Omni CK_PhysPushX sets ck_nextY only when the action sticks to the
   ground): his pogo touched the floor a frame earlier (demo 4 frame 246).
5. **The order of sprites of one priority**: the original draws nothing
   before a map's first frame, so the first frame's order rules (demo 4
   frame 87: the Slicestar over the Volteface); an object that sleeps
   loses its place.

**Game over** (`CK5_ExplodeGalaxy`), every recorded frame equal to ours:
the fade-out and fade-in by the EGA fade palettes (level 1: 0-8 black,
9-15 their dark twins; level 2: 0-7 black), 6 tics a step; then 18 flash
steps of 10 tics (143 ms): **entry 7 follows the second row of
endsplosion_pal_change and entry 8 the first** (Omnispeak gives both the
first row; the observed sequence of (7, 8) grey/black, grey/grey,
grey/black, black/black, black/grey, grey/grey, grey/black, black/black
fits only this); value 0x0F shows light grey, 0x08 black; then 60 star
frames of 4 tics (57 ms each), the last 13 nearly empty; a star exactly at
x 320 appears at the left of the next row. In js-dos the screen stayed
black 1.5 s between the fade-out and the fade-in (loading; not copied).
GAMEOVER at (32, 80) equal; after 24 s the name entry.

**The end**: E+N+D on the map, then about 2.5 s black (loading), then 9
pages, each equal to ours to the pixel, the arrow dim and bright every
1000 ms (70 tics); the help (menu, second topic, pages 1 and 2) and the
name entry with its cursor at the left margin − 1 equal too.

## Watched in E8

Headless js-dos as in D9 (docs/keen4/research.md, "Watched in D9"): the
bundle's `dosbox.conf` with `[mixer] rate=44100` and `[sblaster]
oplmode=opl2`, a scratch copy of CONFIG.CK5 with AdLib sound and music
(bytes 518 and 520) and "had an AdLib" (540) set; the page gave js-dos's
AudioWorkletNode a MessageChannel of its own and kept a copy of every
sample on its way (44.1 kHz, mono). A scratch `GAMEMAPS.CK5` put a
keycard (info 70) one tile left of Keen's start in level 1 and Keen's
start of level 8 on its fuse (as E5). Ours: the songs and sounds rendered
by our OPL2 (`GalaxyMusic.render`, `GalaxyAdlibSound.render_samples`),
laid on the recording by 0.1 s log spectra (0-3 kHz) with a time factor
searched from 0.85 to 1.25, and the strongest partials.

| What | The original (v1.4, DOSBox's OPL) | Ours (E8) |
|---|---|---|
| Level 1's song (5) at demo 0's start (48.1 s into the title loop; the intro is silent) | partials 62, 98, 392, 490, 986, 1002 Hz in the first 0.5 s; the spectra follow ours at a time factor of **1.120** (D9's 11.8 % js-dos drift), 15 s correlate 0.54 overall (0.75 the first second; Keen's sounds on top) | 62, 96, 392, 970, 988, 1006 Hz |
| The world map's song (11) after the fuse message | 40, 82, 124, 164, 206, 588 Hz, factor 1.125 | **the same six partials** |
| The keycard (55) | 7 pulses about 0.1 s apart over the song; partials 274, 333, 552, 601, 666, 999 Hz | 7 pulses 0.09 s apart; 277, 332, 550, 655, 1002 Hz |
| A fuse breaking (52) | its high tone: peaks 3968, 4090, 4157, 4642, 4844, 5573 Hz; the share above 2 kHz follows ours with correlation **0.94** at factor 1.12 | 3989, 4105, 4178, 4644, 4853, 5589 Hz |
| The level's exit (13) after the fuse | the music stops when the game stands still; the exit sound alone, envelope correlation **0.90** with ours at factor 1.12 (1.68 s = 1.48 × 1.12); partials 85, 156, 172, 343, 477, 504, 519 Hz; the fuse message comes when it has played out, the audio silent from there | 88, 155, 170, 351, 478, 503, 519 Hz; the message after 104 tics (1.48 s) |
| Between the maps | the map's song stops at the warp, the loading box is silent (3 s), level 1's song starts with the level; after the fuse message the screens and the map's box are silent and the map's song starts with the map | the same (the music stops whenever a map's play ends) |
| Loudness | 0.4-0.9 of ours (RMS: the map's song 0.44, level 1's with Keen's sounds 0.92, the keycard about 0.4; D9 found a third) | as Keen 4's, against the PC speaker |

So the songs, the sounds' pitch and rhythm, the silence between the maps
and the wait before the fuse message are confirmed. E5's "about 2.3 s"
before the message was js-dos's wall clock; in the recording's own audio
time it is the exit sound's 1.48 s stretched by the drift. The fuse
breaking 1.0 s (audio) before the level ends is 60 tics stretched by the
same factor (`Keen5LevelEnd`). Not recorded: the story's song (the run
stopped 25 s into demo 0), the help's, the end's and game over's (their
places are Omnispeak's: `ck_text.c` StartMusic(19) and
CK_EndingMusicLevel 14, `ck5_misc.c` StartMusic(18), `ck_inter.c`
CK_StarWarsMusicLevel 17).

The sound table: every number from Omnispeak's EPISODE.CK5; where it says
UNKNOWN, Commander Genius's names fit what the code plays there (12 the
map's level entry, 41 the teleporters and the Korath lightning, 52 the
fuse, 63 the elevator door; 43/44 the thrown flag and 56 the elevator's
ride are never played by Keen 5). The Paddle War sounds are Omni's 46-50
(all priority 50, CG lists them one off). The digitised slots 128-191 are
empty; no song uses the rhythm mode (register 0xBD is only written 0).

## Watched in E9

The control panel of the user's v1.4 in js-dos (headless, the snapshots
are 320 × 200 frames; a key on the title opens the main card, Escape in a
game), compared with ours drawn by `GalaxyMenuView` by mapping both to
the 16 EGA colours (D10's lesson):

| Card | Pixels that differ |
|---|---|
| Main card, title loop (cursor icon lit) | 0 |
| Main card in a game (RETURN TO GAME, cursor icon dark) | 0 |
| New Game (BEGIN NORMAL GAME under the cursor) | 0 |
| Load (six empty slots) | 0 |
| Save, "AB" typed into slot 1 / saved | 0 / 0 |
| Sound (ADLIB/SOUNDBLASTER checked) | 0 |
| Paddle War's start (KEEN:0, the title, COMP: 0, both paddles) | 0 |
| Configure | 1,559: the original has USE KEYBOARD, the joysticks, the Gravis pad and CONTROL: KEYBOARD; ours KEYBOARD and RESET KEYS (Keen 4's choice, D10) |
| REALLY QUIT? | 1,779: ours has the line PRESS C TO CHOOSE GAME, so a larger box (the user's decision, 20-10-2026) |

- The pictures (Omni `GFXCHUNK.CK5`, chunk − 6) are Keen 4's minus one
  counted from the end: Keen 5's range ends with GAMEOVER after the
  count-down. Checked by eye: 61 MAIN MENU … 74 QUIT, 75 the joystick, 76
  the wrist watch (Keen 5's own: grey, two red buttons; Keen 4's is
  another picture). Masked picture 0 is the watch's dotted screen, sprites
  0-2 the paddle and the ball, font 1 the watch's font, as Keen 4's.
- Six save slots (Omni US_MAX_NUM_OF_SAVED_GAMES; seen), the name typed
  in the box, "Type name" / "Enter accepts" in the footer, the save card
  staying with the name.
- Loading: black, then the game with the box PAUSED (seen on the world
  map, Keen under the box).
- End Game in a game asks REALLY END CURRENT GAME? (also right after a
  load: the question comes whenever the panel was opened in a game and
  nothing was saved since), then the high scores on map 15, the title loop.
- The cursor's icon blinks (lit and dark both seen), Return to Demo and
  Return to Game as Keen 4's.

