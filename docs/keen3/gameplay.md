# Keen 3: the rules of a level in our engine

What playing Keen 3 does in CommanderPerfect so far, and which numbers are
estimates. Written in milestone C3; later milestones add to it. The facts
and their sources are in [research.md](research.md), the code layout in
[architecture.md](architecture.md). Numbers from Chocolate Keen are marked
(Choco) and converted with the table at the top of research.md ("Units").

## The course of the game (C3, provisional)

Until the world map (C6) and the menus (C8) come, the course is the one
Keen 2 had in B3.

| What | Then |
|---|---|
| Keen 3 picked on the start screen | Level 1 |
| `-- --game=3` | Level 1 |
| `-- --game=3 --level=N` | Level N (1-16); another number: level 1, with a message |
| Keen walks out through an exit | The next level; the keycards are taken away. After level 16 (which has no exit; only reachable with the cheat) "That was the last level" and the start screen |
| Keen dies | One life less, the same level again from its file, with "Keens Left" over it |
| Keen dies without lives left | GAME OVER (the bitmap, bare over the level) for 5.27 s or until a key, then the start screen |
| Escape | Back to the start screen |

"Keens Left" is a window of 16x4 cells with a little Keen (sprite 35,
MAPKEEND1) per life, at most 7; the game waits while it is open; it closes
by itself after 0.87 s (seen in js-dos in C1) or with a button. Cheats for
testing, as in Keen 1 and 2: Shift+N / Shift+P (next / previous level,
wrapping around), Shift+I (all keycards, 99 charges), Shift+G (god mode).

Code: `Keen3View` (the scene) on `Keen3SceneScreen` (setup, loading, the
windows, leaving) on `GameScreen`; `Keen3LevelPlay` (the course),
`Keen3LevelSession` (one attempt at a level), `Keen3Body` (Keen and the
ankh).

## Start values

| Value | Keen 3 | Status |
|---|---|---|
| Lives | 4 | certain (Choco; seen in js-dos) |
| Raygun charges | 5 (`Keen3Inventory.START_CHARGES`) | certain (Choco; seen in js-dos) |
| Pogo stick | from the start; Keen 3 has no pogo item | certain |
| Score | 0; an extra life every 20,000 (EXTRAMANSND) | certain |
| Ankh time | 0 at the start of every level | certain (Choco) |

Keen starts at the cell with info 255, 8 pixels down (Choco); he drops
onto the floor below as in Keen 1 and 2. **Level 9 has two starts**, (2,10)
and (63,17): the original scans row by row and keeps the last one, so Keen
starts at (63,17) (`Keen3LevelPlay.start_cell`; `LevelData.find_info`
would give the first).

## Keen

Keen moves with the shared `KeenBody` physics, unchanged (the user decided
that the jumps, a little too high in all three games, stay as they are for
now). Sprites 0-27 have the same numbers as in Keen 1 and 2; dying shows
22 and 23 (KEENISDEAD1/2, checked). The stun of a youth (C4) uses Keen 2's
timing for now, with Keen 3's frames 28, 29 and 30 (KEENMELT).

## What Keen touches

Everything goes by the tile's behaviour in the tile table of `KEEN3.EXE`.

| Behaviour | Keen 3 in our engine |
|---|---|
| 1 | Deadly (unless the ankh protects him) |
| 2-5 | Doors yellow, red, green, blue: open with the keycard of their color (used up). The door's cells get **the tile left of the door's top cell** (Choco); the door sinks as in Keen 1 (1 px per tick; the original: 1 px per 5 clock ticks, 2 of ours) |
| 6-10 | Points from the table: candy bar 500, burger 100, Vorta-Cola 200, cake 1000, stuffed ninja 5000 (the help text swaps the first two) |
| 15 | Raygun: +5 charges, GOTITEMSND |
| 17 | Exit: any exit tile ends the level, so the two exits of levels 12, 13 and 15 both work. Not while riding (C5) |
| 18-21 | Keycards; taken away at the end of every level |
| 22 | Turns into tile 143, nothing else (Choco); used in no level |
| 27 | **The ankh** (below) |
| 28 | Single charge: +1 charge, GOTITEMSND |

A picked up item leaves **the first tile of its row** in the tile table,
`(tile / 13) * 13` (Choco): each row (143, 156, 169, 182, 195, 208) has its
own background. Keen 1's ship parts, teleporters and statues and Keen 2's
switches and Elders do nothing.

The info layer spawns nothing yet: enemies come in C4, the ball, jack,
platforms and wall guns in C5. Keen's shots use KEENSHOT (102) and splash
with SHOTSPLASHR (105) when flying right, SHOTSPLASHL (106) when flying
left (*estimate*); what they hit comes in C4.

## The ankh

