# Keen 4: architecture

How Keen 4 ("Secret of the Oracle") is added beside Keen 1, 2 and 3.
Written in milestone D1 by the architect, with a code survey by the
developer; the developer follows it in D2 and later and updates it when a
decision changes (with the reason). The milestones are in
[roadmap.md](roadmap.md), the facts about the game in
[research.md](research.md), the file formats in
[file-formats.md](file-formats.md). Read
[../keen2/architecture.md](../keen2/architecture.md) and (on the Keen 3
branches) `docs/keen3/architecture.md` first: the rules there still hold,
but Keen 4 needs more than they describe.

## What is different this time

Keen 2 and Keen 3 were **the same engine** as Keen 1 with other enemies.
Keen 4 is **another engine** (id's "Galaxy" engine, also used by Keen 5 and
6). From the code survey in D1:

| Part | Keen 1-3 code | For Keen 4 |
|---|---|---|
| Graphics files | `EgaHeader`, `EgaGraphics` (EGAHEAD/LATCH/SPRIT) | New: Huffman, the headers in the EXE, chunks, two 16×16 tile sets, 8×8 tiles, proportional fonts |
| Levels | `LevelData`, `RlewDecompressor` (tag 0xFEFE fixed), one file per level, two planes | New: `GAMEMAPS` + `MAPHEAD`, Carmack + RLEW (tag 0xABCD), three planes |
| Tile behaviour | `TileProperties` (six words per tile, behaviours up to 28) | New: `TILEINFO` (slopes, poles, ledges, deadly, front/back, animation timing) |
| Drawing a level | `LevelMap` (one tile plane; foreground and masked tiles from the property table) | New map class with three layers; reuse the pattern (`TileMapLayer`, `set_tile` per cell, one atlas) |
| Keen and physics | `KeenBody`, `LevelCollision` (boxes only, 60 Hz, 1/32 px) | New: slopes, poles, ledges, swimming; the original's units and tics |
| Enemies | `Actor`, `Enemy`, Keen 2/3 subclasses | New: an action (state) machine like the original's; `Actor` and `ActorLayer` can still carry position and sprite |
| World map | `MapSession`, `MapKeen` (a tile map with its own rules) | New: the world map is a level (map 0) with a Keen that walks in 8 directions |
| Sound | `SpeakerSynth` (square wave at 140 steps/s), `SoundFile` | PC speaker: reuse `SpeakerSynth` with a converter. **New: an OPL2 (AdLib) synthesiser** for AdLib sounds and music |
| Windows, HUD, font | `GameWindow`, `Hud`, 8×8 font | New look (Galaxy windows, proportional font, the score box) |
| Menus | `Menu`, `MenuController` (logic) | Logic reused; a Galaxy-looking view |
| Launcher, settings, saves, scaling, online transport, two-player view, tools | shared | Reused, with a few additive seams (below) |

So the rule from Keen 2 and 3 ("subclass the older episode") does **not**
carry over for the game itself. Subclassing `KeenBody`, `LevelCollision` or
`LevelSession` would drag Vorticon rules into Keen 4; Keen 3 already showed
that three levels of inheritance become brittle (`Keen3Ball` copies lines
because it cannot extend two classes). Keen 4 is built as a **new tree that
only uses the generic shared pieces**.

## The rule: Keen 1, 2 and 3 stay as they are

| Group | What | Allowed changes |
|---|---|---|
| **Keen 1 only** | As in `docs/keen2/architecture.md` | **None.** |
| **Keen 2 only** | `src/keen2/**`, its tests and fixtures | **None.** |
| **Keen 3 only** | `src/keen3/**`, its tests and fixtures (on the C branches until merged) | **None.** Keen 3 is still being built by another session: Keen 4 never touches it, not even in a merge (see "Branches") |
| **Shared** | Decoders, graphics and scaling, `src/level/`, `src/keen/`, `src/sound/`, `src/menu/`, `src/online/`, `src/launcher/`, `GameScreen`, `LevelSession`, `Hud`, settings, saves, high scores, tools | **Only additive, behaviour-neutral changes** (a new optional parameter whose default is the old value, a new method or constant, an enum value at the end, an entry in a list of games) |
| **Galaxy** (new) | `src/galaxy/**`: what Keen 5 and 6 will need too | Free during the D milestones. After Keen 4 is done it becomes **shared** for Keen 5 and 6 |
| **Keen 4 only** (new) | `src/keen4/**` | Free |

Exceptions, as for Keen 3 (decided by the architect, to be confirmed by the
user):

1. **The list of games**: the assertions on the number of games
   (`tests/test_launcher.gd`, `tests/test_keen2_files.gd`,
   `tests/test_keen3_files.gd`) grow by one.
2. **`GameLaunch.game_number`/`scene_for`, the data viewer and
   `tools/export_graphics.gd`** may change their bodies to know a fourth
   game, as long as every argument list that worked before gives the same
   answer.
3. **The launcher icon** (below): `GameCatalog.Game` gets an optional way to
   make its own icon picture; without it the launcher does what it does now.

Proof at the end of every D milestone, as in the C series:

1. Every existing test passes without changes to the test files (except
   exception 1); new suites may be added.
2. `gdlint` is clean.
3. `tools/keen1_regression.sh` and `tools/keen2_regression.sh` (and, once it
   exists, the Keen 3 one) give the same screenshots as the reference;
   only `launcher.png` may differ, by the new icon.
4. `git diff $REF -- <Keen 1 only files> src/keen2 src/keen3 tests/test_keen2_*.gd tests/test_keen3_*.gd`
   is empty (apart from exception 1).

`$REF` is the commit the D branch started from (see "Branches").

## Two new folders: `src/galaxy/` and `src/keen4/`

Keen 5 and 6 use the same engine as Keen 4. Everything that is "the Galaxy
engine" goes into `src/galaxy/` with class names starting with `Galaxy`;
everything that is "the game Keen 4" goes into `src/keen4/` with class
names starting with `Keen4`. A rule of thumb: if Keen 5 would need the same
class with other numbers, it is Galaxy, and the numbers are passed in (an
episode table), not written as constants in the class.

