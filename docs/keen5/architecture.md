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
| `GalaxyPlayScreen` | `Keen4PlayScreen` | Playing a level or (E6) the world map on the clock, the score box, the queue of boxes, looking at a map without Keen; sound and music are hooks | 436 |
| `GalaxyFlowScreen` (E6) | `Keen4View`'s flow, `Keen4PlayScreen`'s status window, `Keen4FrontScreen`'s loading box | The flow between the maps: map N shown, an entrance → "One moment", the loading box and the fade, a level done → marked with its value and back to the map, a death → the choice box, no life left → game over; the status window dropping over the game | 385 |
| `GalaxyMapSession` (E6) | `Keen4MapSession` | The world map played: the map Keen, the camera, entrances, done levels (gates, waving or thrown flags by the rules) | 214 |
| `GalaxyProgress` (E6) | `Keen4Progress` | Levels done with a value, the place on the map, the level just finished; a saved game's dictionary with the episode's extras | 89 |
| `GalaxyGameBoxes` (E6) | `Keen4GameBoxes` | The loading box with the count-down (any text), "One moment", PAUSED, the death box with its blinking choice, "Game Over!" when the episode has the text | 181 |
| `GalaxyStatusWindow` (E6) | `Keen4StatusWindow` | The status window: frame, labels, digit bars; the episode's own middle and bottom rows as hooks, the "press a key" tiles' place as a field | 280 |
| `GalaxyFrontScreen` (E7) | `Keen4FrontScreen`, Keen4View's cheats | Between the flow and the view: the title loop, the demos (DEMO sign, 3 tics a frame, Normal, random table from 0), the end pages, a scene over the whole screen, the name typed in on the high-score map, the two cheats (E9: the help and a new game moved to `GalaxyMenuScreen`) | 535 |
| `GalaxyTitleLoop` (E7) | `Keen4TitleLoop` | Intro, demo 0, story, demo 1, high scores, demo 2, demo 3 | 47 |
| `GalaxyHelp` (E7) | `Keen4Help`, `Keen4Episode.page_layout` | The help menu and the topics' pages; the page layout with or without the frame | 139 |
| `GalaxyEnding` (E7) | `Keen4Ending` | The end pages of a given text, the blinking arrow | 110 |
| `GalaxyHighScoreBoard` (E7) | `Keen4HighScoreBoard`, `Keen4FrontScreen.default_high_scores` | The table XORed over the map by the rules' margins and colour, the extra column only with a tile; typing a name; the program's default table | 235 |
| `GalaxyCheats` (E7) | `Keen4Cheats` | E+N+D and B+A+T (the episode adds its gifts) | 56 |
| `GalaxyScene` (E7) | — | A full-screen scene on the clock: advance, press, screen, fade level; since E8 its sounds and songs through two Callables | 54 |
| `GalaxyAudio` (E8) | `Keen4Audio` | The sounds and music on `GalaxySoundPlayer`: names, counts and the song per map from the rules, the cache in the episode's folder, the settings, Shift+S / Shift+M, `remaining_tics()` (SD_WaitSoundDone) | 97 |
| `GalaxySettings` (E8) | `Keen4Settings` | The episode's own settings (quiet AdLib, score box) in `settings_path()` | 46 |
| `GalaxyMenuScreen` (E9) | `Keen4MenuScreen`, `GalaxyFrontScreen`'s help and new game | The control panel between the front screen and the view: the cards and their choices, new game on a difficulty, load, save, End Game, Paddle War on its own tics, Sound/Music/score box settings, F1 over a card, the frames of a level kept for a save, a loaded level played again | 513 |
| `GalaxySavedGame` (E9) | `Keen4SavedGame` | A saved game: difficulty, inventory, progress, map; in a level the random start and the frames (keys, tics, events); the replay; the episode's inventory, progress and gifts as hooks | 299 |

