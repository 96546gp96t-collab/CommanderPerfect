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
   existing suites may not be edited; new suites may be added).
2. `gdlint` is clean.
3. With the Keen 1 shareware data: scripted play of the title screen, level
   1 and the world map gives the same screenshots before and after the
   milestone (`tools/scripted_play.gd`, compare the PNGs byte for byte).
4. `git diff main -- <Keen 1 only files>` is empty.

If a shared change cannot be made behaviour-neutral, stop and ask the user
before making it.

## Where the code goes

```
src/keen2/            Keen 2 only (all class names start with Keen2)
  data/               Keen2Files, Keen2Executable (texts, sounds, version), Keen2Texts
  actors/             Keen2Grunt, Keen2Youth, Keen2Elite, Keen2Scrub, Keen2GuardRobot,
                      Keen2Platform, Keen2Spark, Keen2Shot, Keen2Bridge
  level/              Keen2LevelSession, Keen2Switches, Keen2Darkness, Keen2Tantalus
  map/                Keen2MapSession (no teleporters, no ship), Keen2MapInfo
  game/               Keen2View (the scene; the Keen 2 counterpart of level_view.gd),
                      Keen2Progress, Keen2Inventory, Keen2StatusScreen, Keen2Ending,
                      Keen2EarthExplosion, Keen2Hud parts
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
| Sounds from inside `KEEN2.EXE` | `SoundFile.parse(bytes)` exists | None: `Keen2Executable` cuts the `SND` block out of the image and calls `parse`. The `Sound.Id` table is Keen 1's; Keen 2 passes its own name table (new optional parameter where sounds are looked up). |
| Texts from inside `KEEN2.EXE` | `TextDocument.layout(bytes, width)`, `ExeStrings.find/record_at` exist | None. |
| Saves and high scores apart from Keen 1 | `SaveGames.in_directory(path)`, `HighScores.load_from(path, ...)` exist | None: Keen 2 uses `user://keen2/saves` and `user://keen2/high_scores.json`. Keen 1's paths stay as they are (no migration). High score entries for Keen 2 store cities instead of parts (Keen 2's own entry format, own file). |
| Settings | `user://settings.cfg` | Shared: display, sound, keys and extras are the same choices for both games. Keen 1-only options (Extra levels) are hidden in Keen 2's menu. |
| Pictures behind levels | `BackdropPictures` uses `res://assets/backgrounds` (`backdrop_pictures.gd:16`) | Optional folder parameter; Keen 2 uses `res://assets/backgrounds/keen2`. The player's own folder is already per game (next to the data). |
| Start screen icon | `GameCatalog.games()` returns only Keen 1 (`game_catalog.gd:20-25`) | Append a Keen 2 entry (title "Keen 2", scene `GameLaunch.KEEN_2_SCENE`, files `Keen2Files.locate()`). Keen 1 stays first. *B2 also:* `Game.data_folder` (default `game_data/keen1`), so the launcher's "files not found" text names the right folder; `MISSING_FILES_MESSAGE` takes the folder as a second `%s` and gives Keen 1 the same text as before. The existing launcher test that expected exactly one game now expects two (approved by the architect). |
| Start Keen 2 from the command line | `--level=N` / `--ending` always start Keen 1 (`launcher.gd:35-36`) | New option `--game=2` that, together with `--level=`, starts Keen 2. Without it nothing changes. *B2:* `--game=2` alone also skips the start screen (`GameLaunch.scene_for`). As for Keen 1, "Choose Game" with these options on the command line comes straight back to the game. |
| Keen's movement | `KeenBody` starts without the pogo, ice freezes him | Reuse as is; Keen 2 sets `has_pogo = true` at the start. The stun of the Vorticon youth: try `freeze()` first; if the frames or the friction differ (research §5), add an optional stun mode to `KeenBody` (Keen 1 default unchanged). Sprite numbers 0-27 are the same in both games. |
| Riding a platform or Scrub | `LevelCollision` only knows tiles | New hook: the session gives `KeenBody` a "carrier" (any actor with a top surface and a velocity); `KeenBody` stands on it and moves along. Keen 1 has no carriers, so its path does not change. Design this in B4, test it with fixtures. |
| Tiles that change while playing (bridge, Tantalus wreck, switches, Elder lights) | Keen 1 already changes tiles (items, doors) through `tile_changed` | Reuse. Check that xBRZ and HD layers update per cell as well. |
| Darkness | Nothing | Keen 2 only (`Keen2Darkness`), drawn as a layer or shader on top of `GameScreen`; it must also work with xBRZ, HD and widescreen. |
| The level session | `LevelSession` mixes the generic core with Keen 1's enemies, statues and ship parts (`level_session.gd:46-79`, `311-337`, `420-432`) | Do **not** change its behaviour. Preferred: `Keen2LevelSession extends LevelSession` and overrides only what Keen 2 does differently. If a method that must be overridden is static or private (`_create_enemy` is static), add a new instance hook whose default calls the existing code, so Keen 1 runs the same lines as before. If that becomes awkward, `Keen2LevelSession` uses composition (owns the collision, the actors and Keen) and copies none of the Keen 1 rules. |
| The game scene | `level_view.gd` (991 lines) is Keen 1's state machine on top of `GameScreen` (generic) | `Keen2View extends GameScreen`, built from small classes from the start (title and menu, map, level, ending, Earth explosion, texts). Keep every file under ~500 lines. |
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

## Testing

- Most Keen 2 logic is tested with hand-made fixtures (`tests/fixtures.gd`
  style): small levels with a switch, a bridge, a platform, a spark. These
  run everywhere, also in the cloud.
- Real data: `tests/test_keen2_data.gd` (and later suites) call
  `Keen2Files.locate()` and `skip()` when it is null, like
  `test_keen1_data.gd`. Keen 2 is not shareware: in the cloud these suites
  skip unless the user uploads their own files to `game_data/keen2/` for that
  session. On the Mac they run.
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
