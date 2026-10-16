# CommanderPerfect: instructions for Claude

CommanderPerfect is a fan-made engine, built in Godot, that plays Keen 1 using
the player's own original game files, with modern extras: native macOS and
Windows builds, widescreen, a higher frame rate, xBRZ scaling (toggle) and
Real-ESRGAN graphics. Singleplayer comes first; local co-op may follow later.

## Session routine

- **Start:** read `PROGRESS.md` to see what is done and what comes next.
- **End:** update `PROGRESS.md`: tick off finished work, note open bugs and
  decisions, and write down the next concrete step.
- **Always rebuild the app** after changing the game: run
  `tools/build_macos.sh` (on the Mac). The user plays from
  `build/CommanderPerfect.app`, which is not updated by itself.
  `tools/build_windows.sh` makes `build/windows/` for a Windows PC.
- **Keep the original as it is:** extras (graphics, smooth motion, …) are
  options that are off by default, so the game looks like the original
  unless the player switches them on.
- Work per milestone on a branch named `milestone-<n>-<topic>`.
- Talk to the user in Dutch. Code, comments and commit messages are in English.

## Hard rules

- **Never commit original game data** or anything derived from it (decoded
  images, upscaled graphics, level dumps). Game files live in
  `game_data/keen1/`, which git ignores. Exports go to `exported/` (also
  ignored).
- **Never use the name "Commander Keen" or its logo** as branding. Saying the
  engine "plays Keen 1" is fine.
- **Do not decompile `KEEN1.EXE` code.** Behaviour is rebuilt from public
  documentation and from watching the game. Reading data tables out of the
  EXE (tile properties etc.) is fine.
- **No copied code** from other projects (Commander Genius is GPL). Use them as
  documentation only and write our own implementation.

## Layout

```
src/data/      Reading the original files (decompression, EGA graphics, levels)
src/level/     Drawing a level (TileSet, TileMapLayer, camera) and tile collisions
src/graphics/  xBRZ, HD graphics (Real-ESRGAN sheets), loading them, the scaling shader
src/keen/      Keen: movement physics, input, sprite
src/actors/    Everything else that moves: enemies, shots, opening doors
src/map/       The world map: Keen walking, level entrances, teleporters
src/sound/     PC speaker sounds: synthesis and playback
src/launcher/  The start screen: the CommanderPerfect picture and an icon per game
src/menu/      Menus: main menu, save slots, controls, options, name entry, online
src/online/    Playing online: ENet/Steam transports, the join handshake, snapshots
src/game/      Game screen (main scene), LevelSession, Inventory, the ending, title and
               high scores, settings, saved games
src/viewer/    Data viewer scene
tests/         Headless test runner and test suites
tools/         Command-line tools (graphics export, shareware diskette extraction,
               scripted play with screenshots, HD sheets, builds, the app icon)
docs/          File formats, Keen's physics, enemies and items, the world map, sounds,
               menus, graphics (xBRZ, HD, smooth motion), two players, online
addons/        GodotSteam (Steam for online play; macOS and Windows libraries only)
assets/        Our own pictures (start screen, app icon); never anything from the game files
game_data/     The player's own game files (ignored by git)
```

## Commands

Godot 4.7 is required (`godot` must be on the PATH).

```sh
godot --headless --path . --import                                # first run: build the class cache
godot --headless --path . --script res://tests/run_tests.gd       # run all tests
godot --headless --path . --script res://tools/export_graphics.gd # dump graphics to exported/
godot --path .                                                    # start the game (title screen)
godot --path . -- --level=80                                      # start on the world map (or level N)
godot --path . res://src/viewer/data_viewer.tscn                  # open the data viewer
gdformat src tests tools && gdlint src tests tools                # format + lint (pip install gdtoolkit)
STEPS="20:Space,30:shot_menu" OUT=/tmp/shots godot --path . --script res://tools/scripted_play.gd  # scripted keys + screenshots
tools/build_macos.sh && tools/build_windows.sh                    # builds in build/
REALESRGAN=path/to/realesrgan-ncnn-vulkan tools/make_hd_graphics.sh  # the player's own HD graphics
```

All tests must pass and `gdlint` must be clean before committing.

## Cloud sessions (claude.ai/code)

The cloud container starts without Godot and without game data. The Godot
download site and most game archives are blocked, but GitHub release assets
are not.

- **Godot:** download the official build from GitHub Releases (takes about a
  minute; building from source is not needed):
  ```sh
  mkdir -p ~/godot && cd ~/godot
  base=https://github.com/godotengine/godot/releases/download/4.7.2-stable
  curl -sSLO "$base/Godot_v4.7.2-stable_linux.x86_64.zip" && curl -sSLO "$base/SHA512-SUMS.txt"
  grep 'stable_linux.x86_64.zip' SHA512-SUMS.txt | sha512sum -c
  unzip -q Godot_v4.7.2-stable_linux.x86_64.zip
  ln -sf "$PWD/Godot_v4.7.2-stable_linux.x86_64" /usr/local/bin/godot
  ```
- **Game data:** run `tools/get_shareware.sh`. It downloads the Keen 1
  shareware release (v1.1, freely distributable) as a PCjs diskette image
  from the public GitHub repository `jeffpar/pcjs-gamedisks` (file
  `pcx86/game/id/commander_keen/KEEN1-V11.json`) and unpacks it with
  `tools/extract_pcjs_diskette.py` into `game_data/keen1`.
- **Screenshots:** `xvfb-run -a godot --path . --rendering-driver opengl3
  --write-movie /tmp/shot.png --quit-after 20` saves rendered frames as PNG.

## Code style

- Static typing everywhere (`var x: int`, `-> void`, `:=`).
- Files `snake_case.gd`, classes `PascalCase` via `class_name` (not for tests
  and tools).
- Every script starts with a `##` doc comment that explains its purpose.
  Comments explain *why*, not *what*.
- No magic numbers: name them as constants.
- Small functions with a single job; private members start with `_`.
- Loaders return `null` / an empty array on failure and report the reason
  with `push_error`.
- When you learn something about a file format, add it to
  `docs/file-formats.md`.
