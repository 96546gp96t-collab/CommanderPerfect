# Keen 3: architecture

How Keen 3 ("Keen Must Die!") is added beside Keen 1 and Keen 2. Written in
milestone C1 by the architect; the developer follows it in C2-C11 and
updates it when a decision changes (with the reason). The milestones are in
[roadmap.md](roadmap.md), the facts about the game in
[research.md](research.md). The pattern is the one of Keen 2
([../keen2/architecture.md](../keen2/architecture.md)); read that first.

## The rule: Keen 1 and Keen 2 stay as they are

The user asked to leave the Keen 1 and Keen 2 code alone and to reuse what
is the same for Keen 3. That splits the code into four groups.

| Group | What | Allowed changes |
|---|---|---|
| **Keen 1 only** | As listed in `docs/keen2/architecture.md` (`src/actors/*`, the map and ship classes, `level_view.gd`, the Keen 1 text extractors, the `test_keen1_*` suites, …) | **None.** |
| **Keen 2 only** | `src/keen2/**`, `tests/test_keen2_*.gd`, `tests/keen2_fixtures.gd`, `docs/keen2/*` (docs may get a correction note, see below) | **None.** Not even renames, "small cleanups" or a pulled-out base class. Keen 3 may *use* and *subclass* Keen 2 classes. |
| **Shared** | Decoders, graphics and scaling, `src/level/`, `src/keen/`, `src/sound/`, `src/menu/`, `src/online/`, `src/launcher/`, `GameScreen`, `LevelSession`, `Hud`, settings, saves, high scores, tools | **Only additive, behaviour-neutral changes**: a new optional parameter whose default is the old value, a new method, a new constant, an enum value at the end, a new entry in a list of games. Never a changed default, a removed method or a changed save format. |
| **Keen 3 only** | Everything new | Free, in `src/keen3/`. |

Two exceptions, decided by the architect in C1 and to be reported to the
user:

1. **The list of games.** Assertions that the start screen has exactly two
   games (`tests/test_launcher.gd`, `tests/test_keen2_files.gd`) grow to
   three. Keen 1 stays first and Keen 2 second, both unchanged. This is the
   same exception the user approved in B2.
2. **`GameLaunch.skips_launcher` and `scene_for`** may change their bodies to
   pick one of three games (for example through a new
   `GameLaunch.game_number(arguments)`), as long as every argument list that
   worked before gives the same answer. The existing tests prove it; new
   tests add `--game=3`. The same holds for the two-way choices in the data
   viewer and `tools/export_graphics.gd`.

### The reference to compare with

The Keen 2 milestones are not on `main` yet: `milestone-b10-origineel`
contains all of them, and the C branches start from it. Until that branch is
merged, the reference is commit **`a9d04cc`** (the last commit of B10), and
after the merge it is `main`. Below, `$REF` means that reference.

### How we prove that Keen 1 and Keen 2 did not change

At the end of every C milestone:

1. Every existing test passes **without changes to the test files** (except
   the list-of-games assertions above). New suites may be added.
2. `gdlint` is clean.
3. With the Keen 1 shareware data: `tools/keen1_regression.sh` gives the same
   screenshots before (`$REF` in a `git worktree`) and after, byte for byte;
   only `launcher.png` may differ, by the third icon.
4. With the user's Keen 2 data: `tools/keen2_regression.sh` (new in C2, same
   shape: title, level 1, a walk in level 1, the world map, with
   `SCENE=res://src/keen2/keen2_view.tscn -- --game=2`) gives the same
   screenshots before and after.
5. `git diff $REF -- <Keen 1 only files> src/keen2 tests/test_keen2_*.gd
   tests/keen2_fixtures.gd` is empty (apart from exception 1).

If a shared change cannot be made behaviour-neutral, stop and ask the
architect (who asks the user).

## Where the code goes

