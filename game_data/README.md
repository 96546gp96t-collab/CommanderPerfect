# Game data

CommanderPerfect does not contain the game itself: you need the files of the
original episodes you want to play. Each episode has a folder of its own
here: `keen1`, `keen2`, `keen3`, `keen4` and `keen5`. You only need the episodes you
have; picking an episode without its files on the start screen names
the folder to put them in.

## Which versions work

Every piece of the files is found by its content, not at a fixed place, so
versions that were not tested should work as well.

| Episode | Folder | Tested | Should work too |
|---|---|---|---|
| Keen 1 | `keen1` | 1.1 (shareware) | 1.31 and 1.34 (Steam/GOG) |
| Keen 2 | `keen2` | 1.31 | 1.00 |
| Keen 3 | `keen3` | 1.00 | 1.31 (Steam/GOG) |
| Keen 4 | `keen4` | 1.0, 1.4 (shareware; Steam/GOG sell 1.4) | other 1.x |
| Keen 5 | `keen5` | 1.4 (Steam/GOG sell 1.4) | 1.0 |

The game looks like the version you have (Keen 4's 1.4, for example, has
red help pages); how it plays is the same.

## Keen 1

Put the files of Keen 1 (episode 1) directly in a folder called `keen1`
(upper or lower case does not matter):

```
game_data/
└── keen1/
    ├── EGAHEAD.CK1
    ├── EGALATCH.CK1
    ├── EGASPRIT.CK1
    ├── KEEN1.EXE
    ├── LEVEL01.CK1 … LEVEL16.CK1
    ├── LEVEL80.CK1
    └── … (the other files of the episode)
```

Where to get them:

- **Quickest:** run `tools/get_shareware.sh` from the project folder. It
  downloads the freely distributable shareware release 1.1, checks every file
  and puts it here.
- **Your own copy:** if you own the game, for example the "Commander Keen
  Complete Pack" on Steam or GOG, copy the episode 1 files from its install
  folder (the files ending in `.CK1`, and `KEEN1.EXE`).

Everything in this folder except this README is ignored by git, so the files
can never end up in the repository by accident. The `.gdignore` file stops the
Godot editor from trying to import them.

You can also keep the files elsewhere and start the game with
`-- --data-dir=/path/to/keen1`.

`tools/make_hd_graphics.sh` writes the HD graphics you make with Real-ESRGAN
into `keen1/hd/` (see `docs/graphics.md`). They are made from your own files,
so like them they stay here and are never shared.

## Keen 2

Keen 2 (episode 2) is not shareware, so you need your own copy (version 1.31 is
tested). Put its files in a folder called `keen2` next to `keen1`: at least `KEEN2.EXE`,
`EGAHEAD.CK2`, `EGALATCH.CK2` and `EGASPRIT.CK2`, plus `LEVEL01.CK2` …
`LEVEL16.CK2`, `LEVEL80.CK2`, `LEVEL81.CK2`, `LEVEL90.CK2` and `FINALE.CK2`.
There is no `SOUNDS.CK2` or text file: those are inside `KEEN2.EXE`. You can
also start with `-- --data-dir-keen2=/path/to/keen2`.

## Keen 3

Keen 3 (episode 3) is not shareware either, so you need your own copy. Put
its files in a folder called `keen3` next to `keen1`: at least `KEEN3.EXE`,
`EGAHEAD.CK3`, `EGALATCH.CK3` and `EGASPRIT.CK3`, plus `LEVEL01.CK3` …
`LEVEL16.CK3`, `LEVEL80.CK3`, `LEVEL81.CK3`, `LEVEL90.CK3` and `FINALE.CK3`.
As with Keen 2, the sounds and the texts are inside `KEEN3.EXE`. Version
1.00 is tested; 1.31 (Steam/GOG) should work as well, because everything is
found by its content. You can also start with
`-- --data-dir-keen3=/path/to/keen3`.

## Keen 4

Keen 4 (episode 4) is a different engine ("Galaxy"), with other files. Put
them in a folder called `keen4` next to `keen1`: `EGAGRAPH.CK4`,
`GAMEMAPS.CK4`, `AUDIO.CK4` and the program, `KEEN4E.EXE` (or
`KEEN4.EXE`). The headers of the other files are inside the program and are
found there by their content. Both versions are tested: 1.0 (the program
says "(v1.0)" when it starts) and the shareware 1.4 ("(v1.4)"; Steam and
GOG sell 1.4 as well). The game looks like the version you have: 1.4's
help and end pages are red with a frame, 1.0's light grey. Header files
next to the game (`EGAHEAD.CK4`, `EGADICT.CK4`, `MAPHEAD.CK4`,
`AUDIOHED.CK4`, `AUDIODCT.CK4`), as mods have, are used instead of the ones
in the program. `CONFIG.CK4` and the original's saved games are not read.
You can also start with `-- --game=4 --data-dir-keen4=/path/to/keen4`. The
data viewer (`-- --game=4`) shows everything that is read.

For the developers' tests a second copy in `keen4-v14` (or the folder in
the environment variable `KEEN4_V14_DIR`) is checked as v1.4 by
`tests/test_keen4_v14.gd`, next to the copy in `keen4`.

## Keen 5

Keen 5 (episode 5) uses the same engine and the same kind of files as
Keen 4. It was never shareware, so you need your own copy. Put its files
in a folder called `keen5` next to `keen1`: `EGAGRAPH.CK5`, `GAMEMAPS.CK5`,
`AUDIO.CK5` and the program, `KEEN5E.EXE` (or `KEEN5.EXE`). As with Keen 4
the headers of the other files are found inside the program by their
content, and header files next to the game win. Version 1.4 is tested (its
program prints no version; it is known by its size); 1.0 should work as
well. `CONFIG.CK5`, `KEEN5.VIF` and the original's saved games are not
read. You can also start with `-- --game=5 --data-dir-keen5=/path/to/keen5`.
The data viewer (`-- --game=5`) shows everything that is read. Keen 5 is
being built: for now its icon opens a "coming soon" screen.
