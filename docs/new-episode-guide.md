# Adding another episode: a guide for Claude

For a future Claude Code session that is asked to add another episode of the
series (Keen 3, Keen 4, ...) to CommanderPerfect. It sums up what milestone
B1 (the start of Keen 2) found out, so the research is not done twice. Read
it before you plan anything. Keep it up to date: when a later milestone
teaches something general, add it under "Lessons learned".

Read first, in this order:

1. `CLAUDE.md` (hard rules, session routine) and `PROGRESS.md`.
2. This guide.
3. `docs/keen2/architecture.md`: the pattern used for Keen 2. Copy it for
   the new episode (`src/keen<n>/`, `docs/keen<n>/`, milestones
   `milestone-<letter><n>-<topic>`; Keen 2 used the letter `b`, so Keen 3
   would use `c`, and so on, unless the user picks something else).
4. `docs/keen2/research.md`: everything about episode 2, with a list of where
   in Commander Genius each topic lives. Much of it also holds for episode 3.

## 1. The three families

The six classic episodes are two different engines. Know which family the
new episode is in before you estimate anything.

| Family | Episodes | Engine | What CommanderPerfect can reuse |
|---|---|---|---|
| **Vorticons** | 1, 2, 3 | Same file formats, same physics, same tile property table in the EXE | Almost everything shared: decoders, EGA graphics, levels, `KeenBody`, collision, scaling, menus, sound synth, online. Each episode adds its own enemies, map rules, items and ending. |
| **Galaxy** | 4, 5, 6 | Completely different: Huffman-compressed `EGAGRAPH`, `GAMEMAPS`/`MAPHEAD` with Carmack + RLEW compression, three map planes, sloped floors, AdLib music and sound (`AUDIO.CK4`), new physics, actions/states, a 2.5D world map | Only the outer layer: launcher, menus, settings, saves, scaling shaders, xBRZ/HD pipeline, online transport, test runner. Plan it as a new engine: new decoders, new physics, new collision (slopes), an OPL (AdLib) emulator. Roughly as much work as Keen 1 was. |
| **Keen Dreams** | (between 3 and 4) | Its own engine, close to Galaxy | As Galaxy. Its source code was published under the GPL: our "no copied code" rule still applies; use it as documentation only. |

Episode 4 was researched in milestone D1: see `docs/keen4/research.md`,
`architecture.md` and `roadmap.md`. The short version: a new engine; the
Galaxy engine goes into `src/galaxy/` (for episodes 4-6) and the episode
into `src/keen4/`; the user's copy is v1.0 (sources know 1.4); Omnispeak is
the reference for numbers.

Episode 5 was researched in milestone E1: see `docs/keen5/research.md`,
`architecture.md` and `roadmap.md`. The short version: the Galaxy
readers of Keen 4 read it almost unchanged (two additive fields); the
game around the engine (screens, sessions, saves, title) had stayed in
`src/keen4/`, so E3-E11 lift it into a generic `src/galaxy/game/`, made
from Keen 4's classes while Keen 4 stays frozen (the user's choice). Keen
6 should build on `src/galaxy/game/`, not on `src/keen4/`. The user's copy
is v1.4, as Omnispeak; milestones `milestone-e<n>-<topic>`.

Episode 3 was researched in milestone C1: see `docs/keen3/research.md`.
The short version: the same family as 1 and 2; sounds and texts in the EXE
(text order help, end, previews, story); 624 tiles with a tile table that is
715 entries wide; 148 sprites (numbers from 31 on one lower than episode 2);
behaviours 27 (ankh) and 28 (single charge); map teleporters encoded in the
info layer (0x0Fsd); Messie, a creature Keen rides on the map; the Mangling
Machine in level 16 built from tiles.

## 2. Getting the game files

- **Shareware** (freely distributable): episode 1 (v1.1, already fetched by
  `tools/get_shareware.sh` from the PCjs diskette repository) and episode 4
  (v1.4; check whether `jeffpar/pcjs-gamedisks` has it before writing a
  fetch script).
- **Registered only**: episodes 2, 3, 5, 6. The user must supply their own
  files (Steam/GOG ship the episodes 1-3 in v1.31, and 4-6 in v1.4, which is
  likely but must be checked). In a cloud session there is no way to get them;
  ask the user to upload them for that session, or work with hand-made
  fixtures and let the user run the real-data tests on the Mac.
- Game files go to `game_data/keen<n>/` (ignored by git). Never commit them
  or anything derived from them. Real-data test suites skip without them.

## 3. Sources and the rules for using them

