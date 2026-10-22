# Keen 5: architecture

How Keen 5 ("The Armageddon Machine") is added beside Keen 1-4. Written in
milestone E1 by the architect, with a code survey by a developer agent
and the user's own Keen 5 files run through the existing readers. The
developer follows it from E2 on and writes every change of plan down
here, under "Deviations in E<n>", with the reason. The milestones are in
[roadmap.md](roadmap.md), the facts about the game in
[research.md](research.md), the files in [file-formats.md](file-formats.md).

Read [../keen4/architecture.md](../keen4/architecture.md) first: Keen 5
is the **same engine** as Keen 4 (id's Galaxy engine), and everything
there about time, units, drawing, widescreen, the score box, sound and
testing holds unchanged. This page only says what Keen 5 adds and how it
stays out of Keen 1-4.

## What the survey found

### The engine is ready; the game around it is not

| Part | Where it is now | For Keen 5 |
|---|---|---|
| Reading the files (EXE, headers, EGAGRAPH, GAMEMAPS, TILEINFO, AUDIO) | `src/galaxy/data/`, parameterised by `GalaxyEpisode` | **Works on Keen 5 today** (E1, files): all six headers found by content, 93 pictures, 346 sprites, 16 maps, 206 sound chunks. Two additive fields needed (file-formats.md): the tile border and the order of texts and misc chunks |
| Drawing a level, camera, scroll blocks, xBRZ, pictures behind levels | `src/galaxy/level/`, `graphics/` | Shared as is |
| Clock, actions, clipping with slopes, Keen's moves, the stunner, items, platforms | `src/galaxy/physics/`, `actors/`, `keen/` | Shared; Keen 5's own tile kinds and items need hooks (below) |
| OPL2 synthesiser, AdLib, PC speaker, music, cache | `src/galaxy/sound/` | Shared; Keen 5 brings its own sound and song tables |
| Windows, score box, menus, Paddle War, help pages, split screen, online messages | `src/galaxy/ui/`, `level/`, `online/` | Shared; the 8×8 tiles they use (digits 41/42, menu icons 92-100) sit at the same places in Keen 5 (E1, files) |
| **The screen chain** (level → play → front → menu → co-op → joined → online → view, 3,054 lines) | `src/keen4/keen4_*_screen.gd`, `keen4_view.gd` | **Keen 4 only.** ~85-95 % of each file is episode-neutral, but every field is typed with `Keen4*` classes |
| Level session, map session, saved game, status window, game boxes, help, ending, title loop, high-score board, audio, settings, start, online state, box names (~2,300 lines) | `src/keen4/game/`, `level/`, `map/`, `online/` | **Keen 4 only**, 50-95 % episode-neutral each |
| Creatures and objects | `src/keen4/actors/` (26 files) | Keen 4 only; Keen 5 writes its own |

In `src/galaxy/` the word Keen 4 appears 64 times: 62 in comments, and two
default folders (`GalaxySaveSlots.DEFAULT_DIRECTORY = "user://keen4/saves"`,
`GalaxySoundCache.DEFAULT_DIRECTORY = "user://keen4/cache"`). No Galaxy
class uses a `Keen4*` class. So the D1 decision ("the engine in
`src/galaxy/`, the episode in `src/keen4/`") held for the engine, but not
for the game around it: that went into `src/keen4/`.

### Three ways to give Keen 5 a game around the engine

GDScript class names are global and a class has one parent; a later
episode never extends an earlier one (lesson of D1 and Keen 3). That
leaves three ways:

| Way | What | For | Against |
|---|---|---|---|
| **1. Copy** | Copy `src/keen4/` (game, screens, sessions) to `src/keen5/` and rename | Fastest start; Keen 4 untouched | ~4,500 lines twice, three times with Keen 6; a fix must be made in every copy |
| **2. Refactor Keen 4** | Move the neutral parts of Keen 4 into `src/galaxy/` and let Keen 4 and 5 both use them | One copy, best for Keen 6 | Changes Keen 4 a lot; its tests reach ~45 private members of the chain; risk to a finished, tested episode |
| **3. Lift (advice)** | **New** generic classes in `src/galaxy/game/` (the chain, the sessions, the saved game, ...), made from Keen 4's by copying and generalising: episode numbers come from a parameter object, episode content through small hooks. Keen 5 (and later 6) build on them. **Keen 4 stays exactly as it is** | Keen 4 has no change at all; Keen 5 and 6 share one copy; Keen 4 can move onto it later, proven by its demos and screenshots | For a while two near-equal chains exist (Keen 4's frozen one and the Galaxy one); a bug fix in that part is made twice until Keen 4 moves |

The advice is **way 3** (a question to the user, research.md §13): it is
what the user asked for ("as little as possible of the existing code
changed, everything keeps working") and it does not cost Keen 6 a third
copy. Moving Keen 4 onto the Galaxy chain is an optional milestone at the
end (E13), only if the user wants it.

## The rule: Keen 1-4 stay as they are

| Group | What | Allowed changes |
|---|---|---|
| **Keen 1-3** | As in `docs/keen2/architecture.md` and `docs/keen3/architecture.md` | **None.** |
| **Keen 4 only** | `src/keen4/**`, `tests/test_keen4_*.gd`, the Keen 4 fixtures, `assets/backgrounds/keen4/`, `tools/keen4_regression.sh`, `tools/make_keen4_backgrounds.py` | **None**, with one exception below |
| **Galaxy** (shared since Keen 4 was done) | `src/galaxy/**`, `tests/test_galaxy_*.gd`, the Galaxy fixtures | **Only additive, behaviour-neutral changes**: a new class, a new optional field or parameter whose default is today's value, a new virtual hook that does nothing by default, an enum value at the end. Never a changed default, a removed or renamed method, a changed save format |
| **Shared** (launcher, menus, online, settings, tools, …) | As in the Keen 4 architecture | Additive only |
| **Galaxy game** (new) | `src/galaxy/game/**` (way 3) | Free during the E milestones; shared once Keen 5 is done (for Keen 6) |
| **Keen 5 only** (new) | `src/keen5/**`, `tests/test_keen5_*.gd`, `docs/keen5/`, `assets/backgrounds/keen5/` | Free |

Exceptions (to be confirmed by the user, research.md §13):

1. **The list of games**: the assertions on the number of games grow by
   one (`tests/test_launcher.gd:78`, `test_keen2_files.gd:159`,
   `test_keen3_files.gd:227`), as for Keen 2-4.
2. **`tests/test_keen4_online.gd:26`** checks that Keen 4 is the *last*
   online game id. With `GAME_ID_KEEN_5` appended it must say "Keen 4 is
   fourth". This is the only Keen 4 file that changes, and only that
   assertion.
3. **`GameLaunch`, the data viewer, `tools/export_graphics.gd`** get a
   fifth branch, as for Keen 4; every old argument list gives the same
   answer (the lowest `--game=` wins).

Proof at the end of every E milestone (as in the D series):

1. Every existing test passes without changes to the test files, apart
   from exceptions 1 and 2; new suites may be added.
2. `gdlint` is clean (and `gdformat --check`).
3. `tools/keen1_regression.sh`, `tools/keen2_regression.sh` and
   `tools/keen4_regression.sh` give the same screenshots as on `$REF`;
   only `launcher.png` may differ, inside the fifth icon.
4. `git diff $REF -- src/keen2 src/keen3 src/keen4 <Keen 1 only files> tests/test_keen2_*.gd tests/test_keen3_*.gd tests/test_keen4_*.gd`
   is empty, apart from exceptions 1 and 2.
5. For changes in `src/galaxy/` (not `game/`): the Keen 4 demo suite
   (`test_keen4_demo_sync`) and the Keen 4 real-data suites pass, which
   needs the Keen 4 files (research.md §13: upload them to the cloud
   session or run on the Mac).

`$REF` is the commit the E branch started from.

## Where the code goes

```
src/galaxy/                 the engine, as now; only additive changes
  data/galaxy_episode.gd    + back_tile_count, texts_before_misc (E2), and later the
                            fields the Galaxy game needs (below)
  keen/                     + hooks: spawning a subclass of GalaxyKeen, other tile kinds,
                            more items (E3)
  game/                     NEW (way 3): the generic game around the engine, lifted
                            from src/keen4/ and generalised
    galaxy_game_rules.gd      GalaxyGameRules: the numbers and tables of one episode
                              that the game needs (map numbers, info values, picture
                              and sprite offsets, sound and song tables, user folders,
                              game id, title-loop steps, help and ending numbers)
    galaxy_level_screen.gd    GalaxyLevelScreen  ┐ the chain, from Keen4LevelScreen
    galaxy_play_screen.gd     GalaxyPlayScreen   │ ... Keen4OnlineScreen, with virtual
    galaxy_front_screen.gd    GalaxyFrontScreen  │ hooks where Keen 4 has its own
    galaxy_menu_screen.gd     GalaxyMenuScreen   │ content (_after_level_frame,
    galaxy_coop_screen.gd     GalaxyCoopScreen   │ _finish_level, _check_cheats,
    galaxy_joined_screen.gd   GalaxyJoinedScreen │ _after_map_frame, _status_rows,
    galaxy_online_screen.gd   GalaxyOnlineScreen ┘ _extra_boxes ...)
    galaxy_level_session.gd, galaxy_map_session.gd, galaxy_start.gd,
    galaxy_saved_game.gd, galaxy_game_boxes.gd, galaxy_status_window.gd,
    galaxy_help.gd, galaxy_ending.gd, galaxy_title_loop.gd,
    galaxy_high_score_board.gd, galaxy_audio.gd, galaxy_settings.gd,
    galaxy_files.gd, galaxy_icon.gd, galaxy_progress.gd,
    galaxy_online_state.gd, galaxy_box_names.gd, galaxy_cheats.gd,
    galaxy_creature_table.gd (the info-value → creature dispatch)
src/keen5/                  Keen 5 only (class names Keen5...)
  data/                     Keen5Files, Keen5Episode (GalaxyEpisode + GalaxyGameRules),
                            Keen5Sprites, Keen5CreatureSprites, Keen5Sounds
  actors/                   one file per creature or object (research.md §7)
  level/                    Keen5LevelSession (on GalaxyLevelSession), Keen5Keen (the
                            keycard, the security doors, Keen 5's tile kinds), Keen5Fuses
  map/                      Keen5MapSession (elevators, the fuses' marks, Korath III)
  game/                     Keen5Progress, Keen5Messages, Keen5StatusWindow,
                            Keen5Ending, Keen5Cheats
  keen5_view.gd/.tscn       Keen5View on GalaxyOnlineScreen: what only Keen 5 does
tests/test_keen5_*.gd, tests/test_galaxy_game_*.gd, tests/keen5_fixtures.gd
docs/keen5/
assets/backgrounds/keen5/   our own pictures behind the levels (E10)
```

The list is a plan. Keep every file under ~500 lines and 20 public
methods (gdlint). The Keen 4 originals are the model: when lifting a
class, copy it, replace every `Keen4*` type by its Galaxy base, every
Keen 4 number by a field of `GalaxyGameRules`, and every piece of Keen 4
content (council, wetsuit, Lindsey, swimming, Miragia, the Foot) by a hook
that does nothing. Keep the private member names: Keen 4's tests show
which ones matter, and a later move of Keen 4 (E13) is then a rename.

## The seams in the Galaxy engine (additive)

From the survey; each one keeps Keen 4's behaviour by its default.

| Need | Today | Additive change | Milestone |
|---|---|---|---|
| The tile border | `GalaxyChunkRanges` works it out (1440 for Keen 5, wrong) | `GalaxyEpisode.back_tile_count` (0 = work it out) | E2 |
| Texts before misc chunks | Misc, texts, demos | `GalaxyEpisode.texts_before_misc` (false) | E2 |
| User folders | Defaults `user://keen4/saves`, `user://keen4/cache` | Keen 5 always passes `user://keen5/...`; a test checks it. The defaults stay | E2, E9 |
| A subclass of Keen | `GalaxyKeen.spawn` does `GalaxyKeen.new()` | An optional argument (the Keen to place, default a new `GalaxyKeen`), as `GalaxyMapKeen.place` | E3 |
| Keen 5's tile kinds | `GalaxyKeenBody._touch_tiles` knows misc 7-10, 15-17, 21-28 (16: Keen 4's moon) | A virtual `_touch_other_tile(kind)` for the kinds it does not know (Keen 5: 31 computer, 32 security door; the fuse is a top value, 57). Misc 16 exists on two Keen 5 tiles but does nothing: Keen 5 leaves `shows_moon` false | E3 |
| Keen's extra actions | `GalaxyKeenActions` has Keen 4's rows | Keen 5 adds `ride_platform`, `enter_security_door`, `entered_door` in `Keen5Keen` (its own table merged on top); Keen 4's rows unchanged | E3, E5 |
| A 13th item (the keycard) | 12 items; `ITEM_SOUNDS` clamped to 12 | `GalaxyInventory`/`GalaxyKeenBody` take the item tables from the episode (defaults Keen 4's 12) | E3 |
| Objects sleep 6 tiles out | `GalaxyWorld.SLEEP_MARGIN = 4` | A field `sleep_margin` (default 4) | E4 |
| Shots that live only on screen | — | A flag on the shot (default off) | E4 |
| Creatures that flash white | — | A "white" draw mode in `GalaxyObjectLayer` (default off) | E4 |
| Extra drawn sprites (Sphereful diamonds, the mine's eye) | One sprite per object | Optional extra sprites per object (default none) | E4 |
| Scroll blocks | Keen 4 passes 25 (rows) and 26 (columns) to `GalaxyCamera.blocks_in` | Nothing to change: Keen 5 passes only 25 (info 26 is Korath III's arrival) | E3 |
| No thrown flag, another flag offset | `GalaxyMapFlag` with offsets from the episode | Keen 5 places waving flags only, at (−0x50, −0x1E0) | E6 |
| The viewer page title | `"Keen 4 %s: ..."` | A title parameter, default "Keen 4" | E2 |
| `export_graphics._export_galaxy` | Keen 4 only | Parameters (files, episode, folder) with Keen 4's as defaults | E2 |
| Keen 6 later | The platform priority fix, the clip's middle column | Not for Keen 5; flags when Keen 6 comes | — |

## The flow of Keen 5

```
Launcher ──click "Keen 5"──▶ keen5_view.tscn (Keen5View)
   ▲                            │ title loop: intro, story, demos 0-3, high scores
   │ "Choose Game"              │ control panel: New Game (Easy/Normal/Hard), Load, ...
   └─────────────────────────── ▼
                         world map, map 0, the Omegamatic (Keen5MapSession)
                           │ walk, teleporters, elevators; the upper shaft opens
                           │ after the four fuse levels (4, 6, 8, 10)
                           │ enter level n (0xC000 + n), "Keen ..." box
                           ▼
                         levels 1-13 (Keen5LevelSession)
                           │ the exit door (0xB1B1) ─▶ level done, flag on the map
                           │ the fuse broken (4, 6, 8, 10, 13) ─▶ fuse message, done
                           │ the door to Korath III (0x0000) ─▶ the map, on Korath III
                           │ death ─▶ "Try Again / Exit to Armageddon"
                           │ game over ─▶ the galaxy explodes ─▶ high scores
                           ▼
              map 12, the QED destroyed by a mine ─▶ end pages (the secret end
              when the Korath III fuse was broken) ─▶ high scores (map 15)
```

The details are in research.md §4 and §8-§9; the developer checks them in
js-dos while building.

## Time, drawing, widescreen, the score box, sound

As in [../keen4/architecture.md](../keen4/architecture.md), unchanged:
35 logic frames per second (2 tics), the original's pixel steps, smooth
motion as the shared option; three tile layers; the camera stops at scroll
blocks and widescreen covers what lies beyond; the score box is the HUD;
our own OPL2 renders AdLib sounds and songs into `user://keen5/cache/`.
These were the user's decisions for Keen 4; whether they hold for Keen 5
too is question 2 in research.md §13 (advice: yes).

Keen 5 has 14 songs (Keen 4: 6) and 64 sounds per device (Keen 4: 52):
the song per map and the sound names come from `Keen5Sounds` (research.md
§9-§10). Help has its own song in Keen 5.

## Testing

- `tests/keen5_fixtures.gd`: hand-made pieces where Keen 5 differs (an
  EGAGRAPH with texts before misc chunks and empty tiles at the border;
  mini-levels with Keen 5's tile kinds and objects).
- `tests/test_keen5_data.gd` with the user's files (`Keen5Files.locate()`,
  skip without them): 93 pictures, 346 sprites, 1512 + 2952 tiles, 16
  map slots, 206 sound chunks, the level names.
- `tests/test_galaxy_game_*.gd` for the lifted classes, with a small
  episode of fixtures, so the Galaxy game is tested without Keen 4 or 5.
- Keen 5 is **not shareware**: a cloud session has its files only when
  the user uploads them (as in E1). The real-data suites skip without
  them.
- Screens with `tools/scripted_play.gd`
  (`SCENE=res://src/keen5/keen5_view.tscn -- --game=5 --level=N`) and a new
  `tools/keen5_regression.sh` from E3 on.
- js-dos (`tools/original/`) works as it is: bundle `game_data/keen5`,
  start `KEEN5E`.

## Rules that carry over

All hard rules in `CLAUDE.md`: never commit game data or anything derived
from it (no rendered audio, decoded pictures, level dumps); never the name
"Commander Keen" or its logo as branding ("Keen 5" on the icon is fine);
never decompile `KEEN5E.EXE` code (reading data tables and headers is
fine); no copied code from Omnispeak, Commander Genius or the Keen Dreams
source. Extras are off by default, with the user's exceptions (widescreen
with the score box, pictures behind levels in widescreen). Talk to the
user in Dutch; code, comments and commit messages in English.