```
src/galaxy/                 the Galaxy engine (class names Galaxy...)
  data/                     GalaxyExecutable (finds the headers in the EXE by content),
                            GalaxyHuffman, GalaxyCarmack, GalaxyRlew,
                            GalaxyGraphicsFile (EGAGRAPH chunks), GalaxyGraphics (the
                            decoded pictures, sprites, tiles, fonts, texts),
                            GalaxySpriteInfo (origin, hit box), GalaxyMapFile (GAMEMAPS),
                            GalaxyMap (three planes), GalaxyTileInfo, GalaxyAudioFile,
                            GalaxyTextPages (the ^P/^G mark-up)
  level/                    GalaxyLevelMap (TileMapLayers: back, fore, fore-in-front),
                            GalaxyTileAnimator, GalaxyCamera rules (scroll blocks)
  physics/                  GalaxyUnits, GalaxyClip (tile collision with slopes),
                            GalaxyPhysics (gravity, friction helpers)
  actors/                   GalaxyAction (one state: sprites, tics, velocity, think,
                            react, contact, next), GalaxyObject (position in global
                            units, box, action, timers), GalaxyObjectLayer (drawing,
                            with Interpolation), GalaxyWorld (the object list, spawning,
                            the active area)
  keen/                     GalaxyKeen (the player's states that 4-6 share: walk,
                            jump, pogo, poles, ledges, shoot, doors), GalaxyMapKeen
  sound/                    GalaxyPcSound (bytes → SpeakerSynth), GalaxyOpl (OPL2
                            synthesiser), GalaxyAdlibSound, GalaxyMusic (IMF at 560 Hz),
                            GalaxySoundCache
  ui/                       GalaxyFont, GalaxyWindow, GalaxyScoreBox, GalaxyMenuView,
                            GalaxyTextScreen (help, story)
src/keen4/                  Keen 4 only (class names Keen4...)
  data/                     Keen4Files, Keen4Episode (the numbers of episode 4: chunk
                            ranges, sprite numbers, sounds, music per level, strings)
  actors/                   Keen4Slug, Keen4Mushroom, Keen4Lick, ... (one file per enemy)
  level/                    Keen4LevelSession, Keen4Items, Keen4Council (the elders),
                            Keen4Platforms, Keen4Switches
  map/                      Keen4MapSession (entrances, flags, Miragia, swimming)
  game/                     Keen4Inventory, Keen4Progress, Keen4StatusScreen,
                            Keen4Ending, Keen4HighScores
  keen4_*_screen.gd         the screen chain on top of GameScreen
  keen4_view.gd/.tscn       Keen4View, the scene the start screen opens
tests/test_galaxy_*.gd, tests/test_keen4_*.gd, tests/galaxy_fixtures.gd
docs/keen4/
assets/backgrounds/keen4/   pictures behind levels (our own pictures only)
```

The list is a plan; the developer may split or merge classes and writes the
change down here. Keep every file under ~500 lines (gdlint also allows at
most 20 public methods per file).

## Reusing shared code

| Shared class | For Keen 4 | Note |
|---|---|---|
| `GameFiles.locate_in` | **Use** (`Keen4Files`, `--data-dir-keen4=`) | `level_file(n)` does not apply (one `GAMEMAPS` file) |
| `DosExecutable`, `LzexeDecompressor` | **Use** | v1.4 is not packed; other releases may be |
| `EgaPalette`, `EgaPlanarDecoder` | **Use** | Galaxy stores planes one after another; check the plane order in D2 |
| `XbrzScaler.scale`, `GraphicsLoader` threading, the shaders | **Use** | `ScaledGraphics`/`HdPack` are typed on `EgaGraphics`: Galaxy gets its own small `GalaxyScaledGraphics` that calls `XbrzScaler` |
| `LevelCamera`, `FreeLook`, `LevelBackdrop`, `BackdropPictures` | **Use** | Scroll blocks are Keen 4's own rule on top (see "Widescreen") |
| `DisplaySettings`, `UserSettings`, `KeyBindings` | **Use** | Galaxy needs up/down in levels; see "Input" |
| `Interpolation` | **Use** | Already independent of the tick rate (`blend` 0-1) |
| `GameScreen` | **Base of the screen chain** | Finds nodes by unique name: `keen4_view.tscn` copies the node layout of `level_view.tscn`, as Keen 2 and 3 did |
| `Menu`, `MenuController` | **Use** | With a Galaxy view |
| `SaveGames.in_directory`, `HighScores` pattern | **Use** | `user://keen4/` |
| `SpeakerSynth.render` | **Use** | Galaxy PC sounds are bytes × 60 at 140 Hz: convert to divisors. If C8 changes the rate to 145.65 Hz, Galaxy needs the rate as an optional parameter (default the new rate) |
| `SplitScreen`, `TwoPlayerView`, `PartnerArrow` | **Use** (D12) | |
| Online transport and handshake | **Use** (D12) | New messages for Galaxy at the end of the enums |
| `Actor`, `ActorLayer`, `Enemy`, `KeenBody`, `LevelCollision`, `LevelSession`, `LevelMap`, `MapSession`, `Hud`, `GameWindow`, `EgaGraphics` | **Not used** | Vorticon rules (see the table above) |

## The seams in the shared code

| Need | Today | Additive change |
|---|---|---|
| Start screen icon | `GameCatalog.games()` lists three games; `Launcher._make_icon` always calls `EgaGraphics.load_from` and `KeenPhysics.SPRITE_WALK_RIGHT` | `GameCatalog.Game` gets an optional `icon_picture: Callable` (returns a `Texture2D` or null). `_make_icon` uses it when set, otherwise the old code. Keen 4 points it at a small `Keen4Icon` that decodes one sprite. The fourth icon must fit: the layout had room for three (608 of 1280 px); check `LauncherLayout` in D2 |
| `--game=4`, scene, data viewer, export | Three-way `match` | A fourth branch (exception 2). The data viewer gets a Galaxy page (tiles back/fore, sprites with their boxes, pictures, maps with the three planes); `export_graphics.gd` writes `exported/keen4/` |
| Input: up/down in levels | `KeenInput.vertical` is "only used on the world map"; `PLAYER_ACTIONS` (two players) has no up/down | One player: `KeenInput.vertical` is enough. Two players: new `p1_up`/`p1_down`/`p2_up`/`p2_down` **appended** to `PLAYER_ACTIONS`; this shows in the shared Controls menu for every game, approved by the user (19-10-2026), in D12 |
| Status key | Enter is the status key in Keen 2 and 3 | Same for Keen 4 (Enter shows the status window in the original too) |
| A different logic rate | `KeenPhysics.TICKS_PER_SECOND` = 60 is read by the Keen 1-3 views | Keen 4 has its own clock (`GalaxyClock`, see "Time"); nothing shared changes |
| Online game id | `OnlineProtocol.GAME_IDS` | `GAME_ID_KEEN_4` added at the end (D12) |
| Online snapshot | `Snapshot` sends a Keen 1 `Inventory`; the `TILE` message has one plane | Galaxy messages of its own appended to the enums (plane index, Keen 4 inventory) in D12; Keen 1-3 messages stay byte for byte the same |
| `LevelFingerprint`, `OnlinePlay._original` | `files.level_file(n)` | A Galaxy fingerprint over the map's planes (D12) |
| Build scripts | Copy `game_data/keen1..3` | Same block for `keen4` |
| Tests | `tests/run_tests.gd` | One line per new suite |
| Regression | `keen1_regression.sh`, `keen2_regression.sh` | New `tools/keen4_regression.sh` once Keen 4 draws something (D3) |

## The flow of Keen 4

