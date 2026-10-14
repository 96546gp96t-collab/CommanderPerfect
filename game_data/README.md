# Game data

CommanderPerfect does not contain any of the original game files. Put your own
copy of Keen 1 here, in a folder called `keen1`:

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
- **Steam / GOG:** copy the episode 1 files from the install folder of the
  "Commander Keen Complete Pack".
- **Shareware:** episode 1 was released as freely distributable shareware.

Everything in this folder except this README is ignored by git, so the files
can never end up in the repository by accident. The `.gdignore` file stops the
Godot editor from trying to import them.

You can also keep the files elsewhere and start the game with
`-- --data-dir=/path/to/keen1`.

`tools/make_hd_graphics.sh` writes the HD graphics you make with Real-ESRGAN
into `keen1/hd/` (see `docs/graphics.md`). They are made from your own files,
so like them they stay here and are never shared.