```
src/keen3/            Keen 3 only (all class names start with Keen3)
  data/               Keen3Files, Keen3Executable (version, sounds, texts, tile table,
                      Mortimer and ship messages, ending pages)
  actors/             Keen3Grunt, Keen3Youth (subclasses of Keen 2's), Keen3Mom,
                      Keen3Fireball, Keen3Meep, Keen3SoundWave, Keen3Ninja, Keen3Foob,
                      Keen3Ball (ball and jack), Keen3Platform (horizontal and
                      vertical), Keen3WallGun, Keen3Shot, Keen3AnkhShield
  keen/               Keen3Body (Keen2Body with Keen 3's stun frames and the ankh)
  level/              Keen3LevelSession, Keen3Machine (Mortimer's Mangling Machine)
  map/                Keen3MapSession (teleporters, Messie, done signs, ship messages),
                      Keen3Messie
  game/               Keen3LevelPlay, Keen3GameData, Keen3Progress, Keen3Inventory,
                      Keen3StatusScreen, Keen3Screens, Keen3Ending, Keen3Sounds
  keen3_*_screen.gd   the screen chain on top of GameScreen (see below)
  keen3_view.gd/.tscn Keen3View, the scene the start screen opens
tests/test_keen3_*.gd Keen 3 suites; tests/keen3_fixtures.gd
docs/keen3/           Keen 3 documents
assets/backgrounds/keen3/   pictures behind Keen 3 levels (our own pictures only)
```

The list is a plan; the developer may split or merge classes, and writes
the change down here. Keep every file under ~500 lines.

## Reusing Keen 1 and Keen 2 code

Using a class unchanged, or subclassing it, is no change to it. Two
GDScript facts decide how (found in the C1 code survey):

- **Constants cannot be overridden.** Keen 2 keeps its tile and sprite
  numbers in `const`s and reads them in `sprite_index()`, `create()` and
  static helpers. A Keen 3 subclass must override every method that reads
  such a constant.
- **Static constructors return the parent type.** A Keen 3 subclass gets its
  own constructor with another name (as Keen 2 did with `begin` and
  `placed`).

| Keen 2 / Keen 1 class | For Keen 3 | Why |
|---|---|---|
| `Keen2Icons`, `Keen2RidingCollision`, `Keen2Carrier`, `Keen2SpaceSprite`, `Keen2BackdropPictures` | **Use unchanged** | Generic; no Keen 2 numbers |
| `Keen2Executable` static helpers (`find_sound_block`, `text_blocks`, `text_end`, `message_lines`, `_records_from` …) | **Call from `Keen3Executable`** (composition) | The search is generic; the offsets, the text order and the city table are Keen 2's. Note: `text_blocks` starts the first block two bytes early in KEEN3.EXE (the sound block's `0xFFFF` end mark looks like text); `Keen3Executable` trims it |
| `Keen2LevelSession` | **`Keen3LevelSession extends Keen2LevelSession`** | It has the riding, the stun, enemy shots that hurt enemies and the "no exit while riding" rule that Keen 3 needs too. Keen 3 overrides `create_enemy`, `_spawn_enemies`, `_create_keen`, `_create_shot`, `_is_item`, `_pick_up` and `_touch_special_tile`. The switches, lights and Tantalus stay idle (no behaviour 22-26 in Keen 3). If this becomes awkward, the fallback is `extends LevelSession` with its own riding code; write the choice down here |
| `Keen2Body` | **`Keen3Body extends Keen2Body`** | Same stun, but its last frame is 30 (KEENMELT) instead of 31; plus the ankh (no death, no stun) |
| `Keen2Grunt`, `Keen2Youth` | **Subclass** (`Keen3Grunt`, `Keen3Youth`) | The same behaviour as in Keen 2 (CG), other sprite numbers. Override `sprite_index` and give them their own constructor. If the original shows other numbers (C4), copy instead |
| `Keen2Enemy` | **Base class** of the new enemies | `roll`, `_is_blocked`, `_jump`; override `_fire_shot` (it makes a Keen 2 shot) |
| `Keen2Inventory`, `Keen2HighScores` | Use or subclass | `Keen2HighScores.load_from(path, …)` with `user://keen3/high_scores.json`; Keen 3 has no third column, so the city count stays 0 and is not shown |
| `Keen2LevelPlay.requested_level`, `start_cell` | Call unchanged | Static and generic |
| `Keen2Sounds.find_entry` | Call unchanged | For ANKH, MEEP, MORTIMER and FOOTSLAM, which `Sound.Id` does not name |
| Keen 1's `MapSession`, `MapCollision`, `MapKeen`, `MapMessages` | **`Keen3MapSession extends MapSession`**, the rest unchanged | Entrances and blocking (0x8000 + n) are the same; Keen 3 overrides `_use` (teleporters 0x0Fab, Messie's landings, the ship's messages) and `_mark_done` (done tiles 52-56). Own constructor, because `create` is static |
| `Keen2View` and its screen chain | **Not reusable**; Keen 3 gets its own chain | Typed Keen 2 members and Keen 2 constants in all four files. Copy the generic parts (`_shake`, `_show_game_over`, `_show_picture`, `_leave`, the input and tick loop) into Keen 3 classes |
| `keen2_view.tscn` | Copy as `keen3_view.tscn` | Same node layout as `level_view.tscn`, because `GameScreen` finds its nodes by unique name |