```
Launcher ──click "Keen 4"──▶ keen4_view.tscn (Keen4View)
   ▲                            │ intro credits, story, demos, high scores (D8)
   │ "Choose Game"              │ main menu: New Game (Easy/Normal/Hard), Load (D10)
   └─────────────────────────── ▼
                         world map, map 0 (Keen4MapSession)
                           │ walk, swim (wetsuit), Miragia, the Foot's flight
                           │ enter level n (0xC000 + n), "Keen enters ..." box
                           ▼
                         level 1-17 (Keen4LevelSession)
                           │ out of the scroll area left/right ─▶ level done, flag thrown
                           │ council member rescued ─▶ message, level done
                           │ death ─▶ "Try Again / Exit to Shadowlands", game over
                           ▼
              8th council member ─▶ end text pages ─▶ high scores (map 19)
```

Before the map exists (D3-D6), the flow is as in B3 and C3: level 1 (or
`--level=N`), out of the level to the next one, death restarts the level,
game over goes back to the start screen.

## Branches

The user asked to branch from `main`; Keen 3 is being built at the same
time by another session on the `milestone-c*` branches.

- **D1** (this research, documents only, in `docs/keen4/`) starts from
  `main`. It changes no existing file, so it cannot conflict with Keen 3.
- **D2** is the first milestone that touches shared files (the launcher,
  `GameLaunch`, the data viewer, the build scripts, `run_tests.gd`). Keen 3
  touches the same lines (the third icon, `--game=3`). Decided by the user
  (19-10-2026): D2 starts **after Keen 3 is merged into `main`**, so Keen 4
  becomes the fourth icon on top of a finished Keen 3.
- Most of D2-D5 lives in `src/galaxy/` and `src/keen4/`; only a handful of
  shared lines change, so the merges stay small.
- `$REF` for the proof above is the commit the D branch started from.

## Time: the original's tics

Keen 1-3 run 60 logic ticks per second in 1/32 px. The Galaxy engine counts
**tics of 1/70 s** and **global units of 1/16 px**, and on any modern
machine it runs **one logic frame per 2 tics (35 per second)**; demos use 3
(research §2). Keen 4 keeps this, unconverted:

- `GalaxyClock` collects real time in tics and runs a logic frame for every
  2 tics (3 in demos), at most 5 tics' worth per frame, the way the
  original slows down rather than skipping. A frame knows the absolute tic
  numbers it covers, because gravity and acceleration act on odd tics.
- Positions, velocities, boxes and timers are integers in the original's
  units. The research's numbers go into the action tables unchanged.
- The picture: without smooth motion, objects are drawn where the last
  logic frame put them, on whole pixels (the original's 35 fps steps).
  With smooth motion (the shared option, off by default) the shared
  `Interpolation` draws between the last two logic frames, so a 120 Hz
  screen shows smooth movement.
- Sound effects (140 Hz) and music (560 Hz) are rendered to audio streams
  and are independent of the logic rate.
- The camera follows the logic frames as in the original (also drawn
  through `Interpolation` when smooth).

A "1 tic per frame" mode (70 logic frames per second) is **not** planned:
the original's ledge grabbing breaks at 1 tic (research §2).

## Drawing a level

- **Three tile layers** in one atlas each: the background (unmasked tiles,
  z below everything), the foreground (masked tiles, behind sprites) and
  the foreground tiles whose `TILEINFO` misc has the high bit (drawn **in
  front of** sprites, for example a door frame or the grass Keen walks
  behind). This is the lesson of the masked-tile fix after C7: never
  guess which tiles go in front; the table says it.
- **Animated tiles** follow `TILEINFO` (time in tics and the offset of the
  next tile), per layer; `GalaxyTileAnimator` calls `set_tile`, so the
  xBRZ atlas follows.
- **Sprites**: each sprite has an origin and a hit box from the sprite
  table; an object's position is the original's (global units) and the
  sprite is drawn at position + origin, rounded to the original's pixel
  (the original draws sprites on whole pixels; smooth motion is the
  existing option).
- **Draw order**: the original gives every object a priority (0-3, Keen in
  front of most things, some in front of the foreground). Map it onto
  `z_index` between the three layers.

## Widescreen and scroll blocks

The original never shows a part of the level beyond a **scroll block**
(info values 25 and 26 stop the camera horizontally or vertically). In
4:3 we copy that exactly. In widescreen the picture is wider than the
original's, so it would show what is behind a horizontal scroll block:
secret rooms, the next part of the level, or the empty edge of the map.

Decided by the user (19-10-2026): the camera stops at a
scroll block just as in 4:3; whatever the wider view would show beyond it
is covered (black, or the picture behind the level). The level itself
stays as wide as the original. The same for the world map.

## The score box and the HUD

The original has a **score box** (score, lives, ammo) in the top-left of
the picture, which the player can turn off in the menu. In 4:3 we draw it
as the original does. In widescreen the user's rule is "with the HUD" by
default; for Keen 4 the score box *is* the HUD. Decided by the user (19-10-2026): the score box,
in the top-left of the visible picture, in 4:3 and in widescreen alike;
nothing else.

## Sound

- **PC speaker sounds**: decode them (`GalaxyPcSound`) into divisors and
  render them with the shared `SpeakerSynth`. This gives every sound with
  no new synthesiser, and it is what the original plays without a sound
  card.
- **AdLib sounds and music**: the original's default with a sound card,
  and the only way to hear the music. They need an **OPL2 (YM3812)
  synthesiser**. We write our own from the public chip documentation (no
  copied emulator code: DOSBox's and Nuked OPL's sources are GPL/LGPL).
  GDScript is too slow to run nine channels at 49,716 Hz in real time, so
  `GalaxyOpl` **renders** each sound and each song once, in a background
  thread (as `GraphicsLoader` does for xBRZ), into an `AudioStreamWAV`, and
  caches the result in `user://keen4/cache/` (made from the player's own
  files, never shipped). Music plays as a looping stream.
- A setting "Sound: PC speaker / AdLib" and "Music on/off" in the options
  (the original's own choices). Default as the original's default setup:
  AdLib sounds and music on (decided by the user, 19-10-2026).

## The menus, texts and the status window

- The menu logic is the shared `MenuController`; Keen 4 adds a
  `GalaxyMenuView` with the look of the original's control panel.
- The help, story and end texts are chunks in `EGAGRAPH` with their own
  mark-up and pictures (`GalaxyTextPages`).
- The status window (Enter) shows the level name, score, extra life at,
  keys, ammo, lives, drops, and the rescued elders (D7).
- The original's **Paddle War** (the paddle game in the menu) is optional
  and comes in D11 (decided by the user, 19-10-2026).

## Testing

- `tests/galaxy_fixtures.gd`: hand-made Huffman dictionaries, chunks,
  Carmack/RLEW planes, tileinfo tables and maps, so every decoder, the
  clip code and the actions are tested without the game files.
- `tests/test_keen4_data.gd` with the player's files (`Keen4Files.locate()`,
  skip without them). The user has **v1.0**; Keen 4 is also shareware
  (v1.4), so the real-data suites can run anywhere either is present. The
  tests check what holds for both (397 sprites, 1296 + 2916 tiles, 20
  maps) and, per version, the counts that differ (107 or 115 pictures).
- A cloud session has no Keen 4 files unless the user uploads them (as in
  D1); the fixtures carry the rest.
- Physics against the original: the research gives jump heights, speeds and
  times from Omnispeak; D4 adds tests that Keen's jump, pogo and fall cover
  those distances in those tics.
- The screens with `tools/scripted_play.gd`
  (`SCENE=res://src/keen4/keen4_view.tscn -- --game=4 --level=N`) and
  `tools/keen4_regression.sh` from D3 on.
- `tools/original/` (js-dos) works for Keen 4 as it is: `KEEN4E` instead of
  `KEEN3`.

## Rules that carry over

All hard rules in `CLAUDE.md` apply: never commit game data or anything
derived from it (also no rendered AdLib audio or decoded pictures), never
use the name "Commander Keen" or its logo as branding ("Keen 4" on the icon
is fine), never decompile `KEEN4E.EXE` code (reading data tables and the
headers out of it is fine), no copied code from Omnispeak, Commander Genius
or the Keen Dreams source (all GPL; documentation only). Extras are off by
default, with the user's exceptions (widescreen with the score box,
pictures behind levels in widescreen). Talk to the user in Dutch; code,
comments and commit messages in English.

