# CommanderPerfect

A fan-made engine, built with [Godot](https://godotengine.org/), that plays
Keen 1 ("Marooned on Mars", 1990) on modern computers, with optional modern
extras: widescreen, a higher frame rate, xBRZ pixel-art scaling and
AI-upscaled graphics.

> **Status:** early development. Keen can walk, jump and pogo through every
> level, but there are no enemies, items or doors yet. See
> [PROGRESS.md](PROGRESS.md).

## You need your own game files

CommanderPerfect contains **no** original graphics, levels or sounds. Copy the
episode 1 files from your own copy (for example the *Commander Keen Complete
Pack* on Steam or GOG, or the shareware release) into `game_data/keen1/`. See
[game_data/README.md](game_data/README.md).

## Running

Requires [Godot 4.7](https://godotengine.org/download).

```sh
godot --path .                                    # play level 1
godot --path . -- --level=5                       # start in level 5
godot --path . -- --level=80                      # look around on the world map
godot --path . -- --data-dir=PATH                 # use game files from another folder
godot --path . res://src/viewer/data_viewer.tscn  # browse all graphics and levels
```

Or open the project in the Godot editor and press F5.

| Key | Action |
|---|---|
| Arrows / WASD / D-pad / left stick | Walk (look around on the world map) |
| Ctrl / Z / A button | Jump; hold longer to jump higher |
| Alt / X / B button | Take out or put away the pogo stick; hold jump to bounce higher |
| Page Up / Page Down / shoulder buttons | Previous / next level |
| F2 | Original view (320x200) or widescreen (16:9) |
| F3 | Pixels as on a 4:3 monitor, or square pixels |
| F1 | Show or hide the help line |

## Development

```sh
godot --headless --path . --import                                # first run only
godot --headless --path . --script res://tests/run_tests.gd       # tests
godot --headless --path . --script res://tools/export_graphics.gd # export graphics as PNG
```

File formats are documented in [docs/file-formats.md](docs/file-formats.md),
Keen's movement in [docs/keen-physics.md](docs/keen-physics.md).

## Legal

This is an unofficial fan project, not affiliated with or endorsed by
id Software, Apogee, ZeniMax or Microsoft. All rights to the original game
belong to their respective owners. The engine is written from public file
format documentation; it does not contain code or data from the original game.
