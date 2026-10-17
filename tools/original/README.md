# Watching the original game in js-dos

Tools to run an original `KEEN<n>.EXE` from the player's own files in js-dos
(DOSBox in the browser), served only on 127.0.0.1, and to record its raw
320x200 frames for measuring. Made in milestone C1 (Keen 3); they work for
every episode. Nothing here contains game data, and **nothing the tools make
may go into the repository**: work in a folder outside it (the scratchpad).

## Setting up (once per session)

```sh
W=<scratchpad>/original          # a work folder outside the repository
mkdir -p "$W/web" "$W/game/.jsdos" "$W/frames"
cp tools/original/index.html "$W/web/"
(cd "$W/web" && npm install js-dos@8.5.3)     # js-dos 8.5.3, backend dosbox
cp game_data/keen3/* "$W/game/"               # the player's own files
cat > "$W/game/.jsdos/dosbox.conf" <<'CONF'
[cpu]
cycles=auto
[render]
frameskip=0
[autoexec]
mount c .
c:
CONF
(cd "$W/game" && zip -qr ../web/game.jsdos .)
python3 -I tools/original/serve.py "$W/web" "$W/frames" 8765 &
```

Open `http://127.0.0.1:8765/index.html` in the built-in browser pane
(`preview_start` with that url). The autoexec does not start the game, so a
command line can be typed. `?bundle=other.jsdos` picks another bundle (for
example one with `cycles=fixed 6000`). Stop the server and close the tab
when done.

## Driving it (`javascript_tool` in the page)

- `await K.wait(3500)` after loading (boot), then `await K.typeU("KEEN3\n")`.
- `K.key(code, ms)` presses and releases, `K.raw(code, down)` holds. js-dos
  key codes: Enter 257, Esc 256, Space 32, F1 290, arrows left 263, right
  262, up 265, down 264, left Ctrl 341, left Shift 340, letters = ASCII upper
  case.
- `K.snap(name)` saves the last frame (`frames/<name>.rgb`, raw RGB);
  `K.startRec(max, everyMs)` … `await K.saveRec(name)` saves a recording and
  a log of every changed frame with its time.
- Analyse with `python3 -I tools/original/frames.py <framesdir> <rec>` (PNGs
  and a timeline), `sheet.py` (contact sheet), `crop.py` (enlarged crop with
  an 8-px grid), `track.py` (what moves), `snap2png.py`.

## Three pitfalls (fixed in `index.html`)

1. **Keys arriving seconds late** (why steering failed in B10): js-dos
   stamps keys with wall-clock time and delivers them only when the
   emulator's clock catches up. `K.raw` sends them with `timeMs: 0`; walking
   on the map and entering a level by script then works.
2. **The emulator pauses while the pane is hidden** (`document.hidden`); the
   page pretends to be always visible. Checked with DOS `TIME`: emulated time
   equals real time, also hidden.
3. **A stale bundle**: the bundle URL gets `?v=<now>`.

## Time base

js-dos only reports frames that changed, so the time of a frame is
`performance.now()`. Frame times fall on multiples of 1/70 s (the VGA
retrace). The Vorticon games draw about 24.2 times a second (every 3,
sometimes 2 retraces).

## Starting a level

`KEEN3 /LEVEL` (upper case, alone) loads a file `TEDLEVEL.CK3`, but copies
of the real levels gave a garbled screen or hung, and `/LEVEL5`-style
options start normally. Walk there instead: New Game, then on the map (Keen
3: up ~1 s, right ~0.25 s, Ctrl enters level 1). The cheats C+T+Space (all
keycards, charges) and G+O+D (god mode) help to survive while watching; god
mode does not protect against deadly tiles.
