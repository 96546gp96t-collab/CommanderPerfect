# Languages and alien text: research

Branch `milestone-language` (the user's wish of 26-10-2026): (1) in the
settings of every game the language can be set to Dutch, and a new language
is added by putting a file in a folder, after which it shows up in a list
in the settings; (2) an option "translate alien text" that shows the
Standard Galactic Alphabet signs in the levels translated (into Dutch,
English, ...) in all games. This file is what was found before building;
the open choices for the user are in §6.

## Samenvatting (voor de gebruiker)

- **Taal:** de menu's van alle vijf de spellen komen uit maar twee klassen
  (Keen 1-3 en Keen 4-5), en de instellingen zijn al gedeeld
  (`settings.cfg`). Eén rij *Language* in elk Options-menu is genoeg; de
  keuze geldt dan voor alle spellen. Er is nog niets van vertalen in het
  project; we bouwen een eigen, eenvoudig talenbestand (Engels = sleutel,
  per regel de vertaling), zodat een nieuwe taal één bestand in een map is.
- **Lettertypes:** de spellen tekenen menu's met hun eigen originele
  lettertype; daarin zitten geen é, ë of ï (gecontroleerd in Keen 1, 4 en
  5). Nederlands zonder accenten is goed leesbaar; accenten kunnen we ook
  zelf bijtekenen.
- **Buitenaardse tekst** zit in elk spel anders:
  - Keen 1: hele bordjes met het woord erin getekend: EXIT (rood scherm),
    THIS IS NEAT (bij elk straalgeweer), DIE (bij gevaar), BEHOLD THE HOLY
    "POGO" STICK (level 5).
  - Keen 2 en 3: een **compleet alfabet als losse tegels**; die teksten
    lezen we automatisch uit de levels (TANTALUS met de stadsnamen,
    VORTIVILLE, LOWER VORTIVILLE, FORT VORTICON, KILL KEEN, CAPE
    CANAVORTA, ...), plus een paar hele bordjes zoals in Keen 1.
  - Keen 4 en 5: bordjes in de tegels (EXIT-deur, WATCH OUT, de
    zekeringwaarschuwing WARNING: FUSE STRUCTURE FRAGILE, blauwe panelen).
- **Alles blijft standaard zoals het origineel**: Engels en de
  buitenaardse tekst onvertaald, tot de speler het aanzet.

## 1. What is there now

### Settings

- `UserSettings` (`src/game/user_settings.gd`, `user://settings.cfg`) is
  loaded by every game and the launcher; a language belongs there (section
  `game`). There is no autoload.
- An option reaches all five games through two places: a row in
  `MenuController._options_menu` (Keen 1-3, `src/menu/menu_controller.gd`)
  and a row in `GalaxyMenuPages.options` (Keen 4-5). The Galaxy Options card
  has 8 rows; `MAX_ROWS` is 9, so one more fits, more scroll.
- No menu has left/right cycling; choices are cycled with Enter
  (`next_graphics`) or picked on a "radio" card (Galaxy Sound/Music). A
  language list fits a sub-menu in Keen 1-3 and a radio card in Keen 4-5.

### Texts the engine defines

About 250-300 strings, all hard-coded English literals: menus
(`menu_controller.gd`, `controls_pages.gd`, `galaxy_menu_pages.gd`,
`galaxy_menu_controller.gd`, `galaxy_coop_menu_controller.gd`,
`galaxy_menu_view.gd`), online pages (`online_text.gd`), messages on the
status line (`game_screen.gd`, the views, `status_line.gd`), the F1 help
lines (in the five `*_view.tscn`), the Keen 1 status screen labels
(`status_screen.gd`), the launcher message. Width limits: Keen 1-3 windows
are 38 characters wide in 4:3 and the Options labels are padded to 14
columns; the Keen 1 status screen has fixed columns; the Galaxy watch screen
is 160 px wide with key boxes at +90 px. Many tests check exact English
labels; English stays the default and must stay pixel-equal.

### Fonts

- Keen 1-3: the 8x8 EGALATCH font, indexed by code point: 32-126 ASCII,
  128-159 pictures, 160-255 an inverted copy. "ë" (235) would draw an
  inverted glyph.
- Keen 4-5: three proportional fonts; above 127 only the cursor/arrow
  glyphs (128-140) have a width. No accents.
- The launcher, the status line and the help line use Godot's own font
  (full Latin-1).

### Texts from the game files

Story, hints, Vorticon Elder messages, status boxes, endings, ship
messages, Galaxy level names, help pages, council messages, high score
words. Each already has a stable key (hint level, enum, run index, chunk +
page), so a translation file could use keys instead of the English text.
A translation of them is, however, derived from the original text (see
§6, question 1).

### Levels

- Keen 1-3: one tile plane (`LevelData`), drawn by `LevelMap`
  (TileMapLayer); cell (x, y) is at level pixels (x*16, y*16).
- Keen 4-5: background, foreground and info planes (`GalaxyMap`), drawn by
  `GalaxyLevelMap`.
- A Node2D under `World` in level pixels shows in both split-screen views
  and in widescreen without extra work (`ShipSmoke` does this). In Galaxy it
  stays below `GalaxyViewCover`. Hook points: where each view frames the
  camera after showing a level (`_frame_camera` / `_show_map`).

## 2. The alien alphabet in the five games

Standard Galactic Alphabet: one shape per Latin letter, no digits, no case;
"·-·" is a full stop.

| Game | How it is stored | What it says (found so far) |
|---|---|---|
| Keen 1 | Whole-word tiles | 167/168 EXIT (every level), 206+207 THIS IS / NEAT (next to every raygun), 260 and 440 DIE, 2x2 263+264 / 276+277 BEHOLD THE HOLY "POGO" STICK (level 5) |
| Keen 2 | Letters A-Z as tiles 507-532 (red on white), plus whole-word tiles (167/168 EXIT, 206+207, 16/17, 29/30, 249, 260, 440, ...) | Decoded from the levels: TANTALUS over LONDON, CAIRO, SYDNEY, NEW YORK, PARIS, ROME, MOSCOW, D C; on the map the city names and the room labels (GB, EB, EA, RC, HOME A, HOME B, WA, WB) |
| Keen 3 | Letters A-Z as tiles 351-376 (red on yellow), Latin A-Z as 533-558, whole-word tiles (283/284 EXIT, 251/252, 253/254, 347/348, 118, ...) | VORTIVILLE, LOWER / WEST VORTIVILLE, VALDEN PARK, EARTH, WATER, NEW VORTICON, CENTRAL PARK, SUBWAY, THE BONKS, NURSERY, BEENS, SCHOOL, KILL KEEN, HALS KITCHEN, FORT VORTICON, POOL, FORT CAVORT, FORT VORTA BELLA, CAPE CANAVORTA, BARRACKS, BRIG, and the whole alphabet with Latin letters in level 13 |
| Keen 4 | Signs in the tiles | EXIT signs (foreground 1062/1063/1080/1081), the SGA exit door in Border Village, WATCH OUT signs in the Pyramid of the Forbidden (KeenWiki) |
| Keen 5 | Signs in the tiles, a few single letter tiles (background 374-377, 392-395) | WARNING: FUSE STRUCTURE FRAGILE (STRCTURE before v1.4), the blue panels (background 674-678, 692-696, 710-714), EXIT signs |

Some words are spelled with pickups instead of letters (Keen 1 "HI" with
lollipops, Keen 3 "TH", Keen 5 "ID"); they disappear when picked up.

Published decodings: KeenWiki (Standard Galactic Alphabet, the level pages)
and cc314's SGA pages, read through search excerpts (the sites are blocked
in the cloud); the Keen 2/3 letter texts and the Keen 1 tiles were checked
in the files themselves.

