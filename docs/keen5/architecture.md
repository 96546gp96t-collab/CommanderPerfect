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
| **3. Lift (chosen)** | **New** generic classes in `src/galaxy/game/` (the chain, the sessions, the saved game, ...), made from Keen 4's by copying and generalising: episode numbers come from a parameter object, episode content through small hooks. Keen 5 (and later 6) build on them. **Keen 4 stays exactly as it is** | Keen 4 has no change at all; Keen 5 and 6 share one copy; Keen 4 can move onto it later, proven by its demos and screenshots | For a while two near-equal chains exist (Keen 4's frozen one and the Galaxy one); a bug fix in that part is made twice until Keen 4 moves |

**Decided by the user (22-10-2026): way 3.** It is
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

Exceptions (approved by the user, 22-10-2026):

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
   needs the Keen 4 files: the user uploads Keen 2, 3 and 4 to every Keen
   5 cloud session (decided 22-10-2026).

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
These were the user's decisions for Keen 4; they hold for Keen 5 too
(decided 22-10-2026).

**Playing as the original** (the user's demand, 22-10-2026): with every
option off (4:3, no pictures behind the levels, no xBRZ, no smooth
motion) Keen 5 looks and plays exactly like the original v1.4, as Keen 4
does like its v1.0 and v1.4. So every extra Keen 5 adds is an option that
can be switched off, and nothing of an extra may leak into the 4:3
picture with the options off (the pictures behind the levels only show in
widescreen, as for Keen 1-4). E7 and E12 prove it with the demos frame for
frame against the original.

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

## Deviations in E2

What E2 built differently from the plan above, and why (developer, E2):

1. **The fuse messages are a run of texts by length, not a message run by
   lines.** Their shape (2 lines, then 4) also matches an earlier place in
   the program, so a search without the known place found the wrong one.
   Their lengths (36, 69) are unique: `Keen5Episode.FUSE_TEXTS` in
   `text_lengths`. The arrival on Korath III ("Keen steps out ...") is no
   run of its own: it is the third record of the `game` run, found by the
   lengths of the whole run (`Keen5Episode.KORATH_TEXT`). Keen 5 has no
   "Game Over!" text (it shows a picture), so its `game` run starts one
   record later than Keen 4's and has "Exit to Armageddon" in it.
2. **The version table has one size per version.** `executable_sizes` is a
   dictionary from version to size, so it holds the user's packed 1.4
   (106,417 bytes) and CG's unpacked 1.0 (262,176), but not CG's unpacked
   1.4 (266,096) as well: such a program is read all the same (everything
   is found by content), only its version reads "unknown". Nothing depends
   on Keen 5's version yet; if a later milestone needs it, an additive
   field with the unpacked image's size (254,832 for both 1.4 programs)
   would name both.
3. **`GalaxyChunkRanges` refuses a given border beyond the tile chunks**
   (null with the usual error), the same way it refuses a file with too
   few chunks. Keen 4 never gives a border, so nothing changes for it.
4. **The data viewer's program tab also lists the text runs**
   (`GalaxyEpisode.text_lengths`: status labels, game texts, cheat, and for
   Keen 5 the fuse messages). Additive: Keen 4's page shows a few more
   lines; nothing else on it changed.
5. **`Keen5View` is a plain screen of its own** (a 320×200 picture drawn
   with Keen 5's menu font and Keen standing, sprite 6), not a stripped
   `Keen4View`: the plan's D2 "coming soon" screen is not in the history
   any more, and the real view comes with the shared game in E3. Escape or
   Enter goes back to the start screen.

## The Galaxy game (from E3)

How the shared game around the Galaxy engine is built (way 3). Later
milestones follow it; Keen 4's own classes stay as they are (E13 may move
Keen 4 onto these).

### The classes in `src/galaxy/game/` (E3)

| Class | Made from | What it is | Lines |
|---|---|---|---|
| `GalaxyGameRules` | the numbers in `Keen4Episode` and the Keen 4 classes | The numbers and tables of one episode (below); the episode fills it in (`Keen5Episode.game_rules()`) | 138 |
| `GalaxyStart` | `Keen4Start` | Keen's start by the rules' info values: standing or on the world map (Keen 4's swimming start is Keen 4's own) | 70 |
| `GalaxyLevelSession` | `Keen4LevelSession` | A level played: the world, Keen, the items, the camera, the level's end, the second player; without the swimmer | 283 |
| `GalaxyLevelScreen` | `Keen4LevelScreen` | Drawing a map: tiles, sprites, xBRZ, camera, cover, pictures behind the levels; files and pictures from the rules | 334 |
| `GalaxyPlayScreen` | `Keen4PlayScreen` | Playing a level on the clock, the score box, the queue of boxes, looking at a map without a level; without the status window, the world map, sound and music (hooks) | 398 |

The chain is `GameScreen` → `GalaxyLevelScreen` → `GalaxyPlayScreen` →
the episode's view (`Keen5View`). When the front, menu, co-op and online
screens are lifted (E7, E9, E11), they go between `GalaxyPlayScreen` and
the view, as in Keen 4's chain, and the view's parent moves up.

### `GalaxyGameRules`

| Field | Keen 5 | What |
|---|---|---|
| `name`, `data_folder`, `data_dir_option` | "Keen 5", `game_data/keen5`, `--data-dir-keen5=` | The messages when the files are missing or unreadable |
| `locate_files`, `load_data` (Callables) | `Keen5Files.locate`, `Keen5Episode.load_data` | Finding and reading the files |
| `user_folder` | `user://keen5` | Settings, saves, sound cache (used from E8/E9) |
| `world_map`, `first_level`, `last_level`, `last_map`, `missing_maps` | 0, 1, 13, 15, [14] | `is_level`, `next_level` |
| `keen_right_info`, `keen_left_info`, `map_keen_info` | 1, 2, 3 | Keen's start (`GalaxyStart`) |
| `row_block_info`, `column_block_info` | 25, −1 (none) | Scroll blocks |
| `first_item_info`, `last_item_info`, `more_item_infos`, `low_stunner_info`, `low_shots` | 57, 68, {70: 12}, 69, 5 | Items by info value (`item_of_info`) |
| `keen_stand_right_sprite`, `keen_stand_left_sprite`, `map_keen_sprite` | 6, 14, 142 | Keen standing still, on the map |
| `sprites` | `Keen5Sprites.all()` | Every sprite by name (Keen, items, shot, splash, SCOREBOX); `level_sprites()` for xBRZ |
| `start_lives`, `start_shots`, `first_extra_life`, `stunner_charges`, `easy_stunner_charges` | 3, 5, 20000, 5, 8 | A new game, `charges_for(level)` |
| `backdrop_folder`, `sky_tiles` | `res://assets/backgrounds/keen5`, none | The pictures behind the levels (none until E10) |

### The hooks (virtual methods that do nothing or Keen 4's thing by default)

| Where | Hook | Default | Keen 5 |
|---|---|---|---|
| `GalaxyLevelSession` | `_new_keen()` | a `GalaxyKeen` | `Keen5Keen` (`Keen5LevelSession`) |
| | `_set_up_keen(walker)` | easy jumps on Easy | — (Keen 4 would show the moon) |
| | `_place_info(info, cell)` | nothing | creatures and platforms from E4/E5 |
| `GalaxyPlayScreen` | `_new_inventory()` | a `GalaxyInventory` with the rules' numbers | `Keen5Inventory` |
| | `_new_session(map, number, random_start)` | a `GalaxyLevelSession` | `Keen5LevelSession` |
| | `_play_sound(name, interrupt)`, `_play_map_song(map)` | silent | E8 |
| | `_after_frame()`, `_waiting(tics)`, `_frame_input(tics)`, `_partner_input()`, `_wide_view_changed(width)`, `_partner_view_width(width)` | as Keen 4's | `Keen5View._after_frame`: the next level, a death |
| `GalaxyKeenBody` (engine, additive) | `_action_rows()`, `_item_rows()`, `item_sounds` | Keen 4's rows and twelve sounds | Keen 5's rows without the moon and with `enter_security_door`, `entered_door`; four splash pictures; the keycard's sound |
| | `_touch_other_tile(cell, kind)` | nothing | — (no Keen 5 tile acts on touch) |
| `GalaxyKeen` (engine, additive) | `spawn(..., keen)` | a new `GalaxyKeen` | a `Keen5Keen` |
| | `_is_door(kind)`, `_enter_door(kind)` | misc 2; the normal door | misc 32 too; the keycard and the door opener |

What an episode adds beyond these (Keen 5's keycard, its door targets)
lives in its own subclasses: `Keen5Keen` overrides `_think_enter_door`,
`Keen5Inventory` overrides `collect` and `drop_gems`.

## Deviations in E3

What E3 built differently from the plan above, and why (developer, E3):

1. **`GalaxyFiles`, `GalaxySettings` and `GalaxyIcon` were not lifted.**
   `Keen5Files` and `Keen5Icon` from E2 already do their job; the rules
   hold the two Callables (`locate_files`, `load_data`) the screen needs.
   `GalaxySettings` belongs to the sound settings (Keen 4's quiet AdLib)
   and comes with E8/E9.
2. **The status window, the world map, sound and music stay out of
   `GalaxyPlayScreen`** until their milestones (E6, E8): Keen 4's
   `_on_map`, `_status_drop`, `_audio`, `_game_progress` were left out,
   the sounds go through the hook `_play_sound` (silent). The queue of
   boxes was lifted (small, generic, tested) though Keen 5 shows no box
   yet.
3. **Keen 5's sprites are not Keen 4's numbers.** The brief expected
   Keen's own sprites at Keen 4's indices; that holds only up to putting
   the book away (34). Looking down is one earlier in Keen 5 (35, 36), KEENONPLAT
   follows (37), dying is at Keen 4's 38/39, and from shooting on every
   picture is one further than Keen 4's: `Keen5Sprites` has its own full
   table from Omnispeak (chunk − 102), and the js-dos frame of level 1
   confirms it to the pixel.
4. **Info 70 is item 12, not 70 − 57.** Omnispeak places it with
   `infoValue − 58`; a plain item range would have made it 13 and 69 the
   keycard. The rules have `more_item_infos` for values outside the range.
5. **Two more engine hooks than planned**: `_action_rows()` and
   `_item_rows()` in `GalaxyKeenBody`, because `GalaxyKeenActions.create`
   asks for the moon's sprites (an error in Keen 5) and the Vitalin splash
   has four pictures. Both return exactly what `use_sprites` built before,
   so Keen 4 is unchanged (its demo suite, real-data suites and
   regression screenshots are all the same). `_press_up`'s door part was
   split into `_is_door` and `_enter_door`; the order of its statements is
   the same.
6. **The flow is D4's, not the original's**: level 1 at start, the next
   level after a done one (13 → 1), a death the level again, game over
   the start screen. Without `--level` the game starts in level 1 (the
   title loop comes in E7). Map 15 (the high scores) has a Keen and is
   played; map 0 is only looked at.
7. **Not in E3**: the teleport lightning at doors whose head-row info is
   0 (E6, with the door to Korath III), and the fuse levels cannot be
   finished yet (no exit door; E5 breaks the fuses).

## Keen 5's creatures (from E4)

Each creature is its own class in `src/keen5/actors/` with its own action
table (rows as Keen 4's, numbers from Omnispeak's `ACTION.CK5`), placed by
`Keen5Creatures` from the info plane through the hook
`Keen5LevelSession._place_info` (row by row, as the original scans, for
the difficulty played). The rules are in [gameplay.md](gameplay.md), "The
creatures".

| Class | What | Lines |
|---|---|---|
| `Keen5Creatures` | Info value → kind and lowest difficulty (triples, the turrets' 4 × 3, the Korath), the values for later milestones (`LATER`) and those that place nothing (`READ_ONLY`); writes a GoPlat's start arrow (below); the creatures' sound names with Omni's numbers (for E8) | 214 |
| `Keen5Creature` | The base (on `GalaxyCreature`): placing with a rise, the "deadly" contact, pushing Keen sideways, knocking him off a pole, the white flash, turning round | 109 |
| `Keen5Sparky`, `Keen5Ampton`, `Keen5Shelley`, `Keen5Korath`, `Keen5Shikadi`, `Keen5Shockshund`, `Keen5RoboRed`, `Keen5Spirogrip`, `Keen5Spindred`, `Keen5Master`, `Keen5Sphereful`, `Keen5Mine`, `Keen5Volteface`, `Keen5Turret` | One creature each | 61-250 |
| `Keen5Slicestar` | On `GalaxyPlatform` (the straight ones move by its axis rule); Keen never rides it | 108 |
| `Keen5Shot`, `Keen5MasterBall`, `Keen5PoleSpark` | The shots (on `GalaxyEnemyShot`): Robo Red's, the bark, the lasers; the Master's ball and sparks; the Shikadi's pole spark | 70, 89, 49 |
| `Keen5Piece` | The pieces of a Shelley or a mine (on `GalaxyShrapnel`); a mine's piece tells an object it touches (`hit_by_piece`, for E5's QED) | 45 |
| `Keen5CreatureSprites` | Sprite names → indices (Omni `GFXCHUNK.CK5`, chunk − 102), merged into `Keen5Sprites.all()` | 170 |

`Keen5Keen` gained `push_sideways` (Omni CK_PhysPushX: the Ampton, the
Korath and the Shelley push only sideways) and `knock_off_pole` (Keen 5
knocks Keen off a pole without pushing him, unlike Keen 4's `knock_off`).

## Deviations in E4

What E4 built differently from the plan above, and why (developer, E4):

1. **Two of the planned seams already existed, so they were not added.**
   Shots that live only on the screen are the existing
   `Activity.ON_SCREEN_ONLY` (Omni OBJ_EXISTS_ONLY_ONSCREEN: removed
   beyond the sleep margin, which is now Keen 5's 6 tiles); extra drawn
   sprites are the existing `GalaxyObject.overlays` (the stars, Keen 4's
   jets): the mine's eye and the Sphereful's four diamonds are overlays
   with their own priorities. Box clipping (Omni CK_PhysFullClipToWalls)
   is the existing `GalaxyClip.update_simple_box` (Keen 4's birds and
   fish); the Slicestar and Sphereful use it with a 512 × 512 box.
2. **The seams that were added** (all neutral for Keen 4 by their
   defaults; Keen 4's demo suite, real-data suites and 11 regression
   pictures are unchanged): `GalaxyWorld.sleep_margin` (default
   `SLEEP_MARGIN` = 4; `_far_from_all` and `_is_far` got a margin
   parameter defaulting to it); `GalaxyObject.flash_white` (default off)
   with a white shader in `GalaxyObjectLayer` that only touches an
   object's material while the flag differs from what is drawn; two new
   classes, `GalaxyShrapnel` (Omni CK_ShrapnelTileCol, shared with Keen 6
   later) and `GalaxyPathArrows` (the GoPlat/Volteface rule, for E5's
   GoPlats and Keen 6).
3. **The GoPlats' start arrows are written now.** The original writes a
   GoPlat's arrow into its own tile while it scans; level 13 has a
   Volteface whose path runs through a GoPlat's tile (info 37 at 33,18),
   so without the arrow the Volteface stopped there. `Keen5Creatures`
   writes the arrow for info 36-39 and 80-83 and places nothing; E5 adds
   the platform itself (and must not write the arrow twice).
4. **A Volteface or GoPlat that reaches a tile without an arrow stops**
   (with an error) instead of quitting the game as the original does.
   None does in levels 1-13 on any difficulty (`test_keen5_creatures_play`).
5. **The pole spark runs 48 units a frame**, not "48 units a tic" as
   research.md §7 says: Omni CK5_PoleZap sets the move without the
   frame's tics.
6. **The first frame of the Ampton's climb moves it one unit row back**
   (−32): the original runs an action with timer 0 on a leftover tic as
   "timer − 1" = −1 tics (Omni CK_RunAction); our world does the same, so
   it is kept.
7. **A Godot pitfall**: a `const` typed `Array[PackedInt32Array]` written
   as nested literals reads 0 when indexed with variables; the bounce
   table of `GalaxyShrapnel` is one flat `PackedInt32Array` (row × 8 +
   column).
