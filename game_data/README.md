# Game data

CommanderPerfect does not contain the game itself: you need the files of the
original Keen 1 (episode 1). Put them here, directly in a folder called
`keen1` (upper or lower case does not matter):

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

Keen 2 (episode 2) is not shareware, so you need your own copy. Put its files
in a folder called `keen2` next to `keen1`: at least `KEEN2.EXE`,
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
