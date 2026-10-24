# CommanderPerfect

A fan-made engine, built with [Godot](https://godotengine.org/), that plays
Keen series on modern computers co-op(!!!) with optional modern
extras: widescreen, smooth motion, xBRZ pixel-art scaling and AI-upscaled
graphics. It runs on macOS and Windows.

> **Status:** the whole game can be played from start to finish, with sound,
> menus, saved games and high scores. The modern extras are being tested.
> See [PROGRESS.md](PROGRESS.md).

## Before you start: you need the original game

**CommanderPerfect is only an engine. It does not include the game itself.**
Like DOSBox, it needs the files of the original Keen series. 
Those files belong to the owners of the original game; they are
not in this repository and may not be added to it.

### Step 1: get the files

You only need the episodes you want to play; the start screen has an icon
for each episode, and an episode without its files says so when you pick it.

- **Keen 1 as shareware (free).** Episode 1 was released as freely
  distributable shareware. From the project folder, run:

  ```sh
  tools/get_shareware.sh
  ```

  This downloads release 1.1 from the PCjs diskette archive on GitHub, checks
  every file and puts it in the right place (step 2 is then done for you). It
  needs `curl` and `python3`.
- **Your own copy.** If you own the games, for example the *Commander Keen
  Complete Pack* on Steam or GOG, use the files of each episode from its
  install folder. Keen 4's shareware (1.4) is the whole episode too.

### Which versions work

The files are read by their content, not at fixed places, so versions that
were not tested should work as well:

| Episode | Tested | Should work too |
|---|---|---|
| Keen 1 | 1.1 (shareware) | 1.31 and 1.34 (Steam/GOG) |
| Keen 2 | 1.31 | 1.00 |
| Keen 3 | 1.00 | 1.31 (Steam/GOG) |
| Keen 4 | 1.0, 1.4 (shareware; Steam/GOG sell 1.4) | other 1.x |
| Keen 5 | 1.4 (Steam/GOG sell 1.4) | 1.0 |

The game looks like the version you have (Keen 4's 1.4, for example, has
red help pages); how it plays is the same.

### Step 2: put the files in `game_data/`

Each episode gets a folder of its own inside `game_data`: `keen1`, `keen2`,
`keen3`, `keen4` and `keen5` (create the ones you need). For Keen 1 it must look like
this:

```
CommanderPerfect/
└── game_data/
    └── keen1/
        ├── EGAHEAD.CK1     ┐
        ├── EGALATCH.CK1    │ needed: without these
        ├── EGASPRIT.CK1    │ the game does not start
        ├── KEEN1.EXE       ┘
        ├── LEVEL01.CK1 … LEVEL16.CK1, LEVEL80.CK1, LEVEL81.CK1, LEVEL90.CK1
        ├── SOUNDS.CK1, FINALE.CK1, ENDTEXT.CK1, STORYTXT.CK1
        └── … (any other files of the episode may stay)
```

| Episode | Needed (the other files of the episode go along) |
|---|---|
| Keen 2 | `KEEN2.EXE`, `EGAHEAD.CK2`, `EGALATCH.CK2`, `EGASPRIT.CK2` |
| Keen 3 | `KEEN3.EXE`, `EGAHEAD.CK3`, `EGALATCH.CK3`, `EGASPRIT.CK3` |
| Keen 4 | `KEEN4E.EXE` (or `KEEN4.EXE`), `EGAGRAPH.CK4`, `GAMEMAPS.CK4`, `AUDIO.CK4` |
| Keen 5 | `KEEN5E.EXE` (or `KEEN5.EXE`), `EGAGRAPH.CK5`, `GAMEMAPS.CK5`, `AUDIO.CK5` |

- Put the files **directly** in the episode's folder, not in a folder
  inside it.
- Upper or lower case in the file names does not matter.
- The files can also stay somewhere else: then start the game with
  `godot --path . -- --data-dir=/path/to/keen1` (and `--data-dir-keen2=`,
  `--data-dir-keen3=`, `--data-dir-keen4=`, `--data-dir-keen5=` for the others).
- For a built app (see [Building the apps](#building-the-apps)) the folders
  go in `game_data/` **next to** `CommanderPerfect.app` or
  `CommanderPerfect.exe`. The build scripts copy them there for you.

If an episode's files are missing or in the wrong place, picking its icon
on the start screen says so and names the folder to put them in. More details per
episode: [game_data/README.md](game_data/README.md).

Git ignores everything in `game_data/` (except its README), so the files can
never end up in the repository by accident.

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
| F1 | Show or hide the line with the keys (in 4:3 also the line with the level and score) |
| F2 | Original view (320x200) or widescreen (16:9) |
| F3 | Pixels as on a 4:3 monitor, or square pixels |
| F4 | Full screen or a window |
| F5 | Graphics: original, xBRZ or HD |
| F6 | Smooth motion on or off |
| F7 | A second player joins or leaves (also in the menu) |
| F8 | Realistic look on or off |

The keys for walking, jumping, pogo and firing can be changed in the menu
(Controls). All settings are remembered.

### Two players on one keyboard

Press F7 at any moment during a game and a second player joins. In the
levels both play, sharing score, lives and items; on the world map player 1
walks alone. Close together the two share the screen; when they move apart
it splits in two, with a dark line in the middle. As in the original, the level is over
when one of them dies, and complete when one of them walks out.

| | Player 1 | Player 2 |
|---|---|---|
| Walk | A / D | Left / Right |
| Jump | Left Shift | . |
| Pogo | ` | / |
| Fire | Z | Right Shift |

These keys have their own pages in Controls. See
[docs/two-players.md](docs/two-players.md).

### The start screen

The game starts on the CommanderPerfect screen with an icon for each game
in the bottom left: Keen 1, 2, 3 and 4. Click one (or press Enter) to get to
its main menu. "Choose Game" in the main menu leads back here.

### Playing online

One player hosts, the other joins: Escape (or a key at the title) > Online
Game. Host through Steam (only your Steam friends see the game) or by IP
(UDP port 24800; over the internet the host forwards that port on his
router), and join from the list of your friends' games or by typing the
host's address. The Keen of whoever joins appears next to the host's;
each plays on his own screen, and only the host walks on the world map.
See [docs/online.md](docs/online.md).

Cheats, for testing:

| Keys | Cheat |
|---|---|
| Shift+N / Shift+P (or Page Down / Page Up) | Next / previous map |
| Shift+I | All keycards, the pogo stick and 99 raygun charges |
| Shift+G | God mode: nothing kills Keen, except falling out of the level |

## Modern extras

Out of the box the game looks like the original. Only widescreen is on, with
your lives, score, raygun and keycards in the top corners, and in widescreen
a level that has a picture of its own shows it behind it (level 1 for now;
Options > Backgrounds switches it off, see
[docs/graphics.md](docs/graphics.md)). Everything else is switched on in the
menu (Options) or with F5, F6 and F8:

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

- **Realistic** (F8, all five games) gives the picture light and
  atmosphere: bright things glow, a colour mood per game, a faint vignette
  and film grain; the HUD and the menus stay as they are. More is coming
  (light and shadow, realistic backgrounds, AI graphics), see
  [docs/realistic/research.md](docs/realistic/research.md).

How all of this works: [docs/graphics.md](docs/graphics.md).

## Building the apps

```sh
tools/build_macos.sh    # build/CommanderPerfect.app (Intel and Apple Silicon)
tools/build_windows.sh  # build/windows/CommanderPerfect.exe (64-bit)
```

Both copy the episode folders in `game_data/` next to the app, so it
starts with a double click. For Windows, copy the whole `build/windows` folder to the PC. The
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