- **Commander Genius** (GPL): documentation only, never copied code. Clone it
  sparsely into the scratchpad, never into the repository:

  ```sh
  git clone -q --depth 1 --filter=blob:none --sparse \
      https://github.com/gerstrong/Commander-Genius.git <scratchpad>/cg
  git -C <scratchpad>/cg sparse-checkout set src/engine/keen/vorticon src/fileio
  ```

  Where things are (paths under `src/`):

  | Topic | Vorticons (1-3) | Galaxy (4-6) |
  |---|---|---|
  | EXE versions, unpacking, size table | `fileio/CExeFile.cpp` | same |
  | Tile property table offsets, tile count, pickup leftovers | `fileio/CTileLoader.cpp` | `engine/keen/galaxy/res/` |
  | Graphics headers, bitmap names | `engine/keen/vorticon/CEGAGraphicsVort.cpp`, `CEGALatch.cpp`, `CEGASprit.cpp` | `engine/keen/galaxy/res/` |
  | Sounds (file or inside the EXE) | `engine/keen/vorticon/CAudioVorticon.cpp` | `engine/keen/galaxy/res/` |
  | Level info values → enemies, per episode | `engine/keen/vorticon/CVorticonMapLoader.cpp` | `engine/keen/galaxy/ep4/`, `ep5/`, `ep6/` |
  | Enemies and objects | `engine/keen/vorticon/ai/` | `engine/keen/galaxy/ep<n>/ai/` |
  | Keen (player) | `engine/keen/vorticon/ai/CPlayer*.cpp`, `engine/core/CPhysicsSettings.cpp` | `engine/keen/galaxy/common/ai/CPlayer*.cpp` |
  | Items, switches, doors | `engine/keen/vorticon/CPlayerItems.cpp`, `ai/CPlayerLevel.cpp` | `galaxy/common/ai/` |
  | World map | `engine/keen/vorticon/playgame/CPlayGameWorldMap.cpp` | `galaxy/common/ai/CPlayerWM.cpp` |
  | Ending, special scenes | `engine/keen/vorticon/finale/` | `galaxy/ep<n>/` |
  | Strings in the EXE (offsets per version) | `fileio/CMessages.cpp`, `fileio/CPatcher.cpp` | same |
  | Sprite numbers | `engine/core/spritedefines.h` | the `EGAHEAD` names |
  | Status screen, high scores, story | `engine/keen/vorticon/CStatusScreen.cpp`, `CHighScores.cpp`, `CStory.cpp` | `galaxy/menu/` |

  Commander Genius has bugs and guesses. "CG does X" is not "the original
  does X". Mark such numbers *estimate* in the code.