The chain is `GameScreen` → `GalaxyLevelScreen` → `GalaxyPlayScreen` →
`GalaxyFlowScreen` (E6) → `GalaxyFrontScreen` (E7) → `GalaxyMenuScreen`
(E9) → the episode's view (`Keen5View`). When the co-op and online
screens are lifted (E11), they go between `GalaxyMenuScreen` and the view (Keen 4's chain
has the flow in its view; here it comes first, so the front screen
overrides its hooks such as `_game_ended`), and the view's parent moves
up.

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
| `map_flag_offset`, `throws_map_flag`, `map_flag_throw_offset` (E6) | (−0x50, −0x1E0), false, — | The done levels' flags on the world map (Keen 4: (0x60, −0x1E0), thrown to (0x60, −0x260)) |
| `menu_font`, `status_texts`, `game_texts` (E6) | 0, "status", "game" | The windows' font and the runs of texts the boxes and the status window read |
| `game_over_text`, `demo_text`, `try_again_intro_text`, `try_again_text`, `exit_text`, `one_moment_text` (E6) | −1 (none), 1, 6, 7, 8, 11 | Which text of the game run is which (Keen 4: 0, 3, 7, 8, 9, 12) |
| `countdown_from_end` (E6) | 7 | Keen counting down, from the end of the picture range (Keen 4: 6) |
| `cheat_texts` (E7) | "cheat" | The run whose first text is B+A+T's box |
| `title_from_end`, `story_from_end`, `first_credit_from_end`, `credit_count`, `left_word_misc`, `right_word_misc`, `story_font`, `story_messages` (E7) | 11, 12, 16, 4, 1, 2, 2, "story" | The title loop's pictures and texts (Keen 4: 12, 13, 17) |
| `intro_word_colors`, `story_colors` (E7) | red / light red; [0,1,8,14,15,12,6,7, 11 × 8] | The intro's words alone and over each other, the story picture's palette (empty: Keen 4's grey words and palette) |
| `demo_sign_sprite` (E7) | 5 | The DEMO sign |
| `high_score_map`, `high_score_demo`, `high_score_count`, `high_score_offsets` (E7) | 15, 4, 8, [0x33D56] | The high scores and the program's default table |
| `high_score_top`, `_left`, `_right`, `_color`, `_icon_tile` (E7) | 0x23, 0x28, 0x118, 12, −1 | The table's margins, XOR colour and extra column (Keen 4: 0x33, 0x18, 0x128, 15, tile 71) |
| `help_menu_picture`, `help_pointer_picture`, `help_topic_texts`, `page_frame_picture` (E7) | 0, 18, [0,1,2,6,3], 22 | The help (Keen 4: 0, 39, [0,2,1,6,3], 74) |
| `end_text`, `secret_end_text`, `arrow_dim_picture`, `arrow_bright_picture` (E7) | 4, 5, 20, 21 | The end pages (Keen 4: 4, none, 41, 42) |
| `story_song`, `ending_song`, `game_over_song`, `help_song` (E7) | 17, 14, 18, 19 | The **maps** whose songs the story, the end, game over and the help play (Omni StartMusic takes a map; Keen 4: 12, 7, none, none) |
| `sound_count`, `song_count`, `sound_names`, `map_songs` (E8) | 64, 14, `Keen5Sounds.NUMBERS`, `Keen5Sounds.MAP_SONGS` | The audio file's layout, the sounds by name, the song of maps 0-19 (Keen 4: 52, 6) |
| `sound_cache_folder()`, `settings_path()` (E8) | `user://keen5/cache`, `user://keen5/settings.cfg` | From `user_folder`: never Keen 4's |
| `menu_cards_from_end`, `watch_from_end`, `paddle_war_from_end`, `menu_cards(count)` (E9) | MAIN 32, NEW GAME 31, LOAD 30, SAVE 29, CONFIGURE 28, SOUND 27, MUSIC 26, BUTTON SETUP 23, OPTIONS 21; 17; 20 | The control panel's pictures (Keen 4's by default: one more each) |
| `save_slot_count`, `saves_folder()` (E9) | 6, `user://keen5/saves` | The saved games, never in Keen 4's folder (`GalaxySaveSlots`' default) |

### The hooks (virtual methods that do nothing or Keen 4's thing by default)

