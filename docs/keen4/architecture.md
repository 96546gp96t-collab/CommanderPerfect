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