## 3. Proposal: languages

- **Format:** one plain text file per language, `nl.txt`, UTF-8:

  ```
  # name = Nederlands
  New Game = Nieuw spel
  Sound = Geluid
  [alien]
  THIS IS NEAT = DIT IS TOF
  ```

  The English text is the key (the code keeps its literals and wraps them
  in one call, `Lang.text("New Game")`); a missing line falls back to
  English, so a half-finished language still works. A tool writes a
  template with every English string (`tools/language_template.gd`), which
  is also checked by a test so no string is forgotten.
- **Folders:** the languages that come with the app in `res://languages/`
  (added to the export filter), and a `languages/` folder next to the game
  files (as `game_data`) for languages the player adds. Every file found is
  in the list; its `name` line is what the list shows.
- **The choice:** a row *Language* in Options of Keen 1-3 (a sub-menu with
  the languages) and Keen 4-5 (a radio card); stored in `settings.cfg`,
  shared by every game and the launcher. Default English: then everything
  is exactly as now.
- **Accents:** the original fonts have none (see §6, question 2).
- **Lengths:** Dutch is 20-30 % longer; the Galaxy watch screen and the
  Keen 1 status screen need short words, checked with screenshots of every
  menu in Dutch.

## 4. Proposal: alien text

- **Option** *Alien text: original / translated* in Options of all five
  games, off by default, shared in `settings.cfg`.
- **Finding the text:** per game a table of sign tiles (a tile or a group
  of tiles → English text), and for Keen 2 and 3 the letter tiles read
  automatically (runs of letters in a row; rows directly under each other
  form one sign). The English text then goes through the language file
  (`[alien]` section) to the chosen language.
- **Showing it:** a Node2D in level pixels over the signs, made when a level
  or map is shown; works in split-screen, widescreen and online (only
  drawing, nothing changes in the game state). See §6, question 3.

## 5. Milestones

| # | Work | Estimate |
|---|---|---|
| L1 | Language files, the Language row in all five games, every engine string through `Lang`, Dutch, template tool, tests, screenshots | ~3-4 h |
| L2 | Alien text: tables for Keen 1-5, letter reading for Keen 2-3, the overlay, the option, Dutch and English texts, tests, screenshots | ~3-4 h |

## 6. Open questions for the user

1. Which texts get a language: only the engine's own (menus, messages,
   help lines), or also the texts from the game files (story, hints,
   endings, help pages)? A translation of the latter is derived from the
   original and the hard rules keep that out of git.
2. Accents in Dutch: draw them ourselves on the original letters (é, ë, ï),
   or write without accents?
3. How the alien text shows: painted over the sign in the sign's own
   colours, a label above the sign, or a label only when Keen is close?
4. Where players put a language of their own.

### The user's answers (26/27-10-2026)

1. **All texts**, also those from the game files (story, hints, endings,
   help pages, level names, ...), and the Dutch translation of them goes
   **into git** as an exception to the hard rule (recorded in CLAUDE.md).
2. **No accents**: Dutch is written without them, and accented letters in
   a language file are folded to plain ones (é → e) for the original fonts.
3. The alien text shows **as a label only when Keen is close** to the sign;
   the sign itself stays as it is.
4. A player's own languages go in a folder **`languages` next to
   `game_data`** (next to the app); the languages that come with the game
   are inside the app. Every language found is in the list.