| Where | Hook | Default | Keen 5 |
|---|---|---|---|
| `GalaxyLevelSession` | `_new_keen()` | a `GalaxyKeen` | `Keen5Keen` (`Keen5LevelSession`) |
| | `_set_up_keen(walker)` | easy jumps on Easy | — (Keen 4 would show the moon) |
| | `_place_info(info, cell)` | nothing | creatures and platforms from E4/E5 |
| `GalaxyPlayScreen` | `_new_inventory()` | a `GalaxyInventory` with the rules' numbers | `Keen5Inventory` |
| | `_new_session(map, number, random_start)` | a `GalaxyLevelSession` | `Keen5LevelSession` |
| | `_play_sound(name, interrupt)`, `_play_map_song(map)`, `_stop_music()` (E8) | `GalaxyAudio` (E8; silent before) | — |
| | `_after_frame()`, `_waiting(tics)`, `_frame_input(tics)`, `_partner_input()`, `_wide_view_changed(width)`, `_partner_view_width(width)` | as Keen 4's | `Keen5View._after_frame`: the next level, a death |
| `GalaxyKeenBody` (engine, additive) | `_action_rows()`, `_item_rows()`, `item_sounds` | Keen 4's rows and twelve sounds | Keen 5's rows without the moon and with `enter_security_door`, `entered_door`; four splash pictures; the keycard's sound |
| | `_touch_other_tile(cell, kind)` | nothing | — (no Keen 5 tile acts on touch) |
| `GalaxyKeen` (engine, additive) | `spawn(..., keen)` | a new `GalaxyKeen` | a `Keen5Keen` |
| `GalaxyPlayScreen` (E6) | `_hold_frame(tics)` | nothing | — (`GalaxyFlowScreen`: the status window holds the game) |
| `GalaxyFlowScreen` (E6) | `_new_progress()`, `_new_status_window()`, `_new_map_session(map, random_start)` | the Galaxy classes | `Keen5Progress`, `Keen5StatusWindow`, `Keen5MapSession` |
| | `_loading_box(number)` | the map's "Keen ..." box | the Korath III arrival's box on the map |
| | `_done_value(finished)`, `_after_level_done(finished)` | 1; the exit sound and the map | `result()` (1, 14, 15); the fuse message, Korath III, the QED |
| | `_after_map_frame()`, `_after_level_frame()` | an entrance; done or lost | — |
| | `_game_over()`, `_game_ended()` | "Game Over!" if the episode has it; the start screen | — (E7: the galaxy explodes) |
| | `_status_map()` | the map played | level 13 on Korath III |
| `GalaxyMapSession` (E6) | `_new_keen()`, `_keen_place(start, progress)` | a `GalaxyMapKeen`; where he entered or info 3 | `Keen5MapKeen`; info 26 after the Korath door |
| | `_place_extras(progress)`, `_runs_own_frame(tics, tic)`, `_after_world_frame()` | nothing | the shafts and the filler; the rides |
| `GalaxyProgress` (E6) | `map_shown()`, `_extra_to_dictionary()`, `_extra_from_dictionary(saved)` | the level just finished is used up; nothing | the Korath arrival is used up |
| `GalaxyStatusWindow` (E6) | `_draw_middle(...)`, `_draw_bottom(...)`, `key_tiles_at` | nothing; Keen 4's (160, 140) | KEYCARD; (120, 140) |
| `GalaxyFrontScreen` (E7) | the screens' songs (E8: through the play screen's `_play_map_song` with the rules' maps; E7's `_play_song` is gone) | — | — |
| | `_high_score_count()` | 0 | — (Keen 4 would give the rescued members) |
| | `_cheat_end()`, `_give_items()` | nothing; gems, 99 charges, a life | the end pages; the keycard too |
| | `_game_ended()` (overrides the flow's) | the name on the table or the high scores, then the title loop | — |
| `GalaxyFlowScreen` | `_game_over()` | "Game Over!" or `_game_ended` | the exploding galaxy (`Keen5GalaxyExplosion` as a `GalaxyScene`) |
| `GalaxyMapFlag` (engine, additive, E6) | `wave_at(..., waving_only)` | false: all of Keen 4's actions | true: only the waving ones (Keen 5 has no flipping sprites) |
| | `_is_door(kind)`, `_enter_door(kind)` | misc 2; the normal door | misc 32 too; the keycard and the door opener |
| `GalaxyFlowScreen` (E9) | `_level_began(number, random_start)` | nothing | — (`GalaxyMenuScreen` starts keeping the level's frames) |
| `GalaxyFrontScreen` (E9) | `_title_loop_key(event)` | Escape: the start screen | — (`GalaxyMenuScreen`: any key opens the panel) |
| `GalaxyMenuScreen` (E9) | `_new_panel()`, `_new_saved_game()`, `_panel_waits()` | a `GalaxyMenuController`; a `GalaxySavedGame`; never | —; `Keen5SavedGame`; a ride on the world map |
| `GalaxySavedGame` (E9) | `_new_inventory()`, `_new_progress()`, `_extra_inventory_to_dictionary(carried)`, `_extra_inventory_from_dictionary(carried, saved)`, `give_items(carried)`, `give_everything(carried)` | the rules' inventory; `GalaxyProgress`; nothing; B+A+T's and Shift+I's gifts | `Keen5Inventory` (keycard, fuses), `Keen5Progress` (Korath arrival), the keycard with each gift |

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

## Keen 5's machinery (from E5)

The platforms, the fuses and the QED, each a class of its own beside the
creatures; the rules are in [gameplay.md](gameplay.md), "Platforms" and
"Fuses and the QED".

| Class | What | Lines |
|---|---|---|
| `Keen5Platforms` | Info value → platform (27-30, 32-40, 80-87), the standing platform's reversed difficulty; called by `Keen5LevelSession._place_info` beside `Keen5Creatures` (which still writes a GoPlat's start arrow) | 72 |
| `Keen5Platform` | The red and purple axis platforms (on `GalaxyPlatform`; the purple one overrides `_turn_point_entered` to look one column further going up or down) | 69 |
| `Keen5GoPlat` | The red and purple GoPlats (on `GalaxyPlatform` for riding, moving by `GalaxyPathArrows`) | 62 |
| `Keen5StillPlatform` | The standing and the sneak platform | 79 |
| `Keen5Flash` | Pictures that only show: a fuse's explosion, the teleport lightning | 70 |
| `Keen5Fuses` | The fuse rules (static): counting info 41 (the QED on map 12), breaking a fuse; the sound names with their numbers for E8 | 73 |
| `Keen5Qed` | The QED: a fixed unseen box; a mine's piece calls `hit_by_piece` | 72 |
| `Keen5LevelEnd` | Ends the level 60 tics after the last fuse or the QED (`&"fuse"`, `&"qed"`) | 34 |
| `Keen5Messages` | The fuse message's two screens (`GalaxyWindow`, Keen 4's layout of "I can't swim!") | 58 |

