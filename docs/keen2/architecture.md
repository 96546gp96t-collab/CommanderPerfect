# Keen 2: architecture

How Keen 2 is added beside Keen 1. Written in milestone B1 by the architect;
the developer follows it in B2-B10 and updates it when a decision changes
(with the reason). The milestones are in [roadmap.md](roadmap.md), the facts
about the game in [research.md](research.md).

## The rule: Keen 1 stays as it is

The user asked to leave the Keen 1 code alone and to reuse what is the same
for Keen 2. That splits the code into three groups.

| Group | What | Allowed changes |
|---|---|---|
| **Keen 1 only** | Everything that only Keen 1 has: `src/actors/*` (Yorp, Garg, Vorticon, robots, ice, chain), `src/map/map_session.gd`, `map_info.gd`, `map_teleport.gd`, `src/game/level_view.gd`, the ship (`ship_*.gd`), `ending_sequence.gd`, `status_screen.gd`, `map_messages.gd`, `backdrops.gd`, `game_progress.gd`, `inventory.gd`, the text extractors (`hint_texts.gd`, `ending_texts.gd`, `score_texts.gd`), and the `test_keen1_*` suites | **None.** Not even renames or "small cleanups". Keen 2 gets its own classes. |
| **Shared** | Code that is not about one game: decoders (`src/data/` except the Keen 1 extractors), graphics and scaling, `src/level/` (map, tile set, camera, collision, backdrop), `src/keen/`, `src/sound/`, `src/menu/`, `src/online/`, `src/launcher/`, `GameScreen`, `LevelSession`'s core, settings, saves, high scores, tools | **Only additive, behaviour-neutral changes**: a new optional parameter whose default is the Keen 1 value, a new method, a new constant, a hook that Keen 1 does not use. Never a changed default, a removed method or a changed save format. |
| **Keen 2 only** | Everything new | Free, in `src/keen2/`. |

How we prove that Keen 1 did not change, at the end of every B milestone:

1. Every existing test passes **without changes to the test files** (the
   existing suites may not be edited; new suites may be added). The one
   exception: assertions about the list of games (the start screen offers
   one more game) grow with the catalog; Keen 1 must stay first and
   unchanged. Approved by the user in B2.
2. `gdlint` is clean.
3. With the Keen 1 shareware data: `tools/keen1_regression.sh` gives the
   same screenshots of the title screen, level 1 and the world map before
   (on `main`, in a `git worktree`) and after the milestone, byte for byte.
   It runs Godot with `--fixed-fps 60`; without it the level screenshots
   depend on timing. Only `launcher.png` may differ, and only by the icons
   of the new games.
4. `git diff main -- <Keen 1 only files>` is empty.

If a shared change cannot be made behaviour-neutral, stop and ask the user
before making it.

## Where the code goes

```
src/keen2/            Keen 2 only (all class names start with Keen2)
  data/               Keen2Files, Keen2Executable (texts, sounds, version), Keen2Texts
  actors/             Keen2Grunt, Keen2Youth, Keen2Elite, Keen2Scrub, Keen2GuardRobot,
                      Keen2Platform, Keen2Spark, Keen2Shot; B4 added the
                      bases Keen2Enemy and Keen2Carrier, and Keen2EnemyShot
  keen/               Keen2Body (Keen in a Keen 2 level: Keen 1's KeenBody plus the stun, B4,
                      and the pogo button on switches, B5)
  level/              Keen2LevelSession, Keen2RidingCollision (B4), Keen2Switches,
                      Keen2Bridge (B5: here, not in actors/, because it is no actor),
                      Keen2Darkness, Keen2Tantalus
  map/                Keen2MapSession (no teleporters, no ship), Keen2MapInfo
  game/               Keen2LevelPlay (the levels one after another, B3), Keen2GameData
                      (loading), Keen2Icons (HUD icons), Keen2Progress, Keen2Inventory,
                      Keen2StatusScreen, Keen2Ending, Keen2EarthExplosion with
                      Keen2SpaceSprite (B5), Keen2Sounds (EARTHPOW, B5), Keen2Hud parts
  keen2_view.gd       Keen2View (the scene; the Keen 2 counterpart of level_view.gd)
  keen2_view.tscn     The game scene that the start screen opens
tests/test_keen2_*.gd Keen 2 suites; the ones that need real data skip without it
docs/keen2/           Keen 2 documents
assets/backgrounds/keen2/   pictures behind Keen 2 levels (our own pictures only)
```