| What | Value | Source |
|---|---|---|
| Protection per ankh | 577 ticks (1400 clock ticks, 9.6 s); another ankh adds its time | Choco |
| Sound | ANKH (sound entry 41), played by `Keen3Sounds` on its own speaker | Choco |
| At the start of every level | 0 (every attempt makes a new `Keen3Body`) | Choco |
| Counts down | only while the game runs (one per tick in `Keen3Body.step`; not behind "Keens Left") | Choco |
| Protects against | everything that kills through `KeenBody.kill` (deadly tiles now; enemies and shots in C4) and the stun (`Keen3Body.is_protected`) | Choco |
| Does not protect against | falling out of the level | Choco |
| Halo | sprites 61 (GODHALO) and 62 (BYEHALO) in turn every 6.6 ticks, at Keen −8, −8 px (`Keen3AnkhShield`, drawn by the ActorLayer behind Keen; its middle is transparent) | Choco |
| Blink | in the last 103 ticks; every other picture is left out (*estimate* of the look) | Choco (when), estimate (how) |
| Shown time | whole "seconds" of 144 clock ticks (59.3 of ours): a fresh ankh shows 9, as the status screen | Choco |

The ankh time is Keen's own (`Keen3Body.ankh_ticks`), not part of the
inventory: it never leaves a level. The status screen (C6) reads it from
there.

## The HUD (widescreen)

`Keen3Hud` (a subclass of the shared `Hud`): the lives with Keen 3's map
Keen (sprite 35) and the score on the left; the raygun with its charges and
the keycards on the right; while the ankh runs, a third panel under the
right one with the ankh (the first tile with behaviour 27, tile 149) and
its time in whole seconds. The raygun, keycard and ankh pictures are the
first tiles with that behaviour (`Keen2Icons`): 151, 152-155, 149. They
keep the cyan background of their row (the shared HUD only leaves out Keen
1's gray).

## The border

Every Keen 3 level has a border of 2 cells of tile 245, an "OH no!"
picture that must never be seen. Checked in C3: the shared `LevelMap`
only draws the playable area, and the camera's limits (`LevelCamera`) never
go past it; where a level is narrower than the view (level 16 in
widescreen, 21 cells wide) black bars show, not the border. xBRZ and HD
scale the same tiles, so they show no more. `tests/test_keen3_play.gd`
checks for every level 1-16 that no border cell is drawn and that the
camera keeps to the playable area for views of 320, 426 and 480 pixels.
Nothing had to change for Keen 3. Still to check in later milestones: the
map (C6), map 81 (C7), map 90 (C8) and two players (C10).

## Not yet

Enemies (C4), ball, jack, platforms and wall guns (C5), the world map and
the status screen (C6), level 16's machine (C7), title, menus, saving and
high scores (C8), the pictures behind levels (C9; never Keen 1's or 2's),
two players (C10).

## Seen in the original (C3)

Not compared in js-dos in C3 (the comparison is optional and was skipped).
One thing to check: level 1's first view. In C1 the original showed cell
(2,12) in the top-left corner of the 4:3 view; ours shows (2, 11.5),
because our camera centres Keen and stops at the bottom of the playable
area (row 23 ends at pixel 384, the view is 200 high). Either the original
shows 8 pixels of the bottom border row (unlikely), or its view is less
than 200 pixels high, or its first view is placed differently. To check in
C11.

## Estimates to check against the original

- The halo's blink (which pictures are left out) and whether it is drawn
  in front of Keen or behind him.
- The splash sprites per direction (105 right, 106 left).
- The door sinking speed (shared: 1 px per tick; Choco: 1 px per 5 clock
  ticks).
- "Keens Left": the window's place (the original: x 88-231, y 72-119) and
  how many little Keens fit.
- The ankh time itself: 9.6 s (Choco) against 15 s (KeenWiki) and 21 s (CG)
  (research.md, "Only the original can answer", 1).

## Testing

- `tests/test_keen3_level.gd` and `tests/test_keen3_keen.gd`: hand-made
  levels (`tests/keen3_fixtures.gd`, with a border of tile 245): points per
  behaviour, the candy bar and the burger, what an item leaves, raygun,
  single charge, keycards, doors (the left tile, sinking, shut without the
  card), the exit, two exits, deadly tiles, behaviour 22, no enemies,
  shots, keycards gone after a level, the start values, the pogo stick
  from the first tick, level 9's later start, dying and stun frames, and
  the ankh (protects from a deadly tile, not from falling out, adds up,
  reset per level, counts down only while playing, no stun, the shown
  seconds, the halo's frames and blink).
- `tests/test_keen3_play.gd` with the player's files (skipped without
  them): every level starts with Keen inside it and no enemies, level 1
  plays (and the plant right of the start kills, as in js-dos), level 9
  starts at (63,17), exits per level, the item rows of the real table,
  the ankhs of levels 3, 10 and 14, the border is never drawn, the course
  (next level, death, game over, after level 16), the HUD icons.
- The screen: `tools/scripted_play.gd` with
  `SCENE=res://src/keen3/keen3_view.tscn -- --game=3 --level=N`. With
  `--fixed-fps 60` the frames run much faster than real time, so a
  screenshot can show a frame from some ticks earlier (it depends on the
  machine and on full screen); take them a little later than the event.