`Keen5Keen` gained the surfing action (`ride_platform`), the fuse landing
(`_react_jump`, `_react_pogo`), the arrow-turning switch (`_switched_info`)
and the lightning at a door (`_enter_door`). `Keen5Inventory` holds
`fuses_remaining`, `Keen5LevelSession` gives `result()` (1, 14, 15) and
`fuses_remaining()`, `Keen5View` keeps `levels_done` and shows the fuse
message.

## Deviations in E5

What E5 built differently from the plan above, and why (developer, E5):

1. **One engine seam only**: `GalaxyKeen._switched_info(value)` (default:
   the B-block toggle `value ^ 0x1F`, the statement it replaces), so Keen
   5's switch can turn a path arrow round. Everything else is Keen 5's
   own: `Keen5Keen` overrides Keen's private `_think_standing`,
   `_handle_ground_input`, `_react_jump` and `_react_pogo` (calling the
   shared code), `Keen5Platform` overrides `GalaxyPlatform._turn_point_entered`.
   Keen 4's demo suite, real-data suites and regression pictures are
   unchanged.
2. **The red GoPlat reads its arrow at its position, the purple one 0x40
   further** (Omni CK_GoPlatThink, CK5_PurpleGoPlatThink), not both at
   +0x40 as research.md §7 said: the purple one is placed 0x40 into its
   tile, so both read the arrows of the tile they are in.
3. **The fuse count is Keen's** (`Keen5Inventory.fuses_remaining`), not a
   field of a `Keen5Fuses` object: it is game state (saved with the game,
   Omni ck_gameState), and Keen breaking a fuse reaches it through his
   inventory. `Keen5Fuses` holds only static rules. The session sets it to
   0 before the scan; a loaded game's value wins in E9.
4. **The fuse message comes at once after the level**: the original first
   waits for the level-exit sound to end (about 2.3 s, Omni
   SD_WaitSoundDone; seen in js-dos). With no sounds yet (E8) there is
   nothing to wait for; E8 should add the wait.
5. **The QED's end goes to the next level for now** (the end pages are
   E7), and the door to Korath III ends the level as in E3 (the arrival on
   the map is E6). Each level's result is kept in `Keen5View.levels_done`
   for E6's `Keen5Progress`.