## Deviations in D2

What D2 built differently from the plan above, and why (developer, D2):

1. **More, smaller classes in `src/galaxy/data/`.** The plan's
   `GalaxyExecutable` became five: `GalaxyExecutable` (unpacking, the
   version, the random numbers, the texts), `GalaxyExeTexts` (the search
   for texts by their shape), `GalaxyHeaderSearch` (the searches for the
   six headers), `GalaxyHeaders` (the six pieces, from the EXE or from
   header files next to the game) and `GalaxyEpisode` (the numbers of one
   episode: names, known places, the counts no table gives, the shapes of
   the message runs; Keen 4 fills it in `Keen4Episode`). The chunk ranges
   are `GalaxyChunkRanges`, the whole episode `GalaxyData`. A picture of a
   whole map for the viewer and the export is `GalaxyMapImage`.
   `GalaxyFont` (reading and drawing a font) lives in `data/`; the
   in-game text drawing of later milestones can build on it in `ui/`.
   Reason: the 500-line and 20-method limits, and every class one job.
2. **`GalaxyMap.Layer`** instead of `Plane` (`Plane` is a Godot type).
3. **The counts that no table gives come from the episode**: 3 fonts,
   4 misc chunks, 7 texts, 5 demos (the same in 1.0 and 1.4). Everything
   else is worked out from the file: pictures, masked pictures, sprites
   (the tables), the 8×8 counts (expanding the chunk), the border between
   the background and foreground tiles (a background chunk cannot hold 160
   bytes; around empty chunks the border goes on a whole row of 18), and
   so `TILEINFO`'s size. The plan said the tile counts follow from
   `TILEINFO`'s size; that size is not stored anywhere, so it is the other
   way round.