- **Chocolate Keen** (`jamesfmackenzie/chocolatekeen`) is a reconstruction of
  the original v1.31 code of episodes 1-3. Since C1 (decision of the user,
  17-10-2026, in `CLAUDE.md`) its data tables **and** the facts and numbers
  in its behaviour code may be used (speeds, timings, chances, hit points),
  marked `(Choco)`; its code is never copied. It is far more reliable than
  Commander Genius for numbers. It counts in 145.65 Hz clock ticks with a
  frame every 6 ticks; `docs/keen3/research.md` explains how to convert to
  our 60 Hz units. Where it lives: `src/episodes/episode<n>.c/.h` (the
  episode's objects, map, scenes), `src/game/enemies.c`, `physics.c`,
  `gameplay.c`, `worldmap.c`, `menus.c`, `src/engine/`.
- **ModdingWiki and KeenWiki** (shikadi.net) are the best format
  documentation, but the cloud proxy blocks them (403). GitHub (clone, raw)
  works. On the Mac they can be read.
- **The original game in DOSBox** is the final judge for behaviour. Collect
  the questions that only the original can answer in one list, and check
  them in one milestone at the end.
- **Never decompile the EXE.** Reading data tables (tile properties, strings,
  sound blocks) out of it is fine.

## 4. The pattern: a new episode beside the old ones

The full version is `docs/keen2/architecture.md`. In short:

- Code that belongs to one episode is never changed for another one. Shared
  code only gets additive, behaviour-neutral changes (new optional
  parameters whose default is the old value). Prove it at the end of every
  milestone: the old tests pass unchanged, `gdlint` is clean, scripted play
  of the old episodes gives the same screenshots, and
  `git diff main -- <old episode files>` is empty.
- New code in `src/keen<n>/`, every class name starts with `Keen<n>` (class
  names are global in GDScript).
- Its own `user://keen<n>/` folder for saves and high scores; settings and
  keys are shared.
- Its own icon on the start screen (`GameCatalog`), its own scene (the
  counterpart of `level_view.gd`; build it from small classes from the
  start, `level_view.gd` grew to ~1000 lines).
- `--game=<n>` on the command line to start it directly.
- Online: the handshake must name the episode.

## 5. Things that will trip you up (from B1)

1. **Files that are not there.** Episodes 2 and 3 have no `SOUNDS`,
   `ENDTEXT`, `STORYTXT` or `HELPTEXT` file: all of it is inside the
   unpacked EXE. Do not make the file check require them.
2. **Find by content, not by offset.** Offsets differ per version (1.00,
   1.31, 1.34). Search for `SND\0`, known strings, and the plausible tile
   table (`TileProperties.find_in_image` already does a scan).
3. **The EXE is LZEXE-packed** in common versions; `DosExecutable` unpacks
   it. Offsets in our docs are "raw": in the image after the MZ header.
   Commander Genius sometimes gives file offsets (+512) or odd corrections.
4. **Tile counts differ** (611, 689, 715). Never hard-code them; take the
   count from `EGAHEAD`.
5. **The same info value means a different enemy** in each episode, and
   values ≥ 0x100 can be data (bridge offsets in episode 2).
6. **Tile and sprite numbers differ.** Use the behaviour from the tile table
   wherever possible; name the remaining hard-coded tiles as constants with a
   comment that says where the number comes from.
7. **New mechanics touch shared code**: moving floors (riding platforms),
   darkness, tiles that change while playing (they must also update in the
   xBRZ and HD layers), a game over that does not depend on lives.
8. **Collisions in `user://`**: saves, high scores and the bundled pictures
   behind levels are per episode.
9. **No shareware means no data in the cloud.** Plan tests with fixtures and
   let real-data suites skip.
10. **Name**: the icon says "Keen <n>", never "Commander Keen".

## 6. How the work is split

The user works with an architect and a developer. The architect (B1-style
milestone) researches, writes `docs/keen<n>/research.md`,
`architecture.md` and `roadmap.md` (in Dutch, with a concrete assignment and
"done when" per milestone), and reviews each milestone's diff against the
rules above. The developer builds one milestone per branch, with tests, and
updates `PROGRESS.md`.

## Lessons learned

Add one line per lesson, with the milestone where it was learned.

- B1: the cloud proxy blocks shikadi.net; a sparse clone of Commander Genius
  from GitHub works and is enough for most questions.
- C1: the user's files can be another version than Commander Genius and
  Chocolate Keen know (Keen 3 was 1.00, both sources are 1.31), and the
  offsets do not shift by one amount. Content search pays off.
- C1: Chocolate Keen's numbers disagree with Commander Genius in many places
  (Keen 3's ankh, Messie, the ninja; Keen 2's stun and Elite). Ask the user
  early which sources may be used; it decides how many estimates remain.
- C1: compare with the original during each milestone, not only at the end
  (B10 could not steer Keen reliably in js-dos and left the enemies as
  estimates). Things seen while Keen stands still can be measured any time.
- C1: subagents may not write report files; let them return the report as
  text and save what must last in `docs/` (the scratchpad is temporary).
- D1: the Galaxy headers can all be found by content in the unpacked EXE:
  the two Huffman trees by their shape, the offset tables by their end
  value, `MAPHEAD` by its tag. Do the same for Keen 5 and 6.
- D1: Omnispeak (github.com/sulix/omnispeak) is to Galaxy what Chocolate
  Keen is to Vorticons; clone it from GitHub (davidgow.net and shikadi.net
  are blocked in the cloud). The Keen 4 shareware is not in the PCjs
  repository: ask the user to upload their files.
- D1: keep the engine (`src/galaxy/`) apart from the episode, so later
  episodes never subclass an earlier one (Keen 3's three-level chain
  became brittle).
- C11: the original runs in js-dos in the cloud's headless Chromium
  (`tools/original/headless.js`); no browser pane needed.
- E1: run the existing readers over a new episode's files first, before
  reading any source: for Keen 5 they found every header by content in
  minutes and showed exactly the two places where Keen 4's assumptions do
  not hold (the tile border when the last background tiles are empty; the
  texts before the misc chunks). Check a derived count against a second
  table (TILEINFO's left/right tables hold only 0 and 1).
- E1: Keen 5 has no version text in its EXE; name the version by the
  program size (CG knows the unpacked sizes).
- E1: D1's split (engine in `src/galaxy/`, episode in `src/keen4/`) kept
  the engine clean, but the game around it (the screen chain, sessions,
  saves) went into the episode folder. For a next engine: put the
  episode-neutral game in the engine folder from the start, with the
  episode's numbers in a parameter object and its content behind hooks.
- E1: the user wants every episode to be playable exactly as the
  original with all options off; plan the proof (demos frame for frame
  in 4:3) for every Galaxy episode.
- E3: lift the game around the engine into generic classes made from the
  frozen episode (a rules object with its numbers, hooks for its
  content); the old episode stays untouched and keeps its proof.
- E4: one class per creature, each tested in a hand-made mini level; check
  every left/right sprite pair by eye on a sheet before trusting names.
- E5: a scratch `GAMEMAPS` with new info planes appended (the map header
  pointing at them) puts Keen or a creature anywhere in js-dos; the
  original reads it.
- E6: compare boxes and windows by EGA colour index; Omnispeak's
  coordinates can be a pixel off (Keen 5's KEYCARD row).
- E7: lay the original's demo frames on ours (one of ours per logic frame,
  4:3) from the start: the shared step variable, the platform's stop on a
  tile edge and the sprite order were found only that way.
- E8: js-dos audio runs about 12 % slow; compare spectra with a time
  factor, not by the clock.
- E10: an episode drawn with black (space, stripes, doors) needs its own
  open-sky rule (flood from the star tiles and the map edge), not the
  sky-colour-at-the-edge rule.
- E11: a new online game id goes at the end of `GAME_IDS` and boxes go by
  name, so the older episodes' bytes stay the same.
- E12: Omnispeak is a transcription; where its code cannot do what the
  original is seen to do (a tile loop that never runs, a chance read the
  other way round), the original wins. Watch every creature once.
- E12: js-dos runs 2-4 tics a frame; before changing a rule for a few
  pixels, play ours with those frame lengths (the elevator's 8 px, a
  creature's half-step phase were the frames, not the rules).
- E12: find sprites in recorded frames by all their opaque pixels (numpy,
  a dozen sample pixels first): seconds per recording, and exact, where
  colour tracking was off by 3 px (E4's Ampton).
- E12: prove "all options off" twice: the pixels against the original's
  recordings, and a suite that switches every option off and checks the
  nodes (viewport size, no picture, no cleared tiles, no scaled textures,
  sprites on the original's pixels), since headless tests see no pixels.

## Keen 6 on the Galaxy game

Build Keen 6 on `src/galaxy/game/` (E3-E12), not on `src/keen4/`. Since
E13 **both Keen 4 and Keen 5 play on it** (`Keen4View` and `Keen5View`
extend `GalaxyOnlineScreen`), so there are two working examples: Keen 5
for an episode written on the shared game from the start, Keen 4 for one
that keeps older ways through the rules' flags (`original_sprite_order`,
`music_stops_between_maps`, ... all true by default: a new episode leaves
them alone). A fix in the shared game now reaches both episodes; run both
episodes' suites, demo suites and regression pictures after one.
`Keen6View extends GalaxyOnlineScreen` gets the whole chain (level and
map sessions, flow, front with title loop, help, end and high scores,
control panel and saves, co-op and online) and fills in:

- **`GalaxyGameRules`** (a `Keen6Episode.game_rules()`): names and
  folders (`name`, `data_folder`, `data_dir_option`, `user_folder`,
  `game_id`), file readers (`locate_files`, `load_data`), maps
  (`world_map`, `first_level`, `last_level`, `last_map`, `missing_maps`),
  info values (Keen's starts, scroll blocks: Keen 6 has column blocks,
  items), sprites (`sprites`, Keen standing, map Keen, `demo_sign_sprite`),
  a new game's numbers, the pictures behind the levels (`backdrop_folder`,
  `sky_tiles`, `make_backdrops`), the map flags, the texts and pictures
  counted from the end (boxes, countdown, title, story, credits, help,
  end and secret end, menu cards, watch, Paddle War), the high scores,
  the songs of the story, end, game over and help, the sound table
  (`sound_count`, `song_count`, `sound_names`, `map_songs`), save slots.
  Every field and Keen 5's value is in `docs/keen5/architecture.md`,
  "`GalaxyGameRules`".
- **The hooks** (same file, "The hooks"): `_new_session`,
  `_new_map_session`, `_new_inventory`, `_new_progress`,
  `_new_status_window`, `_new_saved_game`, `_new_box_names`,
  `_new_online_state`; in the sessions `_new_keen`, `_place_info` (the
  creatures), `_place_extras`, `_runs_own_frame`; in the flow
  `_done_value`, `_after_level_done`, `_loading_box`, `_game_over` (a
  `GalaxyScene`), `_status_map`; in the front `_cheat_end`, `_give_items`,
  `_high_score_count`; the status window's `_draw_middle` and
  `_draw_bottom`.
- What is Keen 6's own (its creatures, Keen's extras such as the hook and
  the ropes, the map's rides) goes in `src/keen6/`, one class per
  creature, as Keen 5's `src/keen5/actors/`.
- **Lessons of E13** (Keen 4 moved onto the shared game): GDScript refuses
  a static function in a subclass whose parameters differ from the
  parent's, so give an episode's own constructors their own names
  (`start_level`, `create_keen5`) or keep the parent's parameters and add
  defaults; a subclass cannot redeclare a member, an enum or a constant of
  its parent, so take care with names that an episode's tests may want;
  and compare a move like this one frame by frame with a scripted session
  on the old build (a `git worktree`), not only with the tests: a hash of
  the window every frame finds what the suites do not reach.
