# CommanderPerfect

A fan-made engine, built with [Godot](https://godotengine.org/), that plays
Keen 1 ("Marooned on Mars", 1990) on modern computers, with optional modern
extras: widescreen, smooth motion, xBRZ pixel-art scaling and AI-upscaled
graphics. It runs on macOS and Windows.

> **Status:** the whole game can be played from start to finish, with sound,
> menus, saved games and high scores. The modern extras are being tested.
> See [PROGRESS.md](PROGRESS.md).

## You need the game files

CommanderPerfect contains **no** original graphics, levels or sounds: those
belong to the owners of the original game and are never part of this
repository. Episode 1 was released as freely distributable shareware, so the
quickest way to get them is:

```sh
tools/get_shareware.sh
```

This downloads the shareware release 1.1 (from the PCjs diskette archive on
GitHub), checks every file and unpacks it into `game_data/keen1/`. It needs
`curl` and `python3`.

You can also copy the episode 1 files from your own copy (for example the
*Commander Keen Complete Pack* on Steam or GOG) into `game_data/keen1/`. See
[game_data/README.md](game_data/README.md).

## Running

Requires [Godot 4.7](https://godotengine.org/download).

```sh
godot --path .                                    # play, starting at the title screen
godot --path . -- --level=5                       # start in level 5 (80 is the world map)
godot --path . -- --ending                        # watch the ending
godot --path . -- --data-dir=PATH                 # use game files from another folder
godot --path . res://src/viewer/data_viewer.tscn  # browse all graphics and levels
```

Or open the project in the Godot editor and press F5.

| Key | Action |
|---|---|
| Arrows / WASD / D-pad / left stick | Walk (on the world map also up and down) |
| Ctrl / Z / A button | Jump; hold longer to jump higher. On the world map: enter a level, use a teleporter or the ship |
| Alt / X / B button | Take out or put away the pogo stick; hold jump to bounce higher |
| Space / C / gamepad X button | Fire the raygun (once you have charges) |
| Enter / Start button | Status screen (score, lives, raygun, keycards, ship parts); also closes messages |
| Escape | Menu: new game, continue, save (on the world map), story, high scores, controls, options, quit |
| F1 | Show or hide the line with the keys |
| F2 | Original view (320x200) or widescreen (16:9) |
| F3 | Pixels as on a 4:3 monitor, or square pixels |
| F4 | Full screen or a window |
| F5 | Graphics: original, xBRZ or HD |
| F6 | Smooth motion on or off |

The keys for walking, jumping, pogo and firing can be changed in the menu
(Controls). All settings are remembered.

Cheats, for testing:

| Keys | Cheat |
|---|---|
| Shift+N / Shift+P (or Page Down / Page Up) | Next / previous map |
| Shift+I | All keycards, the pogo stick and 99 raygun charges |
| Shift+G | God mode: nothing kills Keen, except falling out of the level |

## Modern extras

Out of the box the game looks like the original. Only widescreen is on, with
your lives, score, raygun and keycards in the top corners. Everything else is
switched on in the menu (Options) or with F5 and F6:

- **Smooth motion** draws everything in between the 60 game ticks per
  second, for smooth movement on fast (120 Hz) screens.
- **xBRZ** smooths the pixel art: diagonal edges become clean lines, while
  straight edges and flat areas stay sharp.
- **HD** uses graphics that you upscale yourself with
  [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN). Download
  `realesrgan-ncnn-vulkan` for your system from its releases page, unpack it
  into `tools/realesrgan/` and run:

  ```sh
  tools/make_hd_graphics.sh
  ```

  The result goes to `game_data/keen1/hd/`. It is made from the original
  game files, so it stays on your computer and is never shared.

How all of this works: [docs/graphics.md](docs/graphics.md).

## Building the apps

```sh
tools/build_macos.sh    # build/CommanderPerfect.app (Intel and Apple Silicon)
tools/build_windows.sh  # build/windows/CommanderPerfect.exe (64-bit)
```

Both copy `game_data/keen1` next to the app, so it starts with a double
click. For Windows, copy the whole `build/windows` folder to the PC. The
builds need the Godot 4.7.2 export templates for macOS and Windows (Editor >
Manage Export Templates). The `build/` folder is ignored by git, because it
holds a copy of the game files.

## Development

```sh
godot --headless --path . --import                                # first run only
godot --headless --path . --script res://tests/run_tests.gd       # tests
gdformat src tests tools && gdlint src tests tools                # format + lint (pip install gdtoolkit)
godot --headless --path . --script res://tools/export_graphics.gd # export graphics as PNG
```

Documentation: file formats in [docs/file-formats.md](docs/file-formats.md),
Keen's movement in [docs/keen-physics.md](docs/keen-physics.md), items and
enemies in [docs/enemies.md](docs/enemies.md), the world map in
[docs/world-map.md](docs/world-map.md), sounds in [docs/sounds.md](docs/sounds.md),
menus and saving in [docs/menus.md](docs/menus.md), graphics in
[docs/graphics.md](docs/graphics.md), and the plan in
[docs/roadmap.md](docs/roadmap.md).

## Legal

This is an unofficial fan project, not affiliated with or endorsed by
id Software, Apogee, ZeniMax or Microsoft. All rights to the original game
belong to their respective owners. The engine is written from public file
format documentation; it does not contain code or data from the original game.
`tools/get_shareware.sh` only downloads the freely distributable shareware
release for your own use; xBRZ and Real-ESRGAN are used as ideas and as a
separate program, not as copied code.