6. **The teleport lightning came in E5** (E3 had left it for E6), because
   the maps answered which door shows it: only the 0x0000 door of level 11.
7. **The sneak platform watches both Keens** when two play (ours); alone
   it is the original's rule.
8. **`Keen5Creatures.LATER` is only [3, 26]** now, the platforms are
   `Keen5Platforms.is_platform` and 41 is `Keen5Fuses.COUNTER_INFO`;
   `test_keen5_creatures_play` asks all three.
9. **The QED's action has no speed**: Omni gives CK5_ACT_QED 128 across,
   which moves nothing because the object has no facing; it is left out.

## Keen 5's world map (from E6)

| Class | What | Lines |
|---|---|---|
| `Keen5MapSession` | The Omegamatic on `GalaxyMapSession`: Keen 5's map Keen, the Korath III arrival (info 26), the shafts by Keen's row, the yellow filler drawn as space, the rides that hold the game | 147 |
| `Keen5MapKeen` | The map Keen on `GalaxyMapKeen`: the tile under him asks for a teleporter or an elevator half (`_touch_tiles`), the unseen flight in the elevator (`_think_elevator`) | 133 |
| `Keen5MapRide` | The parts of a ride during which the original runs its own loop: the walk onto the tile, the flashing bolt and the jump, the walk out, the door closing and opening from the template | 282 |
| `Keen5Progress` | `GalaxyProgress` with 14 for a fuse, the four shaft fuses, the Korath III fuse, the arrival on Korath III | 41 |
| `Keen5StatusWindow` | `GalaxyStatusWindow` with KEYCARD and the key tiles at (120, 140) | 35 |

`Keen5View` now extends `GalaxyFlowScreen` and keeps only what Keen 5
does: the new game on the map, the Korath III box and location, the fuse
message, the QED's end (the start screen until E7), the cheats.

## Deviations in E6

What E6 built differently from the plan above, and why (developer, E6):

1. **A sixth class in the chain, `GalaxyFlowScreen`**, between
   `GalaxyPlayScreen` and the view. The flow (Keen 4's view), the status
   window (Keen 4's play screen) and the loading box (Keen 4's front
   screen) together would have made `GalaxyPlayScreen` far over 500 lines;
   the play screen only learnt to play the world map. The later front,
   menu, co-op and online screens go between the flow screen and the view
   and override its hooks (`_game_ended`, `_level_began` when it comes).
2. **Keen 5's boxes are no class of their own**: `GalaxyGameBoxes` takes
   the texts' numbers, the font and the count-down's place from the rules,
   and `loading(text)` makes the Korath III box. Keen 4's "I can't swim!"
   box stays Keen 4's.
3. **The rides are a class of their own (`Keen5MapRide`)** that the
   session runs instead of the world's frame (the hook
   `_runs_own_frame`), because the original stops the game in loops of
   its own there (nothing else moves, flags stand still). The elevator's
   flight in between is an ordinary action of the map Keen (the original's
   too), so the flags wave and the view follows.
4. **Keen is clipped after the elevator only when the ride is over**, as
   the original does after its loop: clipped at once, the closed door
   above the target pushed him up two tiles (found by the real-data test).
   The view follows the flight's last box once more on arrival (Omni
   CK_MapCamera in CK5_MapKeenElevator).
5. **The KEYCARD row is a pixel lower than Omnispeak's numbers** (label
   (80, 92), square (135, 91), card (136, 92)): compared with the
   original's window to the pixel. On Korath III the window names Korath
   III's base (seen in the original; Omnispeak names the map), through
   the hook `_status_map`.