4. **A second launcher seam**: besides `GameCatalog.Game.icon_picture`,
   `GameCatalog.Game.icon_title` (the name in the game's own font) and
   `GameIcon.title_picture`. Without them Keen 4's name was drawn in the
   plain fallback font that the grey "no files" icons use, so an
   available Keen 4 looked unavailable. Both are optional and unset for
   Keen 1-3 (the regression's `launcher.png` differs only inside the
   fourth icon). Keen 4's sprite is 30 px high, the icon's panel 30 px
   inside its outline, so his helmet and shoe touch the outline.
5. **Keen 4's online id** is `Keen4Files.GAME_ID`
   ("commanderperfect-keen4"), deliberately *not* in
   `OnlineProtocol.GAME_IDS` until D12, so no lobby or host matches it (an
   empty id would have matched the "unknown game" of a lobby).
6. **`GameLaunch.game_number`**: when several `--game=` options are given,
   the lowest wins (2 before 3 before 4), so every old combination gives
   the same answer.
7. **The "coming soon" screen** (`Keen4View`, `src/keen4/keen4_view.gd`) is
   a plain `Control` built in code: Keen walking (sprite 7) and the title
   in Keen 4's menu font, the level name for `--level=N`, Enter/Escape back
   to the start screen. D3 replaces it with the real view (node layout of
   `level_view.tscn`). As for Keen 2 and 3, started with `--game=4` the
   start screen at once opens Keen 4 again (the option is still on the
   command line).
8. **The data viewer's Galaxy page** is a new file,
   `src/viewer/galaxy_viewer_page.gd` (`GalaxyViewerPage`); `data_viewer.gd`
   only gets the branch that shows it for `--game=4`. Each tab is decoded
   the first time it is shown.
9. **No thread**: decoding all of EGAGRAPH takes about 1 s, loading 70 ms,
   the launcher's sprite under 1 ms (file-formats.md, "Decoding time"), so
   everything is decoded lazily on the main thread.
10. **Tests**: besides `galaxy_fixtures.gd`, `test_galaxy_data.gd` and
    `test_keen4_data.gd`, a second fixture file
    `tests/galaxy_file_fixtures.gd` (the hand-made EGAGRAPH, AUDIO and
    program image) and a suite `tests/test_galaxy_files.gd` (what the
    readers make of those files), to keep each file small.
11. **Texts found so far**: the level names, the "Keen enters …" texts,
    the janitor's records and the run of council, Lindsey and wetsuit
    messages, plus the random numbers. Not yet: the status window, the
    menus, the "Try Again" box, the high-score defaults (the milestones
    that need them search for them, by shape, the same way).

## Deviations in D3

What D3 built differently from the plan above, and why (developer, D3):

1. **Where the classes went.** `src/galaxy/level/`: `GalaxyLevelMap`,
   `GalaxyTileAnimator`, `GalaxyTileAtlas` (one atlas per tile set),
   `GalaxyCamera` (the original's scroll rules, numbers only),
   `GalaxyViewCover` (widescreen), `GalaxyBackdropPictures` and
   `GalaxyClock`. `src/galaxy/actors/GalaxyObjectLayer`,
   `src/galaxy/graphics/GalaxyScaledGraphics`. Keen 4: `Keen4LevelScreen`
   (drawing on `GameScreen`) and `Keen4View` (the flow) as a two-class
   chain like Keen 3's, and `src/keen4/level/Keen4Start`. The info values,
   standing sprites, sky tiles and the backdrop folder are constants in
   `Keen4Episode`; the Galaxy classes get them passed in (Keen 5 ignores
   info 26, for example).
2. **`GalaxyClock` already in D3** (the plan put it in D4): the tile
   animation needs the original's tics. It only hands out 2-tic frames and
   the absolute tic; D4 builds on it.
3. **Atlases per level, not per whole tile set.** An atlas of all 2916
   foreground tiles at xBRZ's factor 6 would be about 112 MB and take
   ~10 s of processor time to scale. A level needs a few hundred tiles
   (with their animation loops); `GalaxyScaledGraphics` scales only those
   (~0.6 s on 4 cores) and keeps them for later levels. A `set_tile` with a
   tile outside the atlas asks for a new atlas (`tiles_missing`).
4. **The camera is not `LevelCamera`'s limits and smoothing.**
   `GalaxyCamera` computes the view in units by the original's rules;
   the scene's `LevelCamera` node is used unchanged with
   `follow_exactly(true)` and its anchor put on the view's middle. In
   widescreen the wide view is centred on the original's view and kept
   inside the area between the blocks around it; it is covered only where
   that area is narrower (D1 planned "centre on the original and cover";
   this shows as much level as allowed and covers less).
5. **Covering instead of clipping.** `CanvasItem.clip_children` first,
   but children with their own z index (the in-front tiles, the sprites)
   escape the clip. `GalaxyViewCover` draws black, or the backdrop picture
   at its own place, over everything outside the area.
6. **Keen 1-3's nodes stay in the scene, hidden.** `keen4_view.tscn` is
   `level_view.tscn`'s layout (GameScreen finds its nodes by name) plus
   `GalaxyMap`, `Objects` and `Cover` under World. `Keen4LevelScreen`
   overrides `_apply_graphics`, `_apply_backdrop`, `_apply_display_settings`,
   `_fit_screen` and `_update_status` (GameScreen's versions read Keen 1-3's
   `EgaGraphics`/`LevelData`); nothing shared changed.
7. **No "coming soon" screen**: without `--level` the view opens level 1,
   as the flow above says for D3-D6. `--level=N` opens any map 0-19; the
   world map and level 17 show the map Keen and the swimming Keen standing
   still (with the camera the original puts there), not only info 1 / 2.
8. **Free look is "where Keen would be"**: the arrows move a point and the
   view is put on it by the original's rules, so looking around respects the
   scroll blocks and jumps across them, instead of `FreeLook`'s own bounds
   over the whole map.
9. **The camera's settle step** follows Omnispeak's 32-bit arithmetic
   (`(distance << 4) >> 7`, an eighth); the 16-bit original may differ for
   distances over 128 px. Only matters once Keen moves (D4).

## Deviations in D4

What D4 built differently from the plan above, and why (developer, D4):

1. **Where the classes went.** `src/galaxy/actors/`: `GalaxyAction`,
   `GalaxyObject`, `GalaxyWorld` (the object list and the frame),
   `GalaxyItem`, `GalaxyStunnerShot`, `GalaxyGemDoor`;
   `src/galaxy/physics/`: `GalaxyUnits`, `GalaxyClip`, `GalaxyPhysics`
   (gravity, acceleration, damping), `GalaxyTileKinds` (the misc values);
   `src/galaxy/keen/`: `GalaxyKeen`, `GalaxyKeenActions` (his table),
   `GalaxyInventory`; `src/galaxy/ui/GalaxyScoreBox`. Keen 4:
   `Keen4LevelSession` (`level/`), `Keen4Inventory` (`game/`, the new-game
   numbers on top of `GalaxyInventory`), `Keen4Sprites` (`data/`, the
   sprite numbers by name). `Keen4View` plays the maps where Keen stands.
2. **Keen in three files.** Keen's think, contact and react functions are
   methods of his own class (the world calls them by name). All of them
   in one class would be ~1000 lines, so the class is split by topic in a
   chain: `GalaxyKeenBody` (what he carries and holds down, dying,
   shooting, the tiles and items he touches) ← `GalaxyKeenAir` (jumping,
   falling, the pogo, ledges) ← `GalaxyKeen` (the ground, looking, poles,
   doors, switches, gem holders). Only Keen does this; enemies (D5) are one
   class each.
3. **Action tables are text rows**, one line per action ("stand STAND_L
   STAND_R step+ -s 4 0 32 standing normal ground stand"), read by
   `GalaxyAction.table_from`; the think, contact and react names get the
   prefixes `_think_`, `_contact_`, `_react_`. Not read from the EXE (the
   records there hold code addresses), as research §3 planned.
4. **Weak references.** `GalaxyAction.next` and `GalaxyObject.world` are
   weak (a `WeakRef` behind a property): the actions of a table form
   loops and the world holds its objects, so strong references would never
   be freed. The owner of a table keeps the table (Keen, items, shots, the
   gem door each hold theirs).
5. **"Protect" means something else than research §3 said** (corrected
   there): it lets leftover tics run an action *to its end* in the frame
   it was reached; without it such an action stops one tic short and the
   rest of the frame is lost (Omni CK_RunAction checks the new action).
6. **A level's first frame is 3 tics** (`GalaxyClock.start_level`, Omni
   CK_PlayLoop), so every later frame starts on an odd tic. This is not a
   detail: gravity then changes the speed before the frame's first tic
   moves, and the held jump is 67 pixels, as the original shows (Omnispeak's
   scratch model with even frames gave 70). Maps that are only shown keep
   `reset` (D3's tests unchanged).
7. **Gravity low is no gravity** (`GalaxyPhysics.gravity_low`): seen in the
   original (a held pogo bounce rises 6 pixels in each of its 12 frames).
8. **The slope table is start + step per slope value** (exactly
   Omnispeak's 8 × 16 numbers, each row a straight line): a `const` array
   of `PackedInt32Array`s read back garbage in Godot 4.7.2 (random heights,
   so Keen sometimes fell through floors); a flat table of 128 numbers is
   what gdformat writes one per line.
9. **The score box** is a `Sprite2D` (`GalaxyScoreBox`) in the World
   viewport's `Ui` canvas layer (a new node `ScoreBox` in
   `keen4_view.tscn`), 4 pixels from the top-left corner of the visible
   picture, in front of the widescreen cover; always drawn with the
   original pixels (also with xBRZ). The original only redraws it when a
   number changes; so does ours.
10. **Objects on the screen**: `GalaxyObjectLayer.show_objects` follows the
    world after every logic frame (an item per object, hidden while it
    sleeps, its priority as it changes); `GalaxyCamera.limits` gives the
    level's edges for leaving it.
11. **The flow before the world map**: walking out of a level opens the
    next (1-16, then 1 again: 17 is swum, D6); maps 0 and 17 are still
    only shown (D3's look-around); a death starts the level again at
    once (the "Try Again / Exit to Shadowlands" box is D7's) and costs a
    life; below 0 lives "Game over" and the start screen. The random table
    starts at a random place per level (the original takes the clock).
12. **Not yet**: platforms (Keen's `_contact_normal` and `_contact_special`
    only take items; D6), enemies and stunning (D5; the shot already calls
    the contact of what sleeps in its way), sounds (D9), the moon spot
    exists only in level 11 (works, not compared with the original),
    difficulty (Normal; Easy's gravity and +8 charges in D10).
13. **Shared files changed**: only `tests/run_tests.gd` (four suites).

## Deviations in D5

What D5 built differently from the plan above, and why (developer, D5):

1. **Where the classes went.** `src/galaxy/actors/`: `GalaxyCreature` (the
   base of every creature and of what they leave: its own action table,
   the stun with its hop and stars, walking and turning, falling,
   gliding), `GalaxyEnemyShot` (a lethal shot that ends at a wall; Keen 4's
   darts, later Keen 5 and 6's shots), `GalaxyDifficulty` (Easy / Normal /
   Hard, default Normal). `src/keen4/actors/`: one class per creature
   (`Keen4Slug`, `Keen4Mushroom`, `Keen4Egg`, `Keen4Bird`, `Keen4Arachnut`,
   `Keen4Skypest`, `Keen4Wormmouth`, `Keen4Cloud`, `Keen4Berkeloid`,
   `Keen4Lick`, `Keen4Mimrock`, `Keen4Bounder`, `Keen4Smirky`,
   `Keen4Inchworm` (also the Foot), `Keen4DartGun`) and `Keen4Creatures`
   (info value → creature and lowest difficulty; the values left for D6 /
   D7 in a list). The sprite numbers are `Keen4CreatureSprites`.
2. **What a creature leaves is an object of its own class.** Slime,
   egg-shell bits, the bolt, fireballs, puffs and what Smirky ate are
   instances of the creature's class (or plain `GalaxyCreature` when they
   only need `_contact_lethal`), so their think / contact / react names
   resolve and their actions are held by their own table (the actions
   only hold each other weakly, D4).
3. **Three small additions to `GalaxyObject`**, each for something the
   original draws differently from "one sprite at the position":
   `overlays` (a second sprite with the object: the stars; the platform
   flames of D6 can use it), `draw_offset` (the Berkeloid's picture bobs,
   its box does not) and `hidden` (the dart gun has a box but no picture).
   `GalaxyObjectLayer.show_objects` draws them.
4. **What Keen does with a creature is the creature's.** Instead of
   Omnispeak's type checks inside Keen's contact functions,
   `GalaxyObject.touched_by_player(player, holding)` is called by Keen's
   `_contact_normal` / `_contact_special`; the Bounder pushes, carries or
   knocks him off, the Foot ends the level. What kills Keen does that in
   its own contact (Omnispeak's extra kill in Keen's special contact for
   the Mushroom, Arachnut and Berkeloid is redundant: their own contact
   already kills).
5. **Riding is Galaxy's now** (planned for D6): `GalaxyKeenBody.platform`,
   `push_out` (Omni CK_PhysPushXY), `land_on` (CK_PhysPushY), `knock_off`
   and `_ride_platform` (CK_KeenRidePlatform), called by `GalaxyWorld`
   between the objects' moves and the contacts, as the original.
6. **The Foot** sets `GalaxyWorld.ending = &"foot"` and completes the
   level; `Keen4LevelSession.ending()` tells it apart from walking out (the
   flight is D7's).
7. **Difficulty is a parameter** of `Keen4LevelSession.start` (default
   `GalaxyDifficulty.DEFAULT`, Normal); the view does not choose yet (D10).
8. **God mode for watching**: Shift+G in `Keen4View` (the original's
   F10+G); it uses `GameScreen`'s `_god_mode` field, nothing shared
   changed.
9. **Smirky's teleport** (research §12 point 4): Omnispeak's loop always
   removes him; ours puts him at the last item still lying in the level
   and lets him come out of the puff, and removes him only when no item
   is left. Not yet confirmed in the original (see research.md, "Watched
   in D5").
10. **Smirky's jump for items lying as sprites** follows Omnispeak, whose
    test (item bottom above his top *and* more than 3 tiles below it) no
    item can pass: he only jumps for item *tiles* above him.
11. **Shared files changed**: only `tests/run_tests.gd` (four suites).

## Deviations in D6

What D6 built differently from the plan above, and why (developer, D6):

1. **Where the classes went.** `src/galaxy/actors/`: `GalaxyPlatform`
   (moving along one axis, turn points, held between two, Keen riding or
   falling onto it) and `GalaxyFallingPlatform`; `src/galaxy/ui/`:
   `GalaxyWindow` (the original's centred message window). Keen 4, in
   `src/keen4/actors/` like the creatures: `Keen4Platform` (the jets),
   `Keen4Mine`, `Keen4Council` (the janitor too), `Keen4Lindsey`,
   `Keen4Wetsuit`, `Keen4SwimmingKeen`, `Keen4Bubble`, `Keen4Schoolfish`,
   `Keen4Dopefish` (extends the school fish: same swimming), and
   `Keen4WaterSprite` (named so it is not taken for a picture sprite);
   `src/keen4/game/`: `Keen4Messages` (the boxes' screens) and
   `Keen4Progress`. The plan's `Keen4Platforms`, `Keen4Switches` and
   `Keen4Council` in `level/` were not needed: the switches are Keen's
   (D4), the rest are objects like the creatures.
2. **`Keen4Progress` already in D6** (the plan put it in D7): the rescue
   count picks Keen's answer and the wetsuit must be kept. It holds the
   rescues, the wetsuit and the levels done; the view keeps one per game.
3. **The swimming Keen is Keen 4's**, not Galaxy's (Keen 5 and 6 do not
   swim): `Keen4SwimmingKeen` extends `GalaxyKeenBody` (inventory, input,
   dying, tiles) with its own actions. `Keen4LevelSession` has `keen`
   (walking, null under water), `swimmer` (null on land) and `player`
   (whichever is played); level 17 uses the world-map camera
   (`GalaxyCamera.follow_map`, which D7 reuses for the map).
4. **Messages after the frame.** The original shows Lindsey's and the
   janitor's boxes inside the contact, in the middle of a frame; ours ask
   for them (`GalaxyWorld.ask`) and the view shows them after the frame
   (the rest of that frame has run). The council and the wetsuit end the
   level (`GalaxyWorld.complete` with `&"council"` / `&"wetsuit"`) and the
   view shows their boxes before the next level, as the original does
   after its play loop. A box stops the clock; any key or joypad button
   pressed (not held from before) goes on; F1-F6 stay display keys.
5. **The boxes are pictures, not live text**: `Keen4Messages` draws each
   screen into a 320 × 200 transparent image with `GalaxyWindow`; the view
   shows it in the World viewport's `Ui` layer (a `Sprite2D` made in code,
   no change to `keen4_view.tscn`), over everything, always with the
   original pixels (as the score box), centred in the wide picture in
   widescreen. Compared with the original pixel by pixel: no difference.
6. **The pictures by their place from the end of the picture range** (11
   the elder … 7 Lindsey), the same in 1.0 and 1.4; never chunk numbers.
7. **After the eighth rescue** (the end is D8's): the status line says
   "All eight council members are rescued" and the next level follows.
   Until the world map exists the round is levels 1-17 (17 after 16, then
   1 again); a rescue or the wetsuit opens the next level like walking out.
8. **Platforms and mines share `GalaxyPlatform`'s move** (Omni uses
   CK_AxisPlatform for both); the mine is a `GalaxyPlatform` that kills
   instead of carrying. The vertical stop rule is Omnispeak's: going up a
   turn point two tiles *below* the one ahead holds it, going down one two
   tiles *above* (the roadmap's "2 tiles beyond").
9. **Keen 4's drawing priority bug kept**: a platform that takes Keen off
   a pole leaves his priority as it was (only Keen 6 resets it; Omni).
10. **A falling platform without a turn point below** falls to the map's
    last row and is removed (level 1's has none); Keen riding it lands on
    whatever floor stops him (Omni's logic, not seen in the original).
11. **Fixed during D6**: the view's `_progress` field shadowed
    `GameScreen`'s and the scene did not compile; no suite loaded the
    view, so a test now checks that `keen4_view.gd` compiles.
12. **Shared files changed**: only `tests/run_tests.gd` (four suites).

## Deviations in D7

What D7 built differently from the plan above, and why (developer, D7):

1. **Where the classes went.** Galaxy: `GalaxyMapKeen` (`keen/`, the walk,
   the waving and the entrances that Keen 5 and 6 share; it extends
   `GalaxyKeenBody` for the input and the world's player hooks),
   `GalaxyMapFlag` (`actors/`, waving and thrown flags; the episode gives
   the offsets), `GalaxyScreenQueue` and `GalaxyStatusDrop` (`ui/`).
   Keen 4: `src/keen4/map/` holds `Keen4MapKeen` (water and the Foot),
   `Keen4Miragia` and `Keen4MapSession` (the plan's map session);
   `src/keen4/game/` holds `Keen4GameBoxes` (entering, "One moment",
   "I can't swim!", Try Again, Game Over) and `Keen4StatusWindow` (the
   plan's `Keen4StatusScreen`; Keen 4 only for now: Keen 5 and 6 differ in
   two fields, so the drawing can move to Galaxy when they come).
2. **The view is a chain of three.** `Keen4View` would pass 500 lines, so
   `Keen4PlayScreen` (between `Keen4LevelScreen` and `Keen4View`) plays a
   level or the map, shows the queue of boxes and fades and the status
   window; `Keen4View` keeps only the flow (which map, done, lost, try
   again, game over) and the keys.
3. **Everything between the frames is one queue** (`GalaxyScreenQueue`):
   message boxes that wait for a key (D6's), the timed "One moment", the
   "Keen enters …" box with its five fingers, the fade (the brightness of
   the screen node) and the black step that puts the next map on the
   screen. The game does not run while the queue has steps, so the thrown
   flag starts once the map has faded in, as the original's
   CK_MapFlagThrown waits for the fade.
4. **The original's load time is a fixed time** (the original's depends on
   reading the files: 130-630 ms per finger in js-dos): 21 tics for the
   whole picture, 20 per finger, 28 for the last, then 3 × 6 tics of fade,
   19 black and 3 × 6 back (seen in the original, D7). The fade is three
   even steps of brightness, not the EGA palette's steps.
5. **Three numbers of the original instead of Omnispeak's**: "One moment" is
   centred, "I can't swim!" is 12 pixels down (Omnispeak: printed from the
   left, 6 down; both compared pixel by pixel), and in the water the stick
   counts again in the think that uses up the last forced tics, and Keen
   walks on at once out of the water (the original's positions frame by
   frame; Omnispeak would turn him round 6 tics later and stand him first).
6. **New texts by their lengths**: the status labels and the run of game
   texts (game over, try again, one moment) are one-line records, so
   `GalaxyEpisode.text_lengths` / `GalaxyExeTexts.find_by_lengths` find a
   run by the lengths of its records (file-formats.md).
7. **`GalaxyWorld` writes the background too** (`back_tile_writer`,
   `set_back_tile`, `copy_block`): Miragia copies all three planes.
   `GalaxyWindow` got `print_in_middle`, `text_height` and `outline` (the
   Try Again frame).
8. **`Keen4Progress`** keeps the map position, the level finished last (its
   flag is thrown), whether the Foot ended it (he flies), and gives a
   dictionary for the saves of D10 (`to_dictionary`, `from_dictionary`).
9. **The start**: `--game=4` without `--level` is a new game on the world
   map with its box (there is no title or menu yet, D8 and D10); `--level=N`
   opens map N at once, also 0 (the map, without a box). After a level
   opened with `--level`, Keen comes back to the map's start.
10. **Map 18** is an ordinary level (seen in the original): walking out of
    the Megarocket ends it; it has no flag and can be entered again.
11. **The eighth rescue** still only says so in the status line (the end is
    D8's), then the map.
12. **Not built**: sounds (D9), the E+N+D cheat (D8), the original's EGA
    sprite shifts (sprites on even pixels, research.md "Watched in D7"; left
    for D13 because it moves every sprite in every level).
13. **Shared files changed**: only `tests/run_tests.gd` (three suites).
    `tools/keen4_regression.sh` (Keen 4's own) takes the world map too.

## Deviations in D8

What D8 built differently from the plan above, and why (developer, D8):

1. **Where the classes went.** Galaxy: `GalaxyTextPages` (`data/`, the
   page mark-up), `GalaxyPageLayout` (`ui/`, the original's page layout:
   18 lines, words, pictures with room around them, timed pictures),
   `GalaxyDemo` (`data/`), `GalaxyTwoButtonFiring` (`keen/`),
   `GalaxyHighScores` (`data/`: the table, its order, the defaults found in
   the program by their shape, JSON), `GalaxyIntroBitmap` and
   `GalaxyIntroCredits` (`ui/`, the "terminator"), `GalaxyStoryScroller`
   (`ui/`), `GalaxyTitleLayer` (`ui/`, the node that shows the full
   screens) and `GalaxyEga` (`ui/`, EGA numbers and XOR). Keen 4:
   `Keen4Help`, `Keen4Ending`, `Keen4HighScoreBoard`, `Keen4TitleLoop`
   and `Keen4Cheats` (`game/`). The plan's `GalaxyTextScreen` became the
   layout plus the layer; the plan's `Keen4HighScores` became the Galaxy
   table plus Keen 4's board on map 19.
2. **The view is a chain of four.** `Keen4FrontScreen` (between
   `Keen4PlayScreen` and `Keen4View`) runs the title loop, the demos, the
   help, the end and the name on the table; `Keen4View` keeps the game's
   flow and calls the front's hooks (`_front_input`, `_after_demo_frame`,
   `_start_ending`, `_game_ended`). `Keen4PlayScreen` got one hook,
   `_frame_input` (the keys, or a demo's recorded input). The loading
   box's queue (`_queue_loading`) moved from `Keen4View` to the front, so
   the demos' "DEMO" box is the same box.
3. **Full screens are a layer over the game**, not message boxes:
   `GalaxyTitleLayer` lies in the World viewport's `Ui` layer under the
   boxes (the "DEMO" box shows over it), black around the original's
   320 × 200 in widescreen. The intro's two words are additive sprites
   (alone dark grey, together light grey, as the original's palette);
   the story is one rectangle with a shader that squeezes the rows as the
   original (pixel for pixel the same, checked by rendering it on the
   processor too); the help, end, zoom and fizzle are pictures.
4. **The table is printed into the map's picture** as the original: a
   see-through 320 × 200 picture placed at the view's corner in the world,
   drawn after the foreground tiles and before the sprites, with each
   letter's pixels XORed with the map's tile colour under it.
5. **Keys of the title loop** (the menus are D10's): Escape goes back to
   the start screen, F1 opens the help, any other key or button starts a
   new game on Normal on the world map. In the original any key opens the
   wrist-watch menu.
6. **F1 is the original's help**, in the title loop and in a game (the game
   waits behind it). Keen 1-3's help line moved to Shift+F1 for Keen 4.
7. **After a game** (game over or the end): the name is typed on map 19
   when the score makes the table (a tie goes above on more rescues), then
   the high scores (demo 4) and the title picture for 420 tics, then the
   title loop goes on (Omni CK_DemoLoop); D7's game over went to the start
   screen.
8. **The end after E+N+D** counts as rescuing the eighth member on the map
   Keen is on (Omni: the level is marked done, the member's boxes with
   Keen's eighth answer, the end), also on the world map (seen in the
   original: the elder's box over the map).
9. **Demos**: a new game on Normal, the random table from index 0 after
   the objects are placed (the original sets it again in its play loop), 3
   tics a frame from the first (the level's first frame is 3 tics anyway),
   no extra lives for points (`GalaxyInventory.extra_lives_for_points`),
   the DEMO sign (sprite 5) at the view's top middle instead of the score
   box, nothing in the high scores. A demo ends after the frame that uses
   its last input, or when Keen leaves or loses the level.
10. **Not built**: the sign-on text screen (the original's DOS screen
    before the intro), the menus (D10), music (D9), the original's
    different fizzle order (it shuffles with the C library's random
    numbers; ours with a fixed seed), the original's sprite and scroll
    steps (see "Watched in D8" in research.md: 2 or 8 pixels; left for
    D13 as in D7).
11. **Fixed during D8**: `[] if ... else ...` gives an untyped `Array`,
    which cannot be stored in an `Array[Image]`: the high-score step of the
    title loop stopped with a script error. No suite runs the view's flow
    (it needs a running scene tree); the screenshots of the whole loop
    caught it. `test_keen4_front_play` tests the flow's pieces instead.
12. **Shared files changed**: only `tests/run_tests.gd` (two suites).
    `tools/keen4_regression.sh` (Keen 4's own) takes the intro (in both
    shapes), the help menu and a help page too.

## Deviations in D10

What D10 built differently from the plan above, and why (developer, D10):

1. **Where the classes went.** Galaxy: `GalaxyMenuController` (`ui/`, a
   subclass of the shared `MenuController`: its stack, its key-set and
   press-a-key menus and its display options are reused; the cards,
   the cursor rules and the dialogs are the original's), `GalaxyMenuView`
   (`ui/`, draws the panel on a 320 × 200 picture), `GalaxyMenuCards`
   (`ui/`, the cards' places, the same in Keen 4-6; the episode gives the
   pictures) and `GalaxySaveSlots` (`data/`, six named JSON slots). Keen 4:
   `Keen4MenuScreen` (a fifth link in the view chain, between
   `Keen4FrontScreen` and `Keen4View`), `Keen4SavedGame` and
   `Keen4Settings` (`game/`). The plan's "a Galaxy view for the shared
   `MenuView`" became a controller subclass too: the shared controller
   draws through `GameWindow`, wraps the cursor round and skips disabled
   choices, and knows nine unnamed slots; none of that is the original's.
2. **No shared file changed** except `tests/run_tests.gd` (two suites, plus
   the tester's). The keys and the display settings are the shared
   `UserSettings`/`KeyBindings` (changed in the panel, used by Keen 1-3
   too); the score box is Keen 4's own setting in
   `user://keen4/settings.cfg` (the original keeps it in CONFIG.CK4), so
   `UserSettings` did not need a new field.
3. **Saving in a level replays the level.** The original saves the game
   state, the three planes and every object (Omni CK_SaveGame). Writing
   out every `GalaxyObject` subclass (actions, timers, references between
   objects, weak references) would touch every creature class. Instead a
   save in a level keeps the level's start (inventory, progress,
   difficulty, the random table's start) and every logic frame since (the
   input bits and the tics, 2 bytes, plus the B+A+T cheat and god mode as
   events); loading starts the level and plays the frames again behind
   black. The engine is deterministic (D8: the demos play frame for frame),
   so the level is exactly as it was: checked by saving in level 1 and
   loading, the picture outside the PAUSED box is identical. The cost: about
   0.25-0.9 ms per frame in this container (a minute in a level is 2100
   frames: 0.5-2 s to load; ten minutes 5-19 s), spread over the screen's
   frames (50 ms each) behind black so the window stays responsive. If a
   later engine change makes old frames end differently (Keen dead or out
   of the level), the level starts anew from the saved start.
4. **The map save** keeps Keen's place (the original's mapPosX/Y): he
   starts there; a thrown flag or the Foot's flight is not repeated.
5. **Configure** has only what this engine has: Options (the score box,
   then the shared display settings in the original's "NAME (ON)" style:
   widescreen, 4:3 pixels, full screen, smooth motion, backgrounds,
   graphics), Keyboard (the one-player keys on the Button Setup card, each
   key in the original's box; the first key of each action, which is the
   one that changes) and Reset Keys. Sound and Music come in D11 (D9's
   sound), the joysticks and two-button firing are not offered, Paddle
   War is D11's. "Choose Game" (back to the start screen) is ours, in
   place of Paddle War.
6. **Escape** in a game opens the panel (D3-D8: the start screen); Escape
   on the main card asks "REALLY QUIT?" as the original. Any key in the
   title loop opens the panel (D8: a new game on Normal); the
   launcher's "open the menu" request is still ignored, the title loop
   comes first as in the original.
7. **F1 is not taken while the panel is open** (the original opens its
   help from the panel); F2-F6 still work.
8. **The panel is a picture on the title layer** (D8's `GalaxyTitleLayer`),
   with black around it in widescreen, always with the original pixels.
   While it is open the game and the title loop stand still; its cursor
   blinks on the game's clock (35 tics).
9. **The original's cards not built**: Sound, Music, Joystick, Movement
   Setup (our keys are one list), the "CONTROL: KEYBOARD" line.
