# CommanderPerfect: instructions for Claude

CommanderPerfect is a fan-made engine, built in Godot, that plays Keen 1 using
the player's own original game files, with modern extras: native macOS and
Windows builds, widescreen, a higher frame rate, xBRZ scaling (toggle) and
Real-ESRGAN graphics. Singleplayer comes first; local co-op may follow later.

## Session routine

- **Start:** read `PROGRESS.md` to see what is done and what comes next.
- **End:** update `PROGRESS.md`: tick off finished work, note open bugs and
  decisions, and write down the next concrete step.
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
src/viewer/    Data viewer scene (main scene for now)
tests/         Headless test runner and test suites
tools/         Command-line tools (graphics export, shareware diskette extraction)
docs/          File format documentation
game_data/     The player's own game files (ignored by git)
```

## Commands

Godot 4.7 is required (`godot` must be on the PATH).

```sh
godot --headless --path . --import                                # first run: build the class cache
godot --headless --path . --script res://tests/run_tests.gd       # run all tests
godot --headless --path . --script res://tools/export_graphics.gd # dump graphics to exported/
godot --path .                                                    # open the data viewer
gdformat src tests tools && gdlint src tests tools                # format + lint (pip install gdtoolkit)
```

All tests must pass and `gdlint` must be clean before committing.

## Cloud sessions (claude.ai/code)

The cloud container starts without Godot and without game data, and its
network blocks the Godot download site and most game archives.

- **Godot:** build it from source (about 25 minutes on 4 cores, run it in the
  background):
  ```sh
  git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot
  pip install scons
  cd godot && scons platform=linuxbsd target=editor vulkan=no wayland=no d3d12=no accesskit=no -j4
  ln -sf "$PWD/bin/godot.linuxbsd.editor.x86_64" /usr/local/bin/godot
  ```
- **Game data:** the Keen 1 shareware release (v1.1, freely distributable) is
  available as a PCjs diskette image in the public GitHub repository
  `jeffpar/pcjs-gamedisks`, file `pcx86/game/id/commander_keen/KEEN1-V11.json`.
  Clone it with `--filter=blob:none --no-checkout`, check out only that file,
  then run `python3 tools/extract_pcjs_diskette.py KEEN1-V11.json game_data/keen1`.
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