6. **The yellow block in widescreen (E3's open point)** was not the
   cover: map 0 is filled with an all-yellow background tile (850) where
   the original's view never comes. `Keen5MapSession` draws it as black
   space (tile 0) above row 100 (Korath III's yellow ground stays); 4:3
   never shows those cells, so the original's picture is unchanged.
7. **The teleporter's target row is the low byte & 0x7F**, as the
   original (Omnispeak masks 0xFF and notes the 0x7F of the disassembly);
   both agree on the real map.
8. **The QED's end goes to the start screen** (not back to the map): the
   original's end pages and high scores follow it (E7), and the map would
   let the game go on after it was won. Game over goes to the start
   screen too (E7: the galaxy explodes). The level-exit sound and the
   status sounds are asked for by name (`_play_sound`), silent until E8.
9. **One engine change**: `GalaxyMapFlag.wave_at` got an optional
   `waving_only` (default false: Keen 4's flags are unchanged); Keen 5 has
   no flipping or falling flag sprites, which the full action table asks
   for. Keen 4's demo suite, real-data suites and 11 regression pictures
   are unchanged.

## Keen 5's front (from E7)

| Class | What | Lines |
|---|---|---|
| `Keen5View` | Now on `GalaxyFrontScreen`: starts with the title loop, the QED's end and E+N+D lead to the end pages (`end_text()`: the secret end after Korath III's fuse), game over to the exploding galaxy, B+A+T adds the keycard, `--random-seed=N` | 274 |
| `Keen5GalaxyExplosion` | Game over (`GalaxyScene`): the fades by the EGA palettes, the Milky Way flashing its entries 7 and 8, 60 frames of 4000 stars from the misc chunk GALAXY, GAMEOVER 24 s or a key | 287 |
| `GalaxyEgaFade` (`src/galaxy/ui/`, new) | The original's four fade palettes as a shader over the picture | 72 |

## Deviations in E7

What E7 built differently from the plan above, and why (developer, E7):

1. **`GalaxyFrontScreen` is 625 lines** (Keen 4's front screen 502): it
   also holds what Keen 4 has in its view (the cheats, F1 and the boxes
   that hold it) and the scenes. It is one job (what is shown between
   the games); E9's menu screen takes the menu part, so it was left whole.
2. **A scene class of its own (`GalaxyScene`)** for game over instead of
   Keen 4's "Game Over!" box: the front screen runs it on the clock like
   the end pages, so Keen 6's end and any later scene plug in the same way.
3. **The fades of the scene are the EGA palettes**, not a brightness: the
   original's fade levels make the dark colours black first and the bright
   ones their dark twins (seen to the pixel in the galaxy's fade-in).
   `GalaxyEgaFade` is a shader on a rectangle over the picture; the flow's
   other fades (the loading box) keep their brightness steps from D7.
4. **Five engine seams, all neutral for Keen 4** (its demo suite,
   real-data suites and 11 regression pictures are unchanged), found by
   laying the original's demo frames on ours: `GalaxyWorld.shared_step`
   (the original's one step variable, written by every action, a ride, a
   push or a started action) and `shared_landing_step` (Keen 5 on: landing
   on a platform also moves Keen across by it, Omni CK_PhysPushY sets only
   ck_nextY); `GalaxyPlatform.bounce` (Keen 5's axis platforms and
   Slicestars stop on the tile's edge, as Omnispeak; Keen 4 v1.0 was seen
   to bounce back in D13); `GalaxyObjectLayer.original_order` (an asleep
   or hidden object loses its place among the sprites of its priority, a
   changed priority goes under; the Galaxy play screen also draws all
   sprites anew at a map's first frame); `GalaxyShrapnel` keeps a spent
   piece one frame (only Keen 5 uses it). `Keen5Keen._shove` (pushed by an
   Ampton or a Korath) takes the shared step's y, as Omni CK_PhysPushX.
5. **Two facts differ from Omnispeak**: the flash gives entry 7 the
   table's second row and entry 8 its first (Omnispeak both the first),
   and a star exactly on the right edge shows at the left of the next row.
   Palette value 0x0F shows light grey (the 200-line EGA ignores bit 3).
6. **A key in the title loop starts a new game** (Keen 4 before D10); the
   original opens the control panel, which E9 brings. F1 opens the help in
   the title loop and in a game, Shift+F1 the help line.
7. **The regression pictures are repeatable**: `Keen5View` seeds Godot's
   random numbers from `--random-seed=N`; the shared random table of the
   demos already starts at 0.
8. **Not done**: the original's loading pauses (1.5 s black before the
   galaxy, 2.5 s before the end pages in js-dos, machine dependent), the
   original's random fizzle order of the title (ours is fixed, as Keen
   4's), sound (E8).

## Keen 5's sound (from E8)

| Class | What | Lines |
|---|---|---|
| `Keen5Sounds` | The 64 sound names with Keen 5's numbers (Omni `EPISODE.CK5`, CG's names where Omni says UNKNOWN), the 14 songs, the song of maps 0-19 (Omni CK_LevelMusic) and the maps of the screens' songs (14, 17, 18, 19) | 114 |

`GalaxyPlayScreen` owns a `GalaxyAudio` (as `Keen4PlayScreen` its
`Keen4Audio`): `_play_sound` plays by name, `_play_map_song(map)` starts a
map's song, `_stop_music()` stops it. Which song plays where
(gameplay.md, "Sound and music"):

| Where | Song (map) | Code |
|---|---|---|
| A map played (levels, the world map, demos, the high-score demo) | its own | `GalaxyPlayScreen._start_playing` |
| The play of a map ends (a level done, a death, an entrance taken, a demo over) | none (Omni CK_PlayLoop ends with StopMusic) | `GalaxyFlowScreen._finish_level`, `_lose_level`, `_after_map_frame`, `GalaxyFrontScreen._end_demo` |
| A map only looked at; the name typed in on map 15 | none | `GalaxyPlayScreen._look_at`, `GalaxyFrontScreen._begin_name_entry` |
| The story / the end pages / the help | 17 / 14 / 19, the help stops it on leaving and a game's map starts its own again | `GalaxyFrontScreen` |
| Game over | 54 at the flashing, 53 at the stars, map 18's song with GAMEOVER, stopped at its end | `Keen5GalaxyExplosion._stage_began` |
| The fuse message | waits for the exit sound (`remaining_tics()`) | `Keen5View._show_fuse_message` |

## Deviations in E8

What E8 built differently from the plan above, and why (developer, E8):

1. **The audio lives in `GalaxyPlayScreen`**, not behind silent hooks the
   view fills: `GalaxyAudio` is generic (everything episode-specific comes
   from the rules), so the hooks `_play_sound`, `_play_map_song` and the
   new `_stop_music` call it directly; `GalaxyFrontScreen._play_song` (E7)
   was removed, the screens name a map by the rules. An episode can still
   override the hooks.
2. **The rules' screen songs are maps, not songs**: Omni StartMusic takes
   a map and looks its song up in CK_LevelMusic, whose entries 14 and
   16-19 name no map but the end, an unused song, the story, game over and
   the help. research.md §9's "the song is the map number" means exactly
   that; its "Song" column is the song (chunk 192 + song).
3. **The music stops whenever the play of a map ends**, so the boxes
   between the maps (One moment, Keen enters, the death box, the fuse
   message) are silent and the next map starts its song from the start:
   Omni CK_PlayLoop ends with StopMusic, and js-dos shows it (the map's
   song stops at the warp, the loading box is silent, level 1's song
   starts with the level; after the fuse message the map's box is silent).
   Keen 4 (D9) keeps the old song through the box; Keen 4 is frozen, so it
   stays so there.
4. **The name entry is silent**: the original only loads map 15 for the
   table (CK_SubmitHighScore: CK_LoadLevel, no play loop); ours plays the
   map for its tiles and stops the song at once. The high-score demo plays
   map 15's song (Skating O'er the Ice) as every demo plays its map's.
5. **The fuse message waits as long as the sound playing still lasts**
   (`GalaxyAudio.remaining_tics()`, wall-clock as the player's own
   priority rule, rounded up to tics): a step of the queue that shows the
   frozen game and takes no key. With the sound off there is no wait, as
   SD_WaitSoundDone returns at once. E5's "about 2.3 s" was js-dos's wall
   clock; the exit sound is 1.48 s (104 tics) and in the recording it ends
   exactly where the original goes silent and shows the message.
6. **Settings as Keen 4's**: the sound device and the music are the shared
   `UserSettings` (`sound/device`, `sound/music`, one choice for Keen 4
   and 5, as the user's player expects of one program); the quiet AdLib
   sounds and the score box are the episode's own `GalaxySettings` in
   `user://keen5/settings.cfg` (Keen 4: `Keen4Settings` in
   `user://keen4/settings.cfg`). Only quiet AdLib is read now; E9's
   control panel sets both. The player's CONFIG.CK5 is never read.
7. **One engine change, additive**: `GalaxySoundLibrary.start` got an
   optional `next_songs` (default none: Keen 4's order is unchanged), so
   Keen 5 renders the world map's song, then the first demo's (map 1) and
   the story's before the rest. Measured on 4 cores into an empty cache:
   all AdLib sounds 1.2 s, the map's song 9.7 s, every song 112 s (one at
   a time; 85 MB); from the cache 0.4 s. Without the order, demo 0's song
   would have come after 54 s, past the 38 s intro.
8. **The provisional sound tables of E4-E6** (`Keen5Creatures.SOUNDS`,
   `Keen5Fuses.SOUNDS`, `Keen5MapSession.SOUNDS`) were removed:
   `Keen5Sounds.NUMBERS` is the one table, and `test_keen5_sound` scans
   the sources of `src/galaxy` and `src/keen5` so every name played has a
   number.
9. **`GalaxyScene` got two Callables** (`sound_player`, `song_player`)
   that the front screen sets, so a scene asks for its sounds by name like
   a world does.

## Keen 5's control panel (from E9)

| Class | What | Lines |
|---|---|---|
| `Keen5SavedGame` | `GalaxySavedGame` with Keen 5's inventory (the keycard, the fuses still to break) and progress (the Korath III arrival, via `Keen5Progress._extra_to_dictionary`), the keycard with B+A+T and Shift+I among the frames | 45 |

`Keen5View` now extends `GalaxyMenuScreen`: `_set_up_panel()` in `_ready`,
Escape opens the panel (`_escape()`), `_new_saved_game()` gives a
`Keen5SavedGame`, `_panel_waits()` holds Escape during a ride on the
world map, god mode and Shift+I are recorded among a level's frames.
`Keen5Episode` has the cards' numbers (`MENU_CARDS_FROM_END`,
`WATCH_FROM_END`, `PADDLE_WAR_FROM_END`). The rules are in
[gameplay.md](gameplay.md), "The control panel", "Saving and loading".

## Deviations in E9

What E9 built differently from the plan above, and why (developer, E9):

1. **The help and a new game moved into `GalaxyMenuScreen`** with the
   panel (the original opens the help from its cards too, and New Game is
   a card): `GalaxyFrontScreen` went from 625 to 535 lines, the menu screen
   is 513. Both stay a little over ~500; what is left in the front screen
   is one job (the title loop, the demos, the end, a scene, the name, the
   cheats), so it was not split further. The front screen's title-loop key
   became the hook `_title_loop_key` (Escape: the start screen); the menu
   screen opens the panel there.
2. **`GalaxySavedGame` is an object with hooks, not static functions**:
   Keen 4's `inventory_to_dictionary` and the replay's `_apply` were
   static on Keen 4's classes; the generic game needs the episode's
   inventory, progress and gifts, so the saved game is made per episode
   (`_new_saved_game()`) and the replay holds it. The format (keys, frame
   bytes, event numbers) is Keen 4's, the folder Keen 5's.
3. **A loaded level is played again silently and without the god mode of
   now** (Keen 4 plays the frames with the world's sounds on and the
   screen's god mode): the replay's sounds would all play at once, and a
   god mode switched on since the save would change what the frames give.
   After the replay god mode is what the frames left.
4. **Escape waits while a ride holds the world map** (a teleporter, an
   elevator's door, the unseen flight in the elevator; `_panel_waits()`):
   a map save keeps only Keen's place, which in a ride is no place to
   stand. The original's own ride loops take no key; during the flight the
   original could save, ours cannot.
5. **One new hook in the flow screen**, `_level_began(number,
   random_start)` (Keen 4's view called it from its own `_show_level`).
6. **No change in `src/galaxy/` outside `game/`**: `GalaxySaveSlots`
   keeps its Keen 4 default; Keen 5 always passes `rules.saves_folder()` (`test_galaxy_game_saved` scans `src/keen5` and
   `src/galaxy/game` for `user://keen4`, `test_keen5_menus` checks that
   nothing in `user://keen4` changed while it saved, loaded and set).
7. **The panel controller is the plain `GalaxyMenuController`**, not
   Keen 4's `GalaxyCoopMenuController`: co-op and online come in E11
   (`_new_panel()` is where E11 gives its own).
8. **Configure is Keen 4's** (Sound, Music, Options, Keyboard, Reset
   Keys), not the original's joystick and Gravis rows, and the quit
   question has the Choose Game line: the two cards that differ from v1.4
   in the js-dos comparison, both as decided for Keen 4.
9. **A map save restarts the animated tiles** (the rocket's flame):
   the place is kept, not the animation's phase (as Keen 4's D10); a level
   save comes back to the pixel.

