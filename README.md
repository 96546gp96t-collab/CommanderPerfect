# CommanderPerfect

A fan-made engine, built with [Godot](https://godotengine.org/), that plays
Keen 1 ("Marooned on Mars", 1990) on modern computers, with optional modern
extras: widescreen, a higher frame rate, xBRZ pixel-art scaling and
AI-upscaled graphics.

> **Status:** early development. The original files can be read and levels
> can be viewed with a scrolling camera, but Keen cannot be played yet. See
> [PROGRESS.md](PROGRESS.md).

## You need your own game files

CommanderPerfect contains **no** original graphics, levels or sounds. Copy the
episode 1 files from your own copy (for example the *Commander Keen Complete
Pack* on Steam or GOG, or the shareware release) into `game_data/keen1/`. See
[game_data/README.md](game_data/README.md).

## Running

Requires [Godot 4.7](https://godotengine.org/download).

```sh
godot --path .                                    # look around in level 1
godot --path . -- --level=80                      # start on the world map
godot --path . -- --data-dir=PATH                 # use game files from another folder
godot --path . res://src/viewer/data_viewer.tscn  # browse all graphics and levels
```

Or open the project in the Godot editor and press F5.

| Key | Action |
|---|---|
| Arrows / WASD / D-pad / left stick | Look around the level |
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

File formats are documented in [docs/file-formats.md](docs/file-formats.md).

## Legal

This is an unofficial fan project, not affiliated with or endorsed by
id Software, Apogee, ZeniMax or Microsoft. All rights to the original game
belong to their respective owners. The engine is written from public file
format documentation; it does not contain code or data from the original game.