GDScript class names are global, so every Keen 2 class starts with `Keen2`
(a `Vorticon` already exists). Files are `snake_case` (`keen2_grunt.gd`).

## The seams in the shared code

What Keen 2 needs from the shared code, and the additive change for each.
Found in the code survey of B1; line numbers are from `main` at that time.

| Need | Today | Additive change |
|---|---|---|
| Find `game_data/keen2`, `KEEN2.EXE`, `*.CK2` | `GameFiles` has static constants: folder `game_data/keen1`, extension `.CK1`, the required files (`game_files.gd:14-30`, `95-110`) | Add an instance field `extension` (default `"CK1"`) used by `level_numbers()` and a new instance `level_file(number)`; add `static func locate_in(subfolder, required) -> GameFiles` that `locate()` calls with the Keen 1 values. `Keen2Files` wraps it with the Keen 2 values (`game_data/keen2`, `--data-dir-keen2=` option). *Built in B2 as:* `locate_in(subfolder, required, option, extension)`, plus `first_complete(candidates, ...)` (so tests can pass folders) and `candidate_directories_in(subfolder, option)`; `open()` got optional `extension` and `required` parameters and the instance a `required_files` field. All defaults are Keen 1's. |
| Read `EGAHEAD.CK2` etc. | `EgaGraphics.load_from(files)` uses fixed `.CK1` names (`ega_graphics.gd:29-35`) | Optional parameter `extension := "CK1"`. *B2 also:* `FinaleImage.load_from(files, file_name := "FINALE.CK1")` for `FINALE.CK2`. `EgaHeader` needed no change. |
| Tile properties of 689 tiles at another offset | `TileProperties.find_in_image(image, tile_count)` already scans; `KNOWN_OFFSETS` are Keen 1's | Use `find_in_image` with the Keen 2 offsets first (new optional parameter `known_offsets`), the scan as fallback. The `Behavior` enum stays Keen 1's; Keen 2 gets `Keen2Behavior` for values 22-26. |
| Sounds from inside `KEEN2.EXE` | `SoundFile.parse(bytes)` exists | None: `Keen2Executable` cuts the `SND` block out of the image and calls `parse`. The `Sound.Id` table is Keen 1's; Keen 2 passes its own name table (new optional parameter where sounds are looked up). *Built in B3:* no shared change: the embedded block has Keen 1's names, so `Keen2GameData` hands `executable.sounds()` to `SoundPlayer.load_sounds` as is. When the EXE has no sound block, a `SOUNDS.CK2` file is used if there is one (only the stand-in data has it). *B4:* the enemies' sounds all have a `Sound.Id` already: `VORTICON_SCREAM` (VORTSCREAM: grunt, youth and Elite die), `SHOT_HIT` (a Scrub dies; a shot hits something), `KEEN_FIRE` (KEENFIRESND: the Elite fires), `TANK_FIRE` (TANKFIRE: the Guard robot fires). `Sound` is unchanged. |
| Texts from inside `KEEN2.EXE` | `TextDocument.layout(bytes, width)`, `ExeStrings.find/record_at` exist | None. |
| Saves and high scores apart from Keen 1 | `SaveGames.in_directory(path)`, `HighScores.load_from(path, ...)` exist | None: Keen 2 uses `user://keen2/saves` and `user://keen2/high_scores.json`. Keen 1's paths stay as they are (no migration). High score entries for Keen 2 store cities instead of parts (Keen 2's own entry format, own file). |
| Settings | `user://settings.cfg` | Shared: display, sound, keys and extras are the same choices for both games. Keen 1-only options (Extra levels) are hidden in Keen 2's menu. |
| Pictures behind levels | `BackdropPictures` uses `res://assets/backgrounds` (`backdrop_pictures.gd:16`) | Optional folder parameter; Keen 2 uses `res://assets/backgrounds/keen2`. The player's own folder is already per game (next to the data). *B3:* not yet; `Keen2View` makes no `BackdropPictures`, so `GameScreen._apply_backdrop` shows none (and never Keen 1's). No shared change. |
| Start screen icon | `GameCatalog.games()` returns only Keen 1 (`game_catalog.gd:20-25`) | Append a Keen 2 entry (title "Keen 2", scene `GameLaunch.KEEN_2_SCENE`, files `Keen2Files.locate()`). Keen 1 stays first. *B2 also:* `Game.data_folder` (default `game_data/keen1`), so the launcher's "files not found" text names the right folder; `MISSING_FILES_MESSAGE` takes the folder as a second `%s` and gives Keen 1 the same text as before. The existing launcher test that expected exactly one game now expects two (approved by the architect). |
| Start Keen 2 from the command line | `--level=N` / `--ending` always start Keen 1 (`launcher.gd:35-36`) | New option `--game=2` that, together with `--level=`, starts Keen 2. Without it nothing changes. *B2:* `--game=2` alone also skips the start screen (`GameLaunch.scene_for`). As for Keen 1, "Choose Game" with these options on the command line comes straight back to the game. |
| Keen's movement | `KeenBody` starts without the pogo, ice freezes him | Reuse as is; Keen 2 sets `has_pogo = true` at the start (*built in B3:* `Keen2Inventory` starts with it and `Keen2LevelSession.begin` sets it; `KeenBody` and the sprite numbers 0-27 unchanged). The stun of the Vorticon youth: try `freeze()` first; if the frames or the friction differ (research §5), add an optional stun mode to `KeenBody` (Keen 1 default unchanged). Sprite numbers 0-27 are the same in both games. *Built in B4, without a shared change:* `freeze()` does not fit (its frames change every 25 ticks instead of 26, it plays Keen 1's frozen sound and pushes Keen, and it has no "shorten"), so the stun lives in `Keen2Body extends KeenBody` (`src/keen2/keen/`): `stun(direction)`, `is_stunned()`, `shorten_stun()`, and overrides of `reset`, `step` (buttons ignored while stunned; falling and friction stay `KeenBody`'s) and `sprite_index` (28/29, then 31). `Keen2LevelSession` overrides `_create_keen` so that its Keens are `Keen2Body`s (constructor `placed`, because a static `create` with another return type cannot override the parent's). `KeenBody` is not changed at all. |
| Riding a platform or Scrub | `LevelCollision` only knows tiles | New hook: the session gives `KeenBody` a "carrier" (any actor with a top surface and a velocity); `KeenBody` stands on it and moves along. Keen 1 has no carriers, so its path does not change. Design this in B4, test it with fixtures. *Built in B4, without a shared change:* the hook already exists: `KeenBody` asks its `collision` for every floor (`floor_under`) and every downward move (`sweep_y`). `Keen2LevelSession` gives its Keens a `Keen2RidingCollision extends LevelCollision` whose two overrides add the tops of the carriers (`Keen2Carrier`: `Keen2Platform`, `Keen2Scrub`) as one-way floors; the enemies and shots keep the session's plain `LevelCollision`. Each carrier records `last_move`; `Keen2LevelSession._resolve_hits` first moves every Keen who stands on a carrier (its top before the move) by that much, through the tiles, and then runs `LevelSession`'s hits. A carrier pushes Keen out sideways when he runs into it (`Keen2Carrier.touch_keen`). No exit while riding: `_touch_tiles` notes whether Keen rides and `_is_exit` then says no. Keen 1 never makes a `Keen2RidingCollision`, so `KeenBody`, `LevelCollision` and `LevelSession` are byte for byte the same as on `main` (B4 changed no file outside `src/keen2/`). The riding collision does not follow `LevelSession.open_sides` (Keen 2 has no open sides). |
| Tiles that change while playing (bridge, Tantalus wreck, switches, Elder lights) | Keen 1 already changes tiles (items, doors) through `tile_changed` | Reuse. Check that xBRZ and HD layers update per cell as well. *Built in B5, without a shared change:* every change in a level goes through `LevelSession.set_tile` (`Keen2Bridge`, `Keen2Switches`, `Keen2Tantalus`, the Elder's light), so `tile_changed` reaches `LevelMap.set_tile`, which redraws that one cell with the tile set in use; xBRZ and HD are only other tile sets (`use_tile_set`), so they change per cell too (checked with a screenshot after F5). Map 81 is no `LevelSession`: `Keen2EarthExplosion` has its own `tile_changed` signal with the same meaning (it changes its `LevelData` and announces the cell), which `Keen2View` connects to the same `LevelMap.set_tile`. |
| Darkness | Nothing | Keen 2 only (`Keen2Darkness`), drawn as a layer or shader on top of `GameScreen`; it must also work with xBRZ, HD and widescreen. *Built in B5, without a shared change:* `Keen2Darkness extends CanvasModulate`, which `Keen2View` adds to the World viewport. It tints the level's own canvas (tiles in any graphics style, Keen, the actors) to `DARK_BRIGHTNESS` (0.3, an estimate, one constant); the HUD and the windows are on the `Ui` CanvasLayer and stay as they are, also in widescreen. Not darkened: the backdrop pictures (their own CanvasLayer; Keen 2 has none until B8, which must decide) and the second player's viewport (B9). `Keen2LevelSession.is_dark()` is real now and announces changes with `lights_changed`. |
| The level session | `LevelSession` mixes the generic core with Keen 1's enemies, statues and ship parts (`level_session.gd:46-79`, `311-337`, `420-432`) | Do **not** change its behaviour. Preferred: `Keen2LevelSession extends LevelSession` and overrides only what Keen 2 does differently. If a method that must be overridden is static or private (`_create_enemy` is static), add a new instance hook whose default calls the existing code, so Keen 1 runs the same lines as before. If that becomes awkward, `Keen2LevelSession` uses composition (owns the collision, the actors and Keen) and copies none of the Keen 1 rules. *Built in B3:* subclassing. `LevelSession.create` now calls the new instance method `_set_up(...)`, which holds its old body in the same order; three hooks whose default is the old code: `_is_item(tile)` (was `properties.is_item(tile)`), `_touch_special_tile(cell, tile)` (the teleporter and statue branches of `_touch_tiles`, reached in the same `elif` order) and `_create_shot(start, direction)` (was `RaygunShot.create`). `Keen2LevelSession` (constructor `begin`, because a static `create` with another return type cannot override the parent's) overrides `_spawn_enemies` (already an instance method: no enemies until B4), `_is_item` (no ship parts), `_touch_special_tile` (22/24 do nothing) and `_create_shot` (`Keen2Shot`, Keen 2's shot sprites 122-125). *B4:* `_spawn_enemies` now spawns info values 1-6 (`create_enemy`), and it also overrides `_create_keen` (`Keen2Body` with the riding collision), `_resolve_hits` (carry the riders first), `_shoot_keens` (an enemy shot only shortens a stun, and may hit other enemies), `_touch_tiles` and `_is_exit` (no exit while riding). All of them already existed as instance methods, so `LevelSession` needed no new hook. The enemies extend the shared `Enemy` (through `Keen2Enemy`) and the enemy shot `Keen2Shot`/`RaygunShot`, without changing them. |
| The Tantalus Ray, the Earth exploding, the Elder's messages (B5) | Keen 1's hint window: `LevelSession.hint_touched` and `GameWindow.show_lines` in `level_view.gd` | *Built in B5, without a shared change:* the pogo button reaches the switches through `Keen2Body`, which overrides `KeenBody._handle_pogo_button` (an instance method, so no hook was needed) and asks `switch_user` (set by the session to `Keen2Switches.use_near`) first. `Keen2LevelSession` overrides `step_players` (nothing moves after the Tantalus Ray, the bridges step), `_touch_special_tile` (the Elder) and `_spawn_enemies` (the spark, nothing at a switch). The game over by the Tantalus Ray is `Keen2LevelPlay.State.EARTH_EXPLODED` and its signal `earth_exploded`, not a new `LevelSession.Outcome` (that enum is shared). The scene on map 81 is `Keen2EarthExplosion` (logic, testable headless) with `Keen2SpaceSprite` actors, drawn by the shared `ActorLayer`; `Keen2View` only shakes the screen, switches to map 81, steps the scene and shows GAME OVER. The Elder's message uses the shared `GameWindow`; EARTHPOW, which `Sound.Id` does not name, is played by `Keen2Sounds` on its own speaker, so `Sound` and `SoundPlayer` stay unchanged. |
| The game scene | `level_view.gd` (991 lines) is Keen 1's state machine on top of `GameScreen` (generic) | `Keen2View extends GameScreen`, built from small classes from the start (title and menu, map, level, ending, Earth explosion, texts). Keep every file under ~500 lines. *Built in B3:* `Keen2View` (~250 lines; its scene has the same node layout as `level_view.tscn`, because `GameScreen` finds its nodes by unique name), `Keen2LevelPlay` (the B3 course: level after level, death, game over), `Keen2GameData` (graphics, tile properties, sounds, FINALE.CK2). `GameScreen` needed no change. |
| HUD icons | `Hud` draws `StatusScreen.RAYGUN_TILE` and `KEYCARD_TILES`, Keen 1's tile numbers | *Built in B3:* `Hud` got the members `raygun_tile` and `keycard_icons` (defaults: those Keen 1 constants) and `Hud.keycard_tiles` an optional `icons` parameter (same default). `Keen2View` sets them to `Keen2Icons`: the first tile with the raygun/keycard behaviour. The ship parts are already optional (`with_parts`, off in levels 1-16). |
| Online and co-op | `Snapshot` sends 4 keycards and 4 ship parts; `OnlineProtocol.GAME_ID` does not name the episode | In B9: add the episode to the handshake (a Keen 1 host must refuse a Keen 2 guest), and a Keen 2 snapshot with cities instead of parts. Keen 1's messages stay byte for byte the same. |
| Tools | `export_graphics.gd`, `export_hd_sheets.gd`, `make_hd_graphics.sh`, `build_*.sh` assume `keen1` | Optional `GAME=keen2` (environment variable), default `keen1`. Builds copy `game_data/keen2` too when it exists. *B2 deviation:* `export_graphics.gd` and the data viewer take `-- --game=2` instead, the same option as the game itself (they are Godot scripts that already read user arguments); output `exported/keen2/`. The shell scripts can still use `GAME=keen2` when they get Keen 2 support. |

## The flow of Keen 2

```
Launcher ──click "Keen 2"──▶ keen2_view.tscn (Keen2View)
   ▲                            │ title (map 90) + main menu (shared Menu classes)
   │ "Choose Game"              ▼
   └──────────────────────── world map 80 (Keen2MapSession)
                                │ enter level 1-16
                                ▼
                              level (Keen2LevelSession)
                                │ exit door ─▶ back to map; city level done → city saved
                                │ Tantalus switch ─▶ Earth explodes (map 81) ─▶ game over
                                ▼
                    map with all 8 cities ─▶ ending (map 81 twice, FINALE.CK2, texts)
                                ─▶ high scores
```

In milestone B3, before the map and the menus exist, the flow is shorter:
level 1 (or `--level=N`) → exit → next level → … → level 16 → start screen;
death restarts the level, game over and Escape go back to the start screen
(see [gameplay.md](gameplay.md)).

## Deviations in B5

- `Keen2Bridge` lives in `level/`, not in `actors/` as planned: it changes
  tiles and is never drawn, so it is no `Actor`.
- The Tantalus game over is a state of `Keen2LevelPlay`, not a new
  `LevelSession.Outcome`: that enum is shared, and the session only has to
  stop (`tantalus_fired`).
- EARTHPOW is played by `Keen2Sounds` on its own speaker instead of a new
  `Sound.Id`, which would have been a change to a shared file.
- The gameplay choices (spark only hit by Keen, nothing spawns at a switch,
  explosions around the Earth's middle, the wreck stays whole, the chunks
  spread out) are listed in [gameplay.md](gameplay.md) with their reasons.

## Testing

- Most Keen 2 logic is tested with hand-made fixtures (`tests/fixtures.gd`
  style): small levels with a switch, a bridge, a platform, a spark. These
  run everywhere, also in the cloud.
- Real data: `tests/test_keen2_data.gd` (and later suites) call
  `Keen2Files.locate()` and `skip()` when it is null, like
  `test_keen1_data.gd`. Keen 2 is not shareware: in the cloud these suites
  skip unless the user uploads their own files to `game_data/keen2/` for that
  session. On the Mac they run.
- *B3:* stand-in data: `tests/test_keen2_stand_in.gd` copies the Keen 1
  shareware files under Keen 2's names and plays the levels through
  `Keen2LevelPlay`. `Keen2View` itself needs a running scene tree (the test
  runner has none: nodes added in `_initialize` only get `_ready` after it),
  so it is checked with `tools/scripted_play.gd` screenshots.
- *B3 deviation:* B2's test of the placeholder screen
  (`test_keen_2_placeholder` in `tests/test_keen2_files.gd`) was removed,
  because B3 replaces that screen; `tests/test_keen2_level.gd` checks the new
  scene instead. It is a Keen 2 test; no Keen 1 test file was touched.
- *B4:* `tests/test_keen2_enemies.gd` (spawning, each enemy, enemy shots,
  stun, friendly fire) and `tests/test_keen2_riding.gd` (Scrub crawling,
  platform, riding, no exit while riding) with hand-made levels; the
  stand-in suite plays every level with the enemies that Keen 1's info
  values become. Both new suites are listed in `tests/run_tests.gd`, the
  only line added to a file outside the Keen 2 suites.
- *B5:* `tests/test_keen2_switches.gd` (pogo button on and off a switch,
  bridges both ways, stopping, taking in, standing on one, the lights and
  the Vorticons in the dark, the Elder, the Elder message finders on a
  hand-made image) and `tests/test_keen2_tantalus.gd` (the machine's wreck
  and points, the switches of a wrecked and an intact machine, the scene on
  a small hand-made map 81). The B3/B4 tests that said "7 spawns nothing"
  now expect the spark (`test_keen2_level`, `test_keen2_enemies`); the
  stand-in suite presses the pogo button now and then and runs the Earth
  explosion on Keen 1's map 81. The two suites are two more lines in
  `tests/run_tests.gd`; nothing else outside `src/keen2/` and the Keen 2
  tests changed.
- Numbers that come from Commander Genius are marked *estimate* in the code,
  as for Keen 1, and listed at the bottom of the Keen 2 docs to check
  against the original (DOSBox) in B10.

## Rules that carry over

All hard rules in `CLAUDE.md` apply to Keen 2 as well: never commit game data
or anything derived from it, never use the name "Commander Keen" or its logo
as branding ("Keen 2" on the icon is fine), never decompile `KEEN2.EXE` code
(reading data tables is fine), never copy code from Commander Genius or other
projects. Extras are off by default, with the same exceptions the user chose
for Keen 1 (widescreen with HUD, pictures behind levels).