## The seams in the shared code

What Keen 3 needs from the shared code, and the additive change for each.

| Need | Today | Additive change |
|---|---|---|
| Find `game_data/keen3`, `KEEN3.EXE`, `*.CK3` | `GameFiles.locate_in(subfolder, required, option, extension)` (B2) | None. `Keen3Files` with `--data-dir-keen3=` |
| Graphics, levels, FINALE | `EgaGraphics.load_from(files, extension)`, `FinaleImage.load_from(files, name)` | None (checked in C1: they load the CK3 files) |
| **The tile table: 624 tiles, rows 715 wide** | `TileProperties.find_in_image(image, tile_count, known_offsets)` uses `tile_count` as the count and as the stride. With 624 it finds a *wrong* table without an error | Add an optional `stride` parameter (default: `tile_count`), so the planes are read 715 apart and only 624 tiles are kept. Known offsets for Keen 3: v1.00 0x199F8, v1.31 0x198C8 |
| Behaviours 27 (ankh) and 28 (single charge) | `TileProperties.Behavior` ends at Keen 1's values; `is_item()` does not know 27/28 | None in the shared enum: Keen 3 gets `Keen3Behavior` and `Keen3LevelSession._is_item` / `_pick_up` |
| What a pickup leaves behind | Keen 1: tile 143; Keen 2: 276 from 305 on | `Keen3LevelSession`: the first tile of the item's row, `(tile / 13) * 13`. An opened door: see research §2 |
| Sounds inside `KEEN3.EXE` | `SoundFile.parse` | None. Entries 0-40 have Keen 1's names; 41-44 (ANKH, MEEP, MORTIMER, FOOTSLAM) are played through `Keen2Sounds.find_entry` on Keen 3's own speaker (as EARTHPOW in Keen 2) |
| Texts inside `KEEN3.EXE` | `TextDocument.layout`, `ExeStrings` | None. Keen 3's order is help, end, previews, story (Keen 2: end, help, …) |
| Saves and high scores apart | `SaveGames.in_directory`, `HighScores.load_from` | None: `user://keen3/saves`, `user://keen3/high_scores.json` |
| The border tile 245 is an "OH no!" picture | Keen 1's camera keeps the 2-tile border out of view (assumed) | Check in C3 that no view (widescreen, two players, the map, the ending) ever shows the border. If the shared camera does, Keen 3 draws the border cells empty in its own `LevelMap` copy of the data, not in shared code |
| Start screen icon | `GameCatalog.games()` with two entries; the layout has room for a third (608 of 1280 px) | Append Keen 3 (title "Keen 3", `GameLaunch.KEEN_3_SCENE`, `Keen3Files.locate()`, `data_folder`, `game_id`) |
| Start Keen 3 from the command line | `GameLaunch.wants_keen_2`, `scene_for` are two-way | `--game=3`; exception 2 above |
| Data viewer, `tools/export_graphics.gd` | Two-way (`Keen2Files if keen_2 else GameFiles`) | Three-way, Keen 1 and Keen 2 the same as before; output `exported/keen3/` |
| HUD | `Hud.raygun_tile`, `keycard_icons` | Set from `Keen2Icons`. The ankh time in the HUD: preferably a `Keen3Hud extends Hud`; if `Hud` cannot be extended without a change, one new member that is off by default |
| Pictures behind levels | `BackdropPictures.create(files, folder)` | None: `Keen2BackdropPictures` with `res://assets/backgrounds/keen3` |
| Online | `OnlineProtocol.GAME_IDS`, `GameCatalog.for_game_id`, scenes/events appended at the end of their enums | `GAME_ID_KEEN_3` in `GAME_IDS`; Keen 3 scenes and events at the end; the ankh time and the done levels in the snapshot through new optional fields (C10). Keen 1's and Keen 2's messages stay byte for byte the same |
| Build scripts | Copy `game_data/keen1` and `keen2` | Same block for `keen3` |
| Tests | `tests/run_tests.gd` lists the suites | One line per new suite |

## The flow of Keen 3

