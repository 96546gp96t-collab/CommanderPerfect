# Keen 2: the rules of a level in our engine

What playing a Keen 2 level does in CommanderPerfect so far, and which
numbers are estimates. Written in milestone B3; later milestones add to it.
The facts and their sources are in [research.md](research.md), the code
layout in [architecture.md](architecture.md).

## The course of the game (temporary, B3)

There is no title, menu or world map yet (B6, B7). Until then:

| What | Then |
|---|---|
| Keen 2 picked on the start screen | Level 1 |
| `-- --game=2 --level=N` | Level N (1-16); another number starts level 1 with a message |
| Keen walks out through the exit | The next level; after level 16 the start screen |
| Keen dies | One life less and the same level again, fresh from its file; "Keens left: N" |
| Keen dies without lives left | "Game over", then the start screen |
| Escape | The start screen |

Levels 80, 81 and 90 (world map, space, title) are not played yet. Cheats
for testing, as in Keen 1: Shift+N / Shift+P (next / previous level),
Shift+I (all keycards, 99 charges), Shift+G (god mode). Enter (status
screen) does nothing yet; Keen 2's status screen comes with the cities in
B6.

Code: `Keen2View` (the scene) and `Keen2LevelPlay` (the course of the
levels), `Keen2LevelSession` (one attempt at a level).

## Start values

| Value | Keen 2 | Status |
|---|---|---|
| Lives | 4 | certain (same as Keen 1) |
| Extra life | every 20,000 points | certain (same as Keen 1) |
| Pogo stick | from the start; Keen 2 has no pogo item | certain |
| Raygun charges | **0** (`Keen2Inventory.START_CHARGES`) | **estimate**: Commander Genius reads them from a code byte of `KEEN2.EXE`, which we do not read. Check in the original. |
| Ship parts | none (Keen 2 has cities instead, B6) | certain |

## What Keen touches

Everything goes by the tile's behaviour in the tile properties of
`KEEN2.EXE`, never by tile number.

| Behaviour | Keen 2 in our engine |
|---|---|
| 1 | Deadly |
| 2-5 | Doors yellow, red, green, blue: open with the keycard of their color (used up), sink into the floor, leave tile 143 |
| 6-10 | Points 500, 100, 200, 1000, 5000 |
| 11-14 | Keen 1's ship parts: **not items** in Keen 2 (nothing happens) |
| 15 | Raygun: +5 charges |
| 16 | Pogo stick: as in Keen 1 (Keen has it anyway; no Keen 2 level is known to have one) |
| 17 | Exit |
| 18-21 | Keycards yellow, red, green, blue; they only count in the current level |
| 22 | Vorticon Elder's message: **nothing yet** (B5/B6), and not Keen 1's statue |
| 23, 25, 26 | Switches: nothing yet (B5) |
| 24 | Keen 1's teleporter: nothing in Keen 2 |

A picked-up item leaves tile 276 when its tile number is 305 or more,
otherwise tile 143, as in Keen 1. Whether 276 is right for every Keen 2 item
is uncertain (research.md §3).

## Enemies and the info layer

None yet (B4). The info layer only gives Keen's start (255). Values 1-7 will
be the enemies; values from 0x100 on are never enemies: at a switch they
point to the bridge it moves (B5).

## Shots

Keen's raygun shot flies and splashes exactly as in Keen 1; it uses Keen
2's sprites: 122 (Keen's shot), 123 (enemy shot), 124/125 (splash).

## The HUD (widescreen)

Lives, score, raygun charges and keycards; no ship parts. The raygun and
keycard icons are the first tile with that behaviour in the tile
properties (`Keen2Icons`), because Keen 2's status screen tile numbers
(414, 424-427 in Commander Genius) are not certain.

## Not yet

Enemies and riding (B4); switches, bridges, darkness, the Tantalus Ray (B5);
the world map, cities, status screen, the Elder's messages and the ending
(B6); menus, saving and high scores (B7); pictures behind the levels (B8;
Keen 1's pictures are never shown behind Keen 2's levels); two players (B9).

## Estimates to check against the original (B10)

- Starting raygun charges: 0.
- The background tile 276 for items from tile 305 on.

## Testing without Keen 2's files

- `tests/test_keen2_level.gd`: hand-made levels (`tests/keen2_fixtures.gd`).
- `tests/test_keen2_stand_in.gd`: the Keen 1 shareware files copied under
  Keen 2's names (`KEEN1.EXE` → `KEEN2.EXE`, `*.CK1` → `*.CK2`): loading
  and the course of the levels. Keen 1's `SOUNDS.CK1` becomes `SOUNDS.CK2`,
  which `Keen2GameData` uses when `KEEN2.EXE` has no sound block.
- The game screen needs a running scene tree, so it is checked with
  screenshots: make such a copy in a temporary folder, then
  `SCENE=res://src/keen2/keen2_view.tscn STEPS=... OUT=... xvfb-run -a godot
  --rendering-driver opengl3 --fixed-fps 60 --path . --script
  res://tools/scripted_play.gd -- --game=2 --level=1
  --data-dir-keen2=<copy>`. Delete the copy afterwards; it never goes into
  the repository.