```
Launcher ──click "Keen 3"──▶ keen3_view.tscn (Keen3View)
   ▲                            │ title (map 90) + main menu (shared Menu classes)
   │ "Choose Game"              ▼
   └──────────────────────── world map 80 (Keen3MapSession)
                                │ teleporters, Messie, the ship's messages
                                │ enter level 1-16
                                ▼
                              level (Keen3LevelSession)
                                │ exit ─▶ back to the map, level done
                                │ level 16: Mortimer's messages, the Mangling Machine,
                                │ the heart destroyed ─▶ level done
                                ▼
                    level 16 done ─▶ ending (map 81 with four pages, camera
                                     flashes, FINALE.CK3, end text) ─▶ high scores
```

Before the map exists (C3-C5), the flow is as in B3: level 1 (or
`--level=N`), exit to the next level, death restarts the level, game over
goes back to the start screen.

## Comparing with the original during the work

B10 showed that measuring everything at the end does not work: steering
Keen through levels in js-dos was too unreliable, so the enemies kept their
estimates. For Keen 3:

- The numbers come first from Chocolate Keen (allowed since C1, see
  `CLAUDE.md`), marked `(Choco)`, then Commander Genius, marked `estimate`.
- Every milestone that builds something visible ends with a short check
  against the original in js-dos (how to set it up:
  [research.md](research.md), "Watching the original"). The things that
  can be seen standing still (an enemy walking, a gun firing, the machine)
  are measured then, not in a last milestone.
- C11 only picks up what is left.

## Testing

As for Keen 2:

- Hand-made fixtures (`tests/keen3_fixtures.gd`) for everything that does
  not need the files; these run everywhere.
- `tests/test_keen3_data.gd` with the user's own files (`Keen3Files.locate()`,
  skip without them). Keen 3 is not shareware.
- The screens with `tools/scripted_play.gd` (`SCENE=res://src/keen3/keen3_view.tscn
  -- --game=3 --level=N`).
- A stand-in suite with Keen 1's files under Keen 3's names is **not**
  planned: Keen 3's tile and sprite numbers are too different to be useful;
  the real files are on the Mac. If a cloud session has no Keen 3 files, the
  real-data suites skip.

## Rules that carry over

All hard rules in `CLAUDE.md` apply: never commit game data or anything
derived from it, never use the name "Commander Keen" or its logo as branding
("Keen 3" on the icon is fine), never decompile `KEEN3.EXE` code (reading
data tables is fine), never copy code from Commander Genius, Chocolate Keen
or other projects. Extras are off by default, with the user's exceptions
(widescreen with HUD, pictures behind levels).

## Deviations in C2

Written by the developer of C2. None of them changes Keen 1 or Keen 2.

- **`TileProperties.from_table` also got the optional `stride`** (default
  -1 = the tile count), besides `find_in_image`: the search hands the found
  table to it. A test (`test_keen3_files.gd`) shows that the default reads
  the same values as an explicit stride of the tile count and as a plain
  reading of the old layout, also for the real Keen 1 and Keen 2 tables.
- **The two bytes before the help text** are not the end of the sound
  block (which ends at 0x16604) but the `0xFFFF` of a table of words right
  before the help. `Keen3Executable.text_blocks` moves every start past
  font-picture bytes (0x80 and up), so no text starts with one.
- **The sound block** is cut at the end of its last sound's data: the size
  word in its header (16,224) runs up to the help text.
- **No `Keen2Executable.line_records`:** it stops at Keen 2's known text
  positions, which could cut a Keen 3 run short. `Keen3Executable` has its
  own small record reader; it only calls Keen 2's public helpers
  (`find_sound_block`, `text_blocks`, `text_end`, `message_lines`) and
  constants. The private `_records_from` is not called.
- **Ending pages without a known position:** they are the line records
  right before the finale name (`ExeStrings.lines_before`), the box over the
  finale the record after it; Mortimer's boxes follow the points table. Only
  the status box and the ship's messages have a 1.00 position and a
  record-by-record search.
- **`OnlineProtocol.GAME_ID_KEEN_3`** is a new constant so that the catalog
  entry has its own id; it is **not** in `GAME_IDS` (online play comes in
  C10), so nothing online changes.
- **`Keen3Behavior`** (27 ankh, 28 single charge) lives in
  `src/keen3/data/`.
- **The placeholder `keen3_view.tscn`** is a plain `Control` with a "Keen 3 -
  coming soon" text, as Keen 2's in B2; C3 replaces it with the copy of
  `keen2_view.tscn` described above.
- **The hand-made KEEN3.EXE image** for the tests is in
  `tests/keen3_fixtures.gd`.
- **`tools/keen2_regression.sh`** takes title, level 1, the walk in level 1
  and map 80, but not the start screen: that changes with every new game
  (the Keen 1 script keeps it, and only its `launcher.png` may differ).
