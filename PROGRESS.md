# Voortgang

Dit bestand is het geheugen van het project tussen sessies. Werk het aan het
eind van elke sessie bij.

## Mijlpalen

Wat elke mijlpaal precies inhoudt, staat in [docs/roadmap.md](docs/roadmap.md).
Hoe lang elke mijlpaal duurde: [docs/doorlooptijden.md](docs/doorlooptijden.md).

| # | Mijlpaal | Status |
|---|---|---|
| 1 | Originele bestanden inlezen in Godot (graphics, levels) + data viewer | ✅ Klaar (branch `milestone-1-data-loading`) |
| 2 | Levels tekenen met TileMapLayer, scrollen, widescreen-camera | ✅ Klaar (branch `milestone-2-level-view`) |
| 3 | Keen: lopen, springen, pogo, botsingen (tile-eigenschappen uit KEEN1.EXE) | ✅ Klaar en gemerged; de besturing voelt goed volgens de gebruiker (14-10-2026), naast DOSBox leggen staat nog open |
| 4 | Vijanden, items, deuren, sleutelkaarten, straalgeweer | ✅ Gemerged naar `main` (PR #4); speeltesten loopt nog |
| 5 | Wereldkaart, levelovergangen, scheepsonderdelen, einde | ✅ Getest door de gebruiker en gemerged naar `main` (PR #5) |
| 6 | Geluid, menu's, opslaan | ✅ Getest door de gebruiker en gemerged naar `main` (PR #6) |
| 7 | Hogere framerate (interpolatie), xBRZ met wisselknop, Real-ESRGAN-pipeline, Windows-build | ✅ Gemerged naar `main` (PR #7) |
| 8 | Twee spelers op één toetsenbord, dynamisch split-screen | ✅ Gemerged naar `main` (PR #8) |
| 9 | Online co-op: hosten en joinen via Steam of IP | ✅ Gemerged naar `main` (PR #9); speeltest online loopt nog |
| 10 | Startscherm met een icoon per spel | ✅ Gemerged naar `main` (PR #10) |
| 11 | Fixes: crash bij "Choose Game", nieuw app-icoon, achtergronden achter levels | 🔶 Gebouwd en getest door de gebruiker (branch `milestone-11-fixes`) |
| 11.2 | Extra: het schip als eigen level (onderdelen monteren), pogo-level opnieuw, onderdelen op de kaart | 🔶 In test bij de gebruiker (branch `milestone-11.2-extra-mini-game`) |

## Keen 2: mijlpalen B

Het tweede deel komt naast Keen 1; Keen 1 blijft zoals het is. Wat elke
mijlpaal inhoudt staat in [docs/keen2/roadmap.md](docs/keen2/roadmap.md), de
opzet in [docs/keen2/architecture.md](docs/keen2/architecture.md), en wat er
over Keen 2 bekend is in [docs/keen2/research.md](docs/keen2/research.md).
Voor een volgend deel: [docs/new-episode-guide.md](docs/new-episode-guide.md).

| # | Mijlpaal | Status |
|---|---|---|
| B1 | Onderzoek: code in kaart, Keen 2 uitgezocht, architectuur, mijlpalen, handleiding | ✅ Klaar (branch `milestone-b1-onderzoek`); vragen beantwoord op 16-10-2026 |
| B2 | De bestanden van Keen 2 inlezen, data viewer, tweede icoon op het startscherm | ✅ Klaar en gecontroleerd door de architect (branch `milestone-b2-bestanden`) |
| B3 | Een level spelen (Keen, items, deuren, uitgang) | ✅ Klaar en gecontroleerd door de architect (branch `milestone-b3-level`) |
| B4 | Vijanden en meerijden (platforms, Scrubs) | ✅ Klaar en gecontroleerd door de architect (branch `milestone-b4-vijanden`) |
| B5 | Schakelaars, bruggen, licht, de Tantalus-straal, de aarde ontploft | ✅ Klaar en gecontroleerd door de architect (branch `milestone-b5-tantalus`) |
| B5.1 | B1-B5 controleren en repareren met de echte Keen 2-bestanden (v1.31) | ✅ Getest door de gebruiker, "geen issues" (branch `milestone-b5.1-echte-data`) |
| B6 | Wereldkaart, steden, statusscherm, het einde | ✅ Getest door de gebruiker, "ziet er goed uit" (branch `milestone-b6-kaart-einde`) |
| B7 | Geluid, menu's, opslaan, highscores | ✅ Gebouwd (branch `milestone-b7-geluid-menus`) |
| B8 | Mooier maken (framerate, xBRZ, HD, achtergronden, builds) | ✅ Gebouwd; Real-ESRGAN bewust overgeslagen (branch `milestone-b8-extras`) |
| B9 | Co-op lokaal en online | 🔶 Gebouwd, in test bij de gebruiker (branch `milestone-b9-coop`) |
| B10 | Naast het origineel leggen (js-dos) | 🔶 Deels: schermen gemeten en aangepast; vijanden/levels niet te meten (branch `milestone-b10-origineel`) |

## Keen 3: mijlpalen C

Het derde deel komt naast Keen 1 en 2; die blijven zoals ze zijn. Wat elke
mijlpaal inhoudt staat in [docs/keen3/roadmap.md](docs/keen3/roadmap.md), de
opzet in [docs/keen3/architecture.md](docs/keen3/architecture.md), en wat er
over Keen 3 bekend is in [docs/keen3/research.md](docs/keen3/research.md).

| # | Mijlpaal | Status |
|---|---|---|
| C1 | Onderzoek: code in kaart, Keen 3-bestanden, Chocolate Keen, Commander Genius, js-dos, architectuur, mijlpalen | ✅ Klaar (branch `milestone-c1-onderzoek`); vragen aan de gebruiker open |
| C2 | De bestanden van Keen 3 inlezen, data viewer, derde icoon op het startscherm | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c2-bestanden`) |
| C3 | Een level spelen (Keen, items, de ankh, deuren, uitgangen) | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c3-level`); in test bij de gebruiker |
| C4 | Vijanden (grunt, youth, moeder, Meep, ninja, Foob) | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c4-vijanden`) |
| C5 | Bal, jack, platforms, wapens in de muur | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c5-mechaniek`) |
| C6 | Wereldkaart: teleporters, Messie, het schip, statusscherm | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c6-kaart`) |
| C7 | Mortimer, de Mangling Machine en het einde | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c7-mortimer-einde`) |
| C8 | Geluid, menu's, opslaan, highscores | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c8-geluid-menus`) |
| C9 | Mooier maken (framerate, xBRZ, achtergronden, builds) | ✅ Gebouwd, wacht op controle architect (branch `milestone-c9-extras`); Real-ESRGAN bewust overgeslagen |
| C10 | Co-op lokaal en online | ✅ Gebouwd, wacht op controle architect (branch `milestone-c10-coop`); Steam niet te testen hier |
| C11 | Naast het origineel (wat nog geschat is) | ✅ Gebouwd, wacht op controle architect (branch `milestone-c11-origineel`); een deel blijft geschat (research.md) |
| C12 | Keen 1 en 2 bijwerken met de getallen uit Chocolate Keen (ook de sprongen) | ⬜ |

## Mijlpaal C11: wat er nu is

Keen 3 naast het origineel gelegd in js-dos (KEEN3.EXE 1.00), dit keer
zonder browservenster: `tools/original/headless.js` stuurt de pagina in
een onzichtbare Chromium. Twee kladkopieën van de spelbestanden (alleen in
de scratchpad) brachten ons waar een script niet komt: een ankh naast
Keens start in level 1, en de ingang van level 1 op de kaart naar level 16
met Keen vlak voor het hart. Wat gemeten is staat in
`docs/keen3/research.md` ("Watched again in C11"), de afwijkingen in
`docs/keen3/architecture.md` ("Deviations in C11").

- [x] **Pixel voor pixel gelijk aan het origineel** (4:3): de titel, de
  highscores, het statusscherm van een nieuw spel, het eerste beeld van de
  kaart en van level 1, de vier pagina's van het einde, FINALE.CK3 met
  zijn vak, en de eindtekst. Alleen de stand van bewegende tiles en
  sprites verschilt.
- [x] **Gerepareerd na het meten:**
  - de vakken van het einde stonden 32 pixels te hoog (rij 14 in plaats
    van 18; het vak op FINALE.CK3 op rij 20);
  - het typen: elk opgeslagen teken (ook de spaties achter een regel) en
    elk regeleinde kost een letter (85,6 ms); pagina 1 duurt nu 13,2 s,
    het origineel 13,1 s (was 12,2 s);
  - onder het vak op FINALE.CK3 draait nu een balletje tot je een toets
    indrukt (tekens 9-12, elke 5 retraces);
  - de eindtekst staat nu in het leesvenster van het origineel: de titel
    rood op een grijze balk, 21 regels, onderaan "ESC to Exit / ↑ ↓ to
    Read" uit KEEN3.EXE, en twee spaties na een punt blijven staan;
  - een nieuwe highscorelijst heeft zeven namen (Yorpy, Gargile, Zzapp!,
    Yorpy, ...), niet drie.
- [x] **Bevestigd** (getallen bleven, nu "seen in the original, C11"): de
  ankh duurt 9,6 s (niet 15 of 21 s) en knippert aan het eind om de ~0,12
  s; titel en highscores wisselen elke 16,5 s; het einde: fade in stappen
  van ~114 ms, 120 retraces na een pagina, 400 retraces voor het vak op
  FINALE.CK3.
- [x] **Gemeten, niet veranderd (C12):** Keen 3 springt 53 px (wij 58), de
  pogo 50 px (wij 58) en met springknop 105 px (wij 109): net als Keen 2.
  Staat in `docs/keen3/choco-keen1-keen2.md`.
- **Blijft geschat** (met de reden in research.md, "Only the original can
  answer"): de vijanden (levenspunten, de moeder, de Meep, de ninja, de
  Foob), bal, jack en wapens in de muur, deuren, de done-bordjes, Messie
  op- en afstappen, level 9's start, Mortimers vakken op de pixel, de
  camera-flitsen. Die zijn in levels die een script niet haalt; met meer
  kladlevels (zoals de ankh) kan het later. Ook het eerste beeld van level
  16: dat staat in het origineel lager dan bij ons (level 1 klopt wel); de
  camera is gedeeld, dus dat wacht op een eigen regel voor Keen 3 of C12.
- **Niet gebouwd:** na de eindtekst toont het origineel de hal weer met
  een venster "GAME OVER", de score, "Congratulations! You got first
  place!" en "Enter your name:" met het draaiende balletje. Wij tonen GAME
  OVER op zwart en daarna het gedeelde naamvak. Dat vraagt een eigen
  naaminvoer in dat venster: een grotere wijziging, voor later.
- [x] **Tests:** nieuwe suite `test_keen3_original` (8 tests); drie
  bestaande Keen 3-tests veranderd omdat C11 de getallen verandert
  (`test_keen3_ending`: de plekken van de vakken; `test_keen3_scenes`: een
  regeleinde kost een letter). 66 suites, 764 tests (was 65 en 756), alle
  slagen, gdlint schoon.
- [x] **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen de C7-referentie (lege gebruikersmap): alles
  gelijk, ook `launcher.png`. `git diff milestone-c10-coop` op `src/keen2`,
  `tests/test_keen2_*.gd`, `tests/keen2_fixtures.gd`, `src/actors`,
  `src/map` en `src/game/level_view.gd` is leeg. Geen gedeeld bestand
  veranderd (alleen de testlijst).
- [x] **Bekeken in de app** (scratchpad `c11shots/`): titel, highscores,
  statusscherm, kaart, level 1, het einde vanaf het hart (met dezelfde
  kladkopie via `--data-dir-keen3`), FINALE.CK3 met het balletje, de
  eindtekst; elk naast het frame van het origineel.

## Mijlpaal C10: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
De regels en besluiten staan in `docs/keen3/gameplay.md` ("Two players
(C10)"), afwijkingen in `docs/keen3/architecture.md`, "Deviations in C10".

- [x] **Twee spelers op één toetsenbord:** F7 of "Add Player 2" in het
  menu, zoals bij Keen 1 en 2: speler 2 (blauwe helm) in het level, eigen
  toetsen (speler 1 WASD, speler 2 de pijltjes), split screen als ze uit
  elkaar gaan, gedeelde inventaris, één dood geldt voor beiden, één uitgang
  voor beiden. Op de kaart is er één Keen die door de toetsen van allebei
  wordt bestuurd.
- [x] **Online:** hosten en meedoen via IP of Steam, zoals bij Keen 1 en 2.
  `GAME_ID_KEEN_3` staat nu in `GAME_IDS`: wie met Keen 1 of 2 meedoet met
  een Keen 3-host, schakelt over naar Keen 3, en andersom (getest via IP
  op deze machine: een Keen 1-speler naar een Keen 3-host, een Keen
  3-speler naar een Keen 2-host). De snapshot stuurt Keen 3's eigen
  getallen mee (`Keen3OnlineState`): de gedane levels, de ankh-tijd van
  beide Keens, Keen 3's eigen geluiden, het beeld van de kaart en Messie.
  Ladingen en sleutelkaarten gaan al mee in de gedeelde inventaris, het
  schild van de ankh als figuur.
- [x] **Besluiten voor wat alleen Keen 3 heeft** (tabel in gameplay.md):
  - *Messie:* er is één Keen op de kaart, die rijdt; de toetsen van
    beide spelers zetten hem erop en eraf. Online rijdt de Keen van de
    host en ziet de meespeler Messie met Keen op haar rug.
  - *Teleporters en ingangen:* de ene Keen gaat; in het level begint
    speler 2 waar speler 1 begint. Online gaat de host, de meespeler ziet
    het flikkeren en het beeld springen.
  - *Het schip:* lokaal één bericht; online hetzelfde bericht op beide
    schermen, dat na 6 s vanzelf sluit.
  - *De ankh per speler:* wie hem pakt, is beschermd en krijgt het schild;
    de HUD toont een paneel per Keen ("1:9", "2:4"), het statusscherm
    beide tijden. Online ziet ieder zijn eigen tijd.
  - *Level 16:* Mortimer spreekt voor beiden (overslaan met Escape of een
    knop van een speler); online krijgt de meespeler Mortimer uit zijn
    eigen bestanden en ziet hij beide Keens eronder. De machine: beide
    Keens kunnen de vonken en het hart raken, en beide gaan dood door de
    armen en benen.
  - *Het einde:* speler 2 stopt, één Keen in de hal (zoals Keen 2);
    online kijkt ieder in zijn eigen tempo, en de meespeler wacht daarna
    bij zijn titel.
  - *Highscores, opslaan, laden:* zoals Keen 2: één score en één naam;
    opslaan op de kaart, speler 2 wordt niet bewaard; online alleen de
    host.
- [x] **Gedeelde code (alleen toevoegingen, Keen 1 en 2 byte voor byte
  gelijk):** `GAME_ID_KEEN_3` in `GAME_IDS`, drie gebeurtenissen achteraan
  (`SHIP_MESSAGE`, `MORTIMER`, `BORDER_FLASH`), geen nieuwe scène, en een
  optioneel deel `Snapshot.extra` (alleen verstuurd als het niet leeg is)
  met `OnlinePlay.extra`. Een test vergelijkt de snapshot en een
  gebeurtenis van Keen 1/2 byte voor byte met de vorm van vóór C10.
- [x] **Code:** nieuw `Keen3OnlineScreen` (tussen `Keen3MenuScreen` en
  `Keen3View`) en `Keen3OnlineState`; `Keen3LevelPlay.step_players`,
  `Keen3LevelSession.remove_player` (het schild gaat mee),
  `Keen3Hud.show_ankh_times`, het statusscherm met twee tijden.
- [x] **Tests:** nieuwe suites `test_keen3_coop` en `test_keen3_online`
  (o.a. een echte host en meespeler via ENet op deze machine). Twee Keen
  3-tests veranderd omdat C10 ze verandert (`test_keen3_files`: Keen 3
  staat nu in `GAME_IDS`; `test_keen3_menus`: het menu biedt nu speler 2).
  65 suites, 756 tests (was 63 en 730), alle slagen, gdlint schoon.
- [x] **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen de C7-referentie (lege gebruikersmap): alles
  gelijk, ook `launcher.png`. `git diff ccdea53` op `src/keen2`,
  `tests/test_keen2_*.gd`, `tests/keen2_fixtures.gd`, `src/actors`,
  `src/map` en `src/game/level_view.gd` is leeg.
- [x] **Bekeken in de app** (scratchpad `c10shots/`): twee spelers in
  levels 1, 3 en 16 en op de kaart (split screen, twee ankh-panelen, het
  statusscherm); online met een host en een meespeler in twee vensters
  (level 1 met de ankh van de meespeler, zijn statusscherm, de kaart met
  Messie en een teleporter, het schip, Mortimer, het einde) en het
  overschakelen van Keen 1 naar Keen 3 en van Keen 3 naar Keen 2.
- **Niet gedaan:** Steam kon hier niet getest worden (geen Steam op
  Linux; de logica is gedeeld en met tests gedekt). De Mac-build kan
  alleen op de Mac.

## Mijlpaal C9: wat er nu is

Gebouwd en nagekeken met de echte Keen 3-bestanden van de gebruiker
(1.00). De regels staan in `docs/keen3/gameplay.md` ("Extras (C9)"),
afwijkingen in `docs/keen3/architecture.md`, "Deviations in C9".

- **xBRZ (F5) en vloeiende beweging (F6)** werken voor alles van Keen 3
  via de gedeelde code; er hoefde niets te veranderen. Nagekeken in de
  code en met screenshots (beide aan, breedbeeld en 4:3): alle figuren
  (vijanden, schoten, golven, bal, jack, platforms met Keen erop, het
  schild van de ankh, Messie, de vonken en het hart, de Vorticon en Keen
  van het einde) zijn `Actor`s in de gedeelde `ActorLayer` en bewegen
  tussen de ticks door; het beeld op de kaart schuift mee met dezelfde
  fractie als Keen, en springt zonder tussenstappen bij een teleporter;
  de teleporters, de Mangling Machine, de bordjes en de flitsen van het
  einde veranderen tiles in de gedeelde `LevelMap` (ook in xBRZ); de HUD,
  het statusscherm, Mortimers vakken, titel, highscores, GAME OVER en
  `FINALE.CK3` wisselen mee met F5. De randflits en de fades zijn effen
  kleuren. Keen 3 heeft geen schudden van het scherm (Choco). Beide
  opties blijven standaard uit.
- **Plaatjes achter levels** (`Keen3BackdropPictures`): eigen map
  `assets/backgrounds/keen3/` (twaalf eigen plaatjes, zie hieronder) of die van de
  speler `game_data/keen3/backgrounds/levelNN.png` (ook .webp of .jpg);
  nooit die van Keen 1 of 2. Alleen in breedbeeld, met de optie
  Backgrounds (standaard aan). **Regel:** een level krijgt alleen een
  plaatje als zijn effen achtergrond de lucht is (tile 143, lichtblauw).
  De andere effen achtergrond, het donkergrijs binnen de bases en grotten
  (tile 195), zit ook in de rotsen en muren, dus daar zou het plaatje
  doorheen schijnen. Keen 2's regel (meest gebruikte tile) zou level 10
  een plaatje achter de muren van zijn basis geven en levels 8, 11, 13 en
  15 geen. **In v1.00: levels 1-8, 11, 13, 14 en 15**; niet 9, 10, 12 en
  16. Getest met een zelfgemaakt testplaatje (niet gecommit, weer
  verwijderd) in levels 1, 8, 10 en 15: zichtbaar achter de lucht van 1,
  8 en 15, niet in level 10 en niet in 4:3.
- **Eigen plaatjes (na C9, op verzoek van de gebruiker, 19-10-2026):**
  `tools/make_keen3_backgrounds.py` tekent er twaalf vanuit code, in grove
  pixels zoals het spel, één per level met lucht, elk passend bij het
  level: 1 zonsondergang met paarse pieken, 2 de stad bij avond met een
  grote maan, 3 twee manen boven bergen, 4 een heldere dag met wolken, de
  stad en de aarde aan de hemel, 5 gouden uur met bomen en torens, 6
  huisjes in de avond, 7 een rode dreigende lucht met een fort, 8 de
  zonsondergang boven groene heuvels (het testplaatje dat de gebruiker
  mooi vond), 11 een bos bij volle maan, 13 een roze dageraad met
  rotsen, 14 kastelen in de zonsondergang, 15 besneeuwde bergen. Samen
  ~110 KB (lossless WebP). Niets komt uit de spelbestanden. Opnieuw maken:
  `python3 tools/make_keen3_backgrounds.py`.
- **Een plaatje toevoegen:** `levelNN.png` (NN = levelnummer met twee
  cijfers) in `game_data/keen3/backgrounds/` om te proberen, of in
  `assets/backgrounds/keen3/` om mee te leveren (alleen eigen plaatjes).
  Elke maat werkt; het plaatje bedekt het beeld en schuift van links naar
  rechts mee, dus breed voor brede levels (zo'n 3840x1080 voor levels 4,
  5 en 14), 1920x1080 voor smalle (6, 11).
- **Builds:** `tools/build_macos.sh` en `tools/build_windows.sh` nemen
  `game_data/keen3` al mee (sinds C2), met een eventuele map
  `backgrounds`; plaatjes in `assets/backgrounds/keen3/` gaan vanzelf mee
  in de export. Niets nieuws nodig. **Niet gebouwd hier:** de Mac-build
  kan alleen op de Mac, en voor Windows ontbreken de export templates.
  De gebruiker moet de app op de Mac bouwen.
- **Real-ESRGAN:** overgeslagen, zoals bij Keen 2 (besluit van de
  gebruiker, 17-10-2026).
- **Gedeelde code:** niets veranderd (alleen een regel in
  `tests/run_tests.gd`). `git diff ade258d` op `src/keen2`,
  `tests/test_keen2_*.gd`, `tests/keen2_fixtures.gd`, `src/actors`,
  `src/map` en `src/game/level_view.gd` is leeg.
- **Tests:** nieuwe suite `test_keen3_extras` (de regel, alleen Keen 3's
  map, het eigen plaatje van de speler, het kaartbeeld en de figuren
  tussen de ticks, de echte levels). 63 suites, 729 tests (was 62 en
  722), alle slagen, gdlint schoon.
- **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen de C7-referentie (lege gebruikersmap): alles
  gelijk, ook `launcher.png`.
- **Bekeken in de app** (scratchpad `c9shots/`, xBRZ en vloeiend aan):
  levels 1, 8, 10, 15 en 16 (Mortimer, de machine), de kaart, het
  statusscherm, het einde, titel, menu en highscores, in breedbeeld en
  4:3; en level 1 met de standaardinstellingen en F2/F5/F6.

## Mijlpaal C8: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
Getallen uit Chocolate Keen (`(Choco)`), de plekken van titel en
highscores uit js-dos (C1). De regels staan in `docs/keen3/gameplay.md`
("Sounds (C8)", "Title, menus, saving and high scores (C8)");
afwijkingen in `docs/keen3/architecture.md`, "Deviations in C8".

- **Geluid op 145,65 Hz voor alle drie de delen** (besluit van de
  gebruiker, 17-10-2026): de gedeelde `SoundFile.STEPS_PER_SECOND` is nu
  1.193.182 / 8192 (`SOUND_TIMER_DIVISOR`), was 140. De enige bewuste
  wijziging aan Keen 1 en 2 in de C-reeks. Geen enkele Keen 1- of Keen
  2-test rekende op 140 Hz (de synth-test leest de snelheid uit
  `SoundFile`), dus er is geen test aangepast.
- **Alle geluiden van Keen 3** (`Keen3Sounds`, Choco): ANKH, MEEP, MORTIMER
  en FOOTSLAM speelden al sinds C3-C7; nieuw volgens het origineel: een
  pogo-stuit klinkt als KEENJUMPSND (niet KEENPOGOSND), van een rand
  lopen geeft PLUMMETSND, tegen een muur in de lucht KEENBLOKSND (elke 32
  klokticks), de moeder eerst TANKFIRE en dan de splash, de eindtekst eerst
  keensleft tot het eind en dan MORTIMER, en geen HISCORESND bij een naam.
  Keen 3's eigen speaker en de gedeelde speler gedragen zich als één
  speaker (prioriteiten). Keen 1 en 2 houden hun eigen keuzes; de
  verschillen staan voor C12 in `docs/keen3/choco-keen1-keen2.md`.
- **Titel en highscores** (`Keen3MenuScreen`, `Keen3Screens`): de titel
  op het eerste scherm van map 90 (`TITLE` op (32,1), `F1HELP` op
  (120,182)), de highscores op cellen 84-103 (`HIGHSCOR`, `NAME`, `SCORE`,
  naam vanaf x 80, score tot x 240, rood op grijs zoals het origineel,
  geen derde kolom); ze wisselen elke 16,5 s (Choco). Een toets opent het
  hoofdmenu.
- **Hoofdmenu** (gedeelde `MenuController`): New Game, Continue Game, Save
  Game (alleen op de kaart, niet tijdens een teleporter), Story (uit
  KEEN3.EXE), High Scores, Controls, Options, Quit to Title, Choose Game
  (terug naar het startscherm), Quit. Geen online, geen tweede speler,
  geen extra levels (C10). Escape opent het menu in een spel (tijdens
  Mortimer slaat Escape hem nog over).
- **GAME OVER, ook na het einde,** leidt naar de highscores; een score die
  erin komt vraagt eerst een naam. Highscores in
  `user://keen3/high_scores.json`.
- **Opslaan en laden** in `user://keen3/saves` (negen plekken, los van
  Keen 1 en 2; toetsen en beeld gedeeld): score, levens, ladingen, de
  gedane levels, Keens plek en het beeld op de kaart (zoals het origineel).
  Messie wordt niet bewaard: het origineel zet haar bij een geladen spel
  ook weer op haar begin.
- **Gedeelde code:** alleen `src/data/sound_file.gd` (de snelheid) en een
  commentaar in `src/sound/speaker_synth.gd`. `git diff 97b128f` op de
  Keen 1- en Keen 2-mappen is leeg.
- **Tests:** drie nieuwe suites: `test_keen3_sounds` (145,65 Hz,
  prioriteiten, de nieuwe geluiden van Keen), `test_keen3_menus` (titel en
  tabel, eigen bestanden, opslaan en laden in een testmap, het menu) en
  `test_keen3_menus_data` (echte bestanden: 45 geluiden, map 90, de
  bitmaps, het verhaal). 62 suites, 722 tests (was 59 en 698), alle
  slagen, gdlint schoon.
- **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen de C7-referentie: alles gelijk, ook
  `launcher.png`.
- **Bekeken in de app** (scratchpad `c8shots/`): titel, menu, verhaal,
  highscores (4:3 en breedbeeld), de titel en highscores die wisselen, een
  nieuw spel, opslaan en laden (zelfde plek en beeld), het einde tot GAME
  OVER en de naam voor de highscores, het menu tijdens het einde, Choose
  Game naar het startscherm.
- **Niet gedaan:** de Windows-build (geen export templates in deze
  omgeving) en de Mac-build (alleen op de Mac). Niet nagebouwd, zoals bij
  Keen 1 en 2: de id-pagina en de bestelpagina met de Foob in de
  titelreeks, F1-hulp, "About ID", "Ordering Info", "Previews!".
- **Open punten:** alle geluiden met het oor naast het origineel (ook de
  145,65 Hz); 100 punten in een nieuwe tabel (schatting zoals Keen 1 en
  2); in het origineel vraagt het GAME OVER-venster zelf de naam en gaat
  "Quit to Title" ook via GAME OVER en de highscores (wij doen het zoals
  Keen 2).

## Mijlpaal C7: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
Getallen uit Chocolate Keen (`(Choco)`), de armen en benen nagekeken in
js-dos. De regels staan in `docs/keen3/gameplay.md` ("Mortimer", "The
Mangling Machine", "The border flash", "The ending"); afwijkingen in
`docs/keen3/architecture.md`, "Deviations in C7".

- **Mortimer** (`Keen3Mortimer`, `Keen3TypedBoxes`): elke keer dat level 16
  begint staat het level met zijn sprites stil, speelt MORTIMER tot het
  eind, en worden zijn negen vensters uit KEEN3.EXE getypt (6 retraces per
  letter), met de maten, plekken en pauzes van Choco; één venster
  tegelijk. Escape, Spatie of een knop slaat de rest over (Escape verlaat
  het spel dan niet).
- **De Mangling Machine** (`Keen3Machine`, `Keen3MachineArm`,
  `Keen3MachineLeg`, `Keen3MachineSweep`, `Keen3Spark`, `Keen3Heart`):
  zes vonken (+1000 en de randflits per vonk), het hart (146/147), twee
  armen (omlaag elke 6,2 ticks, omhoog elke 16,5, keren bij 471 en bij het
  einde van de schacht), twee benen (stap elke 14,4 ticks, FOOTSLAM op de
  vloer, 82 ticks wachten). Bij de zesde vonk stoppen de armen en veegt
  een sweep de kolommen 5-7 en 17-19 schoon (ook tile 611 die het hart
  afschermt). Het hart: +1000, randflits, benen stoppen, alle sprites
  behalve Keen weg, sweep over het lichaam, 181 ticks later is het level
  klaar en volgt het einde. Alle tiles via `LevelSession.set_tile`, dus
  xBRZ en HD volgen (gezien met xBRZ). Geen trillend scherm (Choco).
- **De randflits** (besluit van de gebruiker): een dun kader (2
  spelpixels) knippert geel en cyaan (EGA 14 en 3, elke 26 ticks, 124
  ticks lang, zoals het origineel) rond het beeld: in de zwarte balken
  naast het 4:3-beeld, of op de rand van het beeld zelf als er geen ruimte
  is (breedbeeld).
- **Het einde** (`Keen3Ending`, `Keen3EndingScreen`): map 81 met een
  Vorticon en Keen, infaden, de vier pagina's getypt (120 retraces na
  elke), vijf cameraflitsen (tile wisselt, het beeld licht 2 retraces op,
  CLICKSND, wachttijden 20/10/5/10/15), 120, uitfaden; FINALE.CK3 infaden,
  400 retraces, het venster eroverheen getypt, een toets; de eindtekst
  (scrollen met omhoog/omlaag) met MORTIMER; dan GAME OVER en het
  startscherm (highscores in C8). In breedbeeld zwarte balken naast map
  81, nooit de rand. `-- --game=3 --ending` start het einde direct.
- **Gedeelde code:** niets veranderd (ook `GameLaunch` niet: `--game=3
  --ending` werkte al; `--ending` zonder `--game=3` blijft Keen 1).
- **Tests:** vier nieuwe suites: `test_keen3_machine` (zelfgemaakt level
  16, `tests/keen3_machine_fixtures.gd`), `test_keen3_scenes` (Mortimer,
  typen, vensterplek, randflits, `--ending`), `test_keen3_ending` (alle
  stappen van het einde) en `test_keen3_machine_data` (echte bestanden:
  de machine van level 16, een echt schot op het hart wint het spel, de
  teksten passen in hun vensters, map 81). Aangepast:
  `test_keen3_level` ("machine-infowaarden maken nog niets" werd "maken
  de machine"). Alle 58 suites slagen, geen `SCRIPT ERROR`, gdlint schoon.
- **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen `a9d04cc` in een venster (fullscreen even
  uit, daarna byte voor byte teruggezet): alles gelijk behalve
  `launcher.png`. `git diff a9d04cc` op de gedeelde mappen toont alleen de
  C2-wijzigingen.
- **js-dos:** level 16 is niet te bereiken met een script; in een kopie
  van de bestanden in de scratchpad is LEVEL16.CK3 over LEVEL01.CK3 gezet.
  Daar draait de machine (zonder Mortimer, die hoort bij levelnummer 16):
  de armen (stap omlaag ~108 ms, omhoog ~271 ms, ~371 ms stil aan elk
  eind) en de voeten (~245 ms per stap, ~1,9 s op de vloer) kloppen met
  onze getallen; daarop is het wachten na FOOTSLAM met één stap verlengd.
  Niet gezien: Mortimer, een vonk of het hart raken, de sweeps, de
  randflits, het einde.
- **Bekeken in de app** (scratchpad `c7shots/`): Mortimers vensters (4:3
  en breedbeeld), de machine in beweging, de randflits na een vonk, na de
  zesde vonk, de sweep van het hart (ook met xBRZ), en elk deel van het
  einde (infaden, pagina's, een cameraflits, het plaatje met venster, de
  eindtekst, GAME OVER) in 4:3 en breedbeeld.
- **Open punten:** het eerste beeld van level 16 staat in het origineel
  lager (gezicht bovenaan, voeten onderaan) dan bij ons (C11, zoals level
  1); of het origineel oude Mortimer-vensters laat staan; de y-plek van de
  vensters in het einde; de fade-snelheid; de randflits zelf nog niet in
  het origineel gezien.
- **Gemaskeerde tiles (fix na C7, goedgekeurd voor Keen 2 en 3):** tiles
  met gedrag -2 (hekken, raamkozijnen, tafels, bomen, wolken) worden nu
  heel achter Keen getekend en ervoor alleen waar hun masker (de volgende
  tile, zwart-wit) zwart is; Keen is door de open delen te zien, ook met
  xBRZ en op de kaart van Keen 2. Keen 2's 371-373 hebben geen masker en
  blijven gewone voorgrond-tiles. Keen 1 heeft ze niet en blijft byte voor
  byte gelijk (regressie tegen `a9d04cc`). Zie `docs/keen3/architecture.md`,
  "Masked tiles (fix after C7)".

## Mijlpaal C6: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
De getallen komen uit Chocolate Keen (`(Choco)`) en zijn in js-dos
nagekeken waar dat lukte. De regels staan in `docs/keen3/gameplay.md`
("The course of the game", "The world map", "The status screen");
afwijkingen van de architectuur in `docs/keen3/architecture.md`,
"Deviations in C6".

- **Het verloop** (`Keen3LevelPlay`, zoals Keen 2 na B6): het startscherm
  (en `--game=3`, ook met `--level=80`) begint een nieuw spel op de
  wereldkaart met "Keens Left"; `--level=N` (1-16) start dat level en
  daarna de kaart. Uitgang: level klaar (bordje op de kaart), sleutelkaarten
  weg, terug op de kaart waar Keen het level in ging, met hetzelfde beeld.
  Dood: een leven minder, terug op de kaart met "Keens Left" (hoogstens 6
  Keens, Choco). Geen levens meer: GAME OVER, dan het startscherm.
  **Level 16 klaar = gewonnen**: voorlopig het briefje "You won - the
  ending comes later" (5 s of een toets) en dan het startscherm; het einde
  komt in C7. `Keen3Progress extends GameProgress` bewaart ook Messie en
  het beeld van de kaart. Cheats Shift+N/P/I/G werken (van de kaart: level
  1 / level 16).
- **De kaart** (`Keen3MapSession extends MapSession`, Keen 1's klassen
  ongewijzigd): ingangen 1-16 met springen of pogo (opnieuw indrukken),
  ook via een 0x8000-cel; de cellen onder Keens vak tellen, de laatste
  wint. Muren (0x8000 + n) tot het level klaar is. Bordjes 56 (1x1) en
  52-55 (2x2; ook level 15 met drie 0x800F-cellen), de info-cellen worden
  gewist.
- **Kaart-Keen** (`Keen3MapKeen`): sprites 31-46, 4 px per frame (97 px/s;
  Keen 1's 127,5 px/s is te snel, dus eigen snelheid), stapgeluid elk
  tweede frame.
- **Het beeld** (`Keen3MapScroll`): zoals het origineel, Keen vrij tussen 9
  en 11 cellen van links en 3 en 7 van boven; een nieuw spel toont (35,44)
  linksboven; de camera staat er precies op.
- **Teleporters** (`Keen3MapTeleport`): tiles 130-133 twee keer met
  TELEPORTSND, 134; het beeld springt (bestemming 10 cellen rechts, 6
  omlaag); dezelfde animatie daar; Keen onzichtbaar tot hij aankomt;
  Messie wacht. Alle 16 routes kloppen met research §8.
- **Het schip**: een van de vier berichten (willekeurig) in een venster van
  32x6, met de regel eronder uit KEEN3.EXE; een toets sluit het.
- **Messie** (`Keen3Messie`): start op (35,8) naar links, 2 px per frame,
  de eerste buur kolom voor kolom die pad of wier is en niet haar cel of de
  vorige; 122 frames wachten voor wier; plaatjes per richting (met Keen 8
  verder). Opstappen door tegen haar aan te lopen (CRYSTALSND, Keen
  verborgen, kan niets gebruiken, het beeld volgt haar), afstappen met een
  richting naar een aanlegplek (0x2200); daarna 30 frames niet opnieuw.
  Ze brengt Keen naar het eiland van level 16 en naar de Hidden City
  (level 13) (getest met de echte kaart).
- **Statusscherm** (`Keen3StatusScreen` in `Keen3Window`): de statustoets
  (Enter; in het origineel Spatie, maar dat is hier vuren) op de kaart en
  in een level, het spel staat stil, elke toets sluit. Vak 28x11 op x
  40-279, y 48-151; rode labels op grijze balken (de tweede helft van het
  lettertype, zoals het origineel); score, volgende extra Keen, Keentjes
  (max 9), pistool met ladingen, ankh met tijd, sleutelkaarten. Alle
  plaatjes staan pixel voor pixel waar het origineel ze heeft.
- **HUD op de kaart** (breedbeeld): levens, score, straalgeweer,
  sleutelkaarten (geen ankh-paneel).
- **Gedeelde code:** niets veranderd.
- **Tests:** vier nieuwe suites: `test_keen3_map` en `test_keen3_messie`
  (zelfgemaakte kaarten, `tests/keen3_map_fixtures.gd`), `test_keen3_status`
  en `test_keen3_map_data` (echte bestanden: alle ingangen en bordjes, de 16
  teleporters, Messie's lus van 256 cellen, beide aanlegplekken, haar
  timing tegen js-dos, met Messie naar level 16 en 13, van de kaart naar
  level 1 en terug). Aangepast omdat C6 het verloop verandert:
  `test_keen3_play` (uitgang en dood naar de kaart, level 16 wint) en
  `test_keen3_level` (level 16 klaar = gewonnen). Alle 54 suites slagen,
  geen `SCRIPT ERROR`, gdlint schoon.
- **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen `a9d04cc` in een venster (fullscreen even
  uit, daarna exact teruggezet): alles gelijk behalve `launcher.png`.
  `git diff a9d04cc` op de gedeelde mappen toont alleen de C2-wijzigingen.
- **js-dos:** kaart-Keen 4 px per frame en het beeld dat meeschuift op x
  176; teleporter 1 → 3 en terug (71 ms per tile, 1,14 s, Keen onzichtbaar,
  beeld op (45,35)); Messie 70 s gevolgd: ze komt op dezelfde momenten in
  beeld als bij ons (op ~0,1 s), dus start, snelheid, route en het wachten
  bij het wier kloppen; het schip (venster op x 24-295, y 64-127,
  willekeurig bericht); het statusscherm met alle sleutelkaarten (pistool
  en sleutelkaarten 4 px lager dan C1 noteerde: Choco klopt); na een dood
  in level 1 hetzelfde beeld en dezelfde plek. Niet gezien: een
  "done"-bordje (geen level uitgespeeld), op- en afstappen bij Messie,
  geluiden.
- **Bekeken in de app** (schermafdrukken in de scratchpad, `c6shots/`):
  de kaart bij de start (4:3 en breedbeeld), lopen, "Keens Left", de
  teleporter halverwege en erna, het schip, Messie zwemmend, Keen op
  Messie, een 2x2-bordje, het statusscherm op de kaart en in level 1, de
  kaart na een dood.
- **Open punten:** de kaart (met Messie) wordt nog niet opgeslagen (C8);
  het "done"-bordje en op/afstappen bij Messie nog in js-dos bekijken
  (C11).

## Mijlpaal C5: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
De getallen komen uit Chocolate Keen (`(Choco)`), omgerekend naar onze
eenheden; het verticale platform is ook in js-dos nagekeken. De regels
staan in `docs/keen3/gameplay.md` ("Ball, jack, platforms and wall guns
(C5)", "Riding"); afwijkingen van de architectuur in
`docs/keen3/architecture.md`, "Deviations in C5".

- **Bal** (info 7, `Keen3Ball`): vertrekt schuin naar Keens start, 121/32
  per as, zonder zwaartekracht, kaatst tegen muren, vloeren en plafonds.
  Keen kan erop staan en meerijden; de bal duwt hem opzij. Schoten spatten
  erop, hij gaat nooit kapot.
- **Jack** (info 8, `Keen3Jack`): vliegt hetzelfde, vier plaatjes; aanraken
  is dodelijk (niet met de ankh); schoten spatten erop.
- **Platforms** (info 9 zijwaarts, 10 op en neer, `Keen3Platform`):
  22,8/32; het zijwaartse wacht 31 ticks bij een muur, het verticale keert
  bij een vloer meteen en wacht 31 ticks bij een plafond. Ze bewegen altijd,
  ook ver buiten beeld. Meerijden met Keen 2's `Keen2RidingCollision` en
  `Keen2Carrier` (ongewijzigd, met `Keen3Carrier` als Keen 3-laag erop);
  niet naar buiten lopen terwijl je meerijdt. Op het 32x8-platform staat
  Keen goed (schermafdruk level 2).
- **Hard van alle kanten** (`Keen3Carrier`): van boven komt Keen erop, van
  onder stoot hij zijn hoofd, van opzij wordt hij weggeduwd; altijd door de
  tiles heen, dus nooit in een muur. Houden de tiles hem vast, dan gaat het
  ding langs hem heen (zo deed het origineel in level 2). Draagt een
  platform of bal Keen tegen een plafond, dan stopt het onder zijn voeten
  alsof het zelf het plafond raakte (*schatting*; nooit vastgeklemd of
  dood).
- **Wapens in de muur** (info 14 naar rechts, 15 omlaag, `Keen3WallGun`):
  onzichtbaar; één klok voor alle wapens vanaf de start van het level, elke
  165 ticks (2,75 s) vuren ze tegelijk met één TANKFIRE, ook buiten beeld
  (hoorbaar); een schot dat ver buiten beeld zou beginnen wordt niet
  gemaakt. Het schot (`Keen3GunShot`, 103/104) vliegt door alle sprites en
  doodt onderweg Keen (ook verdoofd, niet met de ankh), grunts en Foobs;
  bij een muur SHOTHIT en een spat.
- **Raakregels** verhuisd naar `Keen3Hits` (de sessie werd te lang), met de
  algemene tak voor vijandelijke schoten. Keens schot spat nu ook op bal,
  jack, platforms en het schot van een wapen.
- **Gedeelde code:** niets veranderd.
- **Tests:** `test_keen3_objects` (bal, jack, wapens) en `test_keen3_riding`
  (platforms, meerijden) met zelfgemaakte levels; `test_keen3_enemy_census`
  telt nu ook de objecten van elk level 1-16 (echte bestanden). Twee
  Keen 3-tests aangepast: `test_keen3_level` (alleen 12, 13, 16-18 maken
  nog niets) en de census (objecten tussen de vijanden toegestaan). Alle 50
  suites slagen, geen `SCRIPT ERROR`, gdlint schoon.
- **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen `a9d04cc` in een venster (fullscreen even
  uit, daarna exact teruggezet): alles gelijk behalve `launcher.png`.
  `git diff a9d04cc` op de gedeelde mappen toont alleen de C2-wijzigingen.
- **js-dos:** level 2 bereikt (kaart: één omhoog, vier naar rechts), het
  verticale platform gemeten: 0,71 px per tick (Choco 22,8/32), keert bij de
  vloer meteen, wacht ~0,55 s bij het plafond (Choco 31 ticks + 1): de
  getallen kloppen. Het platform ging langs een Keen die onderin de schacht
  stond (daarom de regel hierboven). Niet bereikt: bal, jack, wapens
  (levels 3 en 4 liggen achter de blokkade die pas na level 2 opengaat).
- **Bekeken in de app** (schermafdrukken in de scratchpad, `c5shots/`):
  level 2 (meerijden op het verticale platform, tot onder het plafond),
  level 8 (zijwaarts platform), level 9 (schoten naar rechts uit de rode
  kanonnen), level 12 (schoten omlaag uit de lampen, spatten op de vloer),
  level 15 (bal en jack), level 6 (bal). Levels 1-15 draaien headless 2000
  ticks zonder fouten; Keen, op elk echt platform gezet, komt nooit in een
  tile (op een paar in levels 9, 10 en 14 schraapt een muur op hoofdhoogte
  hem eraf).
- **Open punten:** in level 14 schraapt een paal (kolom 110) Keen van het
  zijwaartse platform boven de spijkers; zo zitten de tiles, maar of het
  origineel hem ook laat vallen is niet gezien. Nog te zien in js-dos (C11):
  bal, jack, wapens, het zijwaartse platform, meerijden tegen een plafond.

## Mijlpaal C4: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
Alle getallen komen uit Chocolate Keen (in de code `(Choco)`), omgerekend
naar onze eenheden. De regels staan in `docs/keen3/gameplay.md` ("Enemies",
"Waking and sleeping", "The stun"); afwijkingen van de architectuur in
`docs/keen3/architecture.md`, "Deviations in C4".

- **Zes vijanden** (`src/keen3/actors/`, op de nieuwe basis `Keen3Enemy`):
  grunt (info 1 en 11; loopt, springt, wisselt van snelheid, kijkt rond na
  elke landing en gaat dan op Keen af; aanraken is dodelijk), youth (2;
  rent en huppelt, verdooft Keen), moeder (3; loopt niet van een richel,
  draait zich om en spuwt een vuurbal; duwt Keen opzij; 5 schoten), Meep
  (4; zingt een geluidsgolf die door muren gaat; zingt ook in de lucht aan
  een richel, de bug van het origineel; duwt), ninja (5; springt op Keen af
  als hij binnen 5 tiles hoogte is; 4 schoten) en Foob (6; schrikt, vlucht
  naar een muur; gaat zelf dood als Keen hem raakt). Info 7-18 maken nog
  niets (C5, C7). Vijanden geven geen punten.
- **Schoten:** Keens schot (121/32) spat op elke sprite behalve Keen en
  lijken, ook op een vuurbal (allebei weg) en een golf (die vliegt door).
  De vuurbal doodt Keen (ook verdoofd), grunts en Foobs en vliegt door
  moeders heen. De golf doodt Keen.
- **Wakker en slapen** zoals het origineel (`Keen3ActiveArea`): een vijand
  wordt wakker vlak bij het beeld en slaapt weer ver ervandaan; schoten,
  golven en lijken verdwijnen daar. In widescreen groeit het gebied mee met
  het beeld (besluit van C4). Een golf verdwijnt ook zodra hij het
  speelbare deel verlaat (anders vloog hij in level 16 over de zwarte
  balken).
- **Keen 3's eigen verdoving** (`Keen3Body`): Keen krijgt de snelheid van
  de youth, ligt 165 ticks (28/29), glijdt uit, staat 16,5 ticks op (30).
  Een schot doodt een verdoofde Keen; de ankh voorkomt verdoving en dood.
- **HUD:** de plaatjes van straalgeweer, sleutelkaarten en ankh laten de
  achtergrondkleur van hun tile-rij weg (geen cyaan vlak meer).
- **Gedeelde code:** niets veranderd.
- **Tests:** `test_keen3_enemies`, `test_keen3_enemy_rules` (zelfgemaakte
  levels) en `test_keen3_enemy_census` (echte bestanden: elk level 1-16
  heeft de vijanden uit research.md §5). Twee C3-asserties ("nog geen
  vijanden") zijn aangepast. Alle 48 suites slagen, geen `SCRIPT ERROR`,
  gdlint schoon.
- **Keen 1- en Keen 2-controle:** `keen1_regression.sh` en
  `keen2_regression.sh` tegen `a9d04cc` in een venster: alles gelijk
  behalve `launcher.png`. `git diff a9d04cc` op de gedeelde mappen toont
  alleen de C2-wijzigingen.
- **js-dos:** level 1 bereikt met G+O+D. Gezien: de Foob gaat dood als
  Keen hem raakt (Keen niet), de gevluchte Foob staat tegen de rotsen te
  "dribbelen" (bij ons ook), god mode toont de halo achter de
  voorgrond-tiles. Niet gelukt: de grunt, youth en moeder bereiken (Keen
  viel twee keer in de put na de waterval); de Choco-getallen blijven.
- **Bekeken in de app** (schermafdrukken in de scratchpad): level 1 (Foob
  tegen de rotsen, HUD zonder cyaan), level 4 en 6 (grunts, youths, Foobs),
  14 (ninja springt), 16 (Meeps zingen golven), een verdoofde Keen
  (level 6) en een vuurbal (level 1).
- **Open punten:** de youth gebruikt één botsingsbox voor beide
  richtingen (*estimate*); welke spat-sprite (origineel: willekeurig); het
  widescreen-gebied; de vijanden zakken bij de start op de vloer zoals in
  Keen 1 en 2. Nog te meten in js-dos (C11): snelheden en tijden van
  grunt, youth, moeder, Meep en ninja.

## Mijlpaal C3: wat er nu is

Gebouwd en getest met de echte Keen 3-bestanden van de gebruiker (1.00).
De regels staan in `docs/keen3/gameplay.md`; afwijkingen van de
architectuur in `docs/keen3/architecture.md`, "Deviations in C3".

- **Het spelscherm:** `Keen3View` (`src/keen3/keen3_view.gd/.tscn`, een kopie
  van de opbouw van `keen2_view.tscn`) op `Keen3SceneScreen` op
  `GameScreen`: widescreen met HUD, F1-F6 (ook xBRZ), de camera, berichten.
  De keten is zo opgezet dat C6-C8 er de kaart, de menu's en het einde
  tussen kunnen zetten (zoals bij Keen 2).
- **Voorlopig verloop** (`Keen3LevelPlay`, zoals B3): vanaf het startscherm
  level 1, met `-- --game=3 --level=N` level N (1-16). Uitgang: volgend
  level (sleutelkaarten weg), na 16 terug naar het startscherm. Dood: een
  leven minder, hetzelfde level opnieuw met het venster "Keens Left" (0,87 s,
  zoals in js-dos). Geen levens: GAME OVER (het plaatje, 5,27 s) en terug.
  Escape gaat terug. Cheats: Shift+N/P, Shift+I, Shift+G.
- **Een level** (`Keen3LevelSession extends Keen2LevelSession`): punten uit
  de tabel (snoepreep 500, hamburger 100, cola 200, taart 1000, ninja-knuffel
  5000), straalgeweer +5, losse lading +1, sleutelkaarten en deuren (de deur
  krijgt de tile links van zijn bovenste cel en zakt weg zoals bij Keen 1),
  uitgang (elke uitgang telt, dus de twee uitgangen van 12, 13 en 15
  werken), dodelijke tiles, extra leven per 20.000. Een opgepakt item laat
  de eerste tile van zijn rij achter, `(tile / 13) * 13`. Gedrag 22 wordt
  tile 143. Nog geen vijanden (C4/C5). Level 9 start bij de laatste van
  zijn twee starts, (63,17).
- **Keen** (`Keen3Body extends Keen2Body`): de gedeelde natuurkunde,
  ongewijzigd (sprongen blijven voorlopig iets te hoog, besluit van de
  gebruiker). Startwaarden: 4 levens, 5 ladingen, pogo vanaf het begin.
  Doodgaan met sprites 22/23 (nagekeken).
- **De ankh:** geluid ANKH (`Keen3Sounds`), 577 ticks per ankh (Chocolate
  Keen: 1400 klokticks, 9,6 s), telt op, bij elk level op 0, telt alleen af
  tijdens het spelen. Keen kan dan niet dood (behalve door uit het level te
  vallen) en niet verdoofd worden (`is_protected()`, klaar voor C4). Het
  schild: sprites 61/62 om de 6,6 ticks, 8 px links-boven Keen, knippert in
  de laatste 103 ticks (`Keen3AnkhShield`).
- **HUD:** `Keen3Hud extends Hud`: levens (met Keen 3's eigen kaart-Keen),
  score, ladingen, sleutelkaarten en, zolang de ankh werkt, de ankh met zijn
  tijd in hele "seconden" zoals het statusscherm (een nieuwe ankh: 9).
- **De rand (tile 245, "OH no!"):** nooit te zien. De gedeelde `LevelMap`
  tekent alleen het speelbare deel en de camera blijft erbinnen; smalle
  levels (16 in widescreen) krijgen zwarte balken. Getest voor alle levels
  en drie beeldbreedtes; bekeken in 4:3, widescreen en xBRZ.
- **Gedeelde code:** niets veranderd.
- **Tests:** `test_keen3_level` en `test_keen3_keen` (zelfgemaakte levels met
  een rand van 245) en `test_keen3_play` (echte bestanden). De C2-test van
  het voorlopige scherm is weg (dat scherm bestaat niet meer).
- **Keen 1- en Keen 2-controle:** alle 45 suites slagen, gdlint schoon.
  `keen1_regression.sh` en `keen2_regression.sh` tegen `a9d04cc`: alles
  gelijk behalve `launcher.png`, als het venster niet schermvullend is.
  Schermvullend gaf `level1_walk.png` van Keen 1 een ouder beeld bij de
  referentie (de spellogica was gelijk; het schermvullend-maken van macOS
  verschuift de schermafdruk). Zie architecture.md.
- **Niet gedaan:** de vergelijking met het origineel in js-dos (optioneel).
  Wel opgevallen: ons eerste beeld van level 1 begint bij cel (2; 11,5), het
  origineel bij (2,12) (zie gameplay.md).
- **Open punten:** de plaatjes van het straalgeweer, de kaarten en de ankh in
  de HUD houden de cyaan achtergrond van hun rij; in `test_keen3_data.gd`
  (C2) breekt `test_sprite_names_fit_the_enemies` af met een scriptfout bij
  de boxen (de suite meldt toch PASS), niet aangepast.

## Mijlpaal C2: wat er nu is

Gebouwd met de echte Keen 3-bestanden van de gebruiker (versie 1.00).
Details in `docs/keen3/file-formats.md`; afwijkingen van de architectuur
staan in `docs/keen3/architecture.md`, "Deviations in C2".

- **Bestanden vinden:** `Keen3Files` (`src/keen3/data/`) zoekt
  `game_data/keen3` op dezelfde plekken als Keen 1 en 2
  (`--data-dir-keen3=PATH`, de projectmap, naast het programma, naast de
  macOS-app) en geeft een gewone `GameFiles` met extensie `CK3`. Vereist:
  `KEEN3.EXE`, `EGAHEAD.CK3`, `EGALATCH.CK3`, `EGASPRIT.CK3`. Levels 1-16,
  80, 81 en 90.
- **De tile-tabel:** `TileProperties.find_in_image` en `from_table` kregen
  een optionele `stride` (standaard de tile-telling, dus Keen 1 en 2 lezen
  precies hetzelfde; een test bewijst dat ook met hun echte tabellen). Keen 3
  leest 624 tiles met rijen van 715 (0x199F8 in 1.00, 0x198C8 in 1.31, anders
  zoeken); met 624/624 vindt hij aantoonbaar een verkeerde tabel. Gedrag 27
  (ankh) en 28 (losse lading) staan in `Keen3Behavior`, niet in de gedeelde
  enum.
- **KEEN3.EXE:** `Keen3Executable` pakt de EXE uit, herkent de versie (1.00,
  1.31 of "unknown") en vindt op inhoud: het geluidsblok (45 namen, met
  ANKH, MEEP, MORTIMER en FOOTSLAM), de tile-tabel, de vier teksten in de
  volgorde help, eind, previews, verhaal (de eerste niet meer twee bytes te
  vroeg), het statusvak (11 regels), Mortimers negen vakjes (na de
  puntentabel), de vier pagina's van het einde, het vakje boven het
  slotplaatje, de vier scheepsberichten en de highscore-teksten. Het gebruikt
  de openbare hulpfuncties van `Keen2Executable`; die is niet veranderd.
  Niets crasht als een stuk ontbreekt.
- **`Keen3GameData`** leest graphics, tile-eigenschappen, geluiden, teksten
  en `FINALE.CK3` in één keer (klaar voor C3).
- **Startscherm:** een derde icoon "Keen 3" rechts van Keen 2, met Keen uit
  de eigen Keen 3-graphics; zonder bestanden grijs met de uitleg dat ze in
  `game_data/keen3` horen (de teksten van Keen 1 en 2 zijn gelijk gebleven).
  Met bestanden opent het voorlopig `src/keen3/keen3_view.tscn` ("Keen 3 -
  coming soon"; Enter of Escape terug, via `call_deferred`).
- **Opdrachtregel:** `-- --game=3` (met of zonder `--level=N`) opent Keen 3;
  `GameLaunch.game_number` kiest uit drie spellen. Elke oude
  argumentenlijst geeft hetzelfde antwoord (getest, ook `--game=2 --game=3`
  blijft Keen 2). Data viewer en `tools/export_graphics.gd` kiezen ook uit
  drie (Keen 3 naar `exported/keen3/`); de statusregel van de viewer noemt
  de versie van `KEEN3.EXE` en wat erin gevonden is.
- **Online:** alleen de constante `OnlineProtocol.GAME_ID_KEEN_3`, nog niet in
  `GAME_IDS` (dat is C10).
- **Tools:** nieuw `tools/keen2_regression.sh` (titel, level 1, lopen in
  level 1, kaart 80, met `--game=2`); de bouwscripts nemen `game_data/keen3`
  mee; `game_data/README.md` heeft een stukje over Keen 3.
- **Tests:** `test_keen3_files` (zonder data: map zoeken, stride, Keen 1/2
  lezen hetzelfde, een zelfgemaakt EXE-beeld uit `tests/keen3_fixtures.gd`
  met alle stukken, kapotte stukken, versies, de catalogus met drie
  spellen, `--game=3`, oude argumenten, het voorlopige scherm) en
  `test_keen3_data` (echte data: 624 tiles, 148 sprites, 14 bitmaps,
  spritenamen en -boxen, versie 1.00, de geluiden, de vier teksten op hun
  plek, de berichten op hun plek en ook gevonden als alles verschoven is,
  kaart 80: ingangen, 16 teleporters, Messie's cellen, het schip). Alleen
  de "twee spellen"-regels in `test_launcher.gd` en `test_keen2_files.gd`
  zijn nu drie.
- **Keen 1- en Keen 2-controle:** alle 42 suites slagen, gdlint schoon.
  `keen1_regression.sh` tegen `a9d04cc` (worktree): alleen `launcher.png`
  verschilt (het derde icoon). `keen2_regression.sh` tegen `a9d04cc`: alle
  vier plaatjes gelijk. `git diff a9d04cc` op de Keen 1/2-bestanden toont
  alleen de toegestane regel in `tests/test_keen2_files.gd`.
- **Nog niet getest:** versie 1.31 (Steam/GOG); de bekende adressen van 1.31
  komen van Chocolate Keen, de rest wordt gezocht.

## Mijlpaal C1: wat er nu is

- **Branch:** `milestone-c1-onderzoek`, gemaakt vanaf
  `milestone-b10-origineel` (die bevat alles van Keen 1 en 2; de B-branches
  staan nog niet op `main`). Tot die op `main` staan, is commit `a9d04cc` de
  referentie voor "Keen 1 en 2 niet veranderd".
- **De Keen 3-bestanden van de gebruiker** (`game_data/keen3`) zijn
  **versie 1.00**, niet 1.31 (Steam/GOG). Commander Genius en Chocolate Keen
  kennen alleen de adressen van 1.31, en die schuiven niet overal evenveel
  op: alles wordt op inhoud gezocht. Een nieuwere versie is niet nodig; 1.31
  hoort ook te werken (nog niet te testen).
- **Wat de bestanden zeggen:** 624 tiles maar een tile-tabel van 715 breed
  (de gedeelde `TileProperties` leest met 624 stil een verkeerde tabel; C2
  krijgt een optionele `stride`), 148 sprites (vanaf 31 één lager dan Keen
  2), 14 bitmaps, 45 geluiden (nieuw: ANKH, MEEP, MORTIMER, FOOTSLAM), de
  teksten in een andere volgorde dan Keen 2, de randtile 245 is een "OH
  no!"-plaatje dat nooit te zien mag zijn, teleporters in de info-laag
  (0x0Fsd), Messie's pad (0x2000-0x2200), de machine in level 16 van tiles.
- **Chocolate Keen:** op verzoek van de gebruiker mogen nu ook de getallen
  uit de gedragscode gebruikt worden (`CLAUDE.md` aangepast). Daarmee zijn
  bijna alle vijanden, de ankh (9,6 s, telt op, per level op 0), Messie, de
  teleporters, de machine, Mortimers berichten, het einde en het
  statusscherm bekend. Het origineel rekent met 145,65 Hz en ~24 beelden per
  seconde; `research.md` legt uit hoe we omrekenen naar onze 60 Hz.
- **Bijvangst voor Keen 1 en 2** (alleen informatie, niets aangepast):
  [docs/keen3/choco-keen1-keen2.md](docs/keen3/choco-keen1-keen2.md). Zo
  telt in Keen 2 een stad als gered zodra iets de vonk raakt, duurt de
  verdoving langer, en zijn de geluiden 145,65 Hz.
- **Architectuur:** Keen 3 in `src/keen3/` met klassen `Keen3...`;
  `Keen3LevelSession extends Keen2LevelSession` (meerijden, verdoving),
  grunt en youth als subklassen van Keen 2's, `Keen3MapSession extends
  MapSession`; een eigen schermketen. Een nieuwe controle
  `tools/keen2_regression.sh` (C2) bewijst dat Keen 2 niet verandert.
- **Handleiding** voor volgende delen bijgewerkt (lessen van C1).
- Er is nog geen code geschreven.

## Mijlpaal B1: wat er nu is

- De code is in kaart gebracht: decoders, graphics, schaling,
  geluidssynthese, levels tekenen en botsen, menu's en het netwerk werken
  voor beide delen. Keen 1 zit vast in `GameFiles` (map, `.CK1`,
  levelnummers), `EgaGraphics` (bestandsnamen), de spritenummers van de
  vijanden, de vijandenfabriek in `LevelSession` en `level_view.gd`.
  Opslaan, highscores en de plaatjes achter levels zouden tussen de delen
  botsen; daarvoor krijgt Keen 2 eigen mappen.
- Keen 2 uitgezocht met Commander Genius (en de datatabellen van Chocolate
  Keen) als documentatie: alles in `docs/keen2/research.md`, met per feit de
  bron en of het zeker is. Belangrijkste verschillen: geen `SOUNDS`- en
  tekstbestanden (alles zit in `KEEN2.EXE`), 689 tiles, andere vijanden
  (grunt, youth, Elite, Scrub, Guard robot, platform, vonk), schakelaars met
  de pogo-knop (bruggen, licht, Tantalus-straal), de aarde die ontploft,
  acht steden in plaats van scheepsonderdelen, de pogo vanaf het begin.
- Architectuur: Keen 1-code wordt niet aangeraakt; gedeelde code krijgt
  alleen toevoegingen met Keen 1 als standaard; Keen 2 komt in
  `src/keen2/` met klassen `Keen2...`. Elke mijlpaal eindigt met een
  controle dat Keen 1 niet veranderd is.
- Er is nog geen code geschreven.

## Mijlpaal B2: wat er nu is

Gebouwd zonder echte Keen 2-bestanden (Keen 2 is geen shareware). Alles is
getest met zelfgemaakte testdata en met de Keen 1-bestanden onder Keen
2-namen. Details in `docs/keen2/file-formats.md`.

- **Bestanden vinden:** `Keen2Files` (`src/keen2/data/`) zoekt
  `game_data/keen2` op dezelfde plekken als Keen 1 (`--data-dir-keen2=PATH`,
  de projectmap, naast het programma, naast de macOS-app) en geeft een gewone
  `GameFiles` met extensie `CK2` terug. Vereist: `KEEN2.EXE`, `EGAHEAD.CK2`,
  `EGALATCH.CK2`, `EGASPRIT.CK2`. Levelnummers 1-16, 80, 81 en 90 als
  constanten.
- **Gedeelde code, alleen toevoegingen (standaard = Keen 1):** `GameFiles`
  kreeg `extension`, `required_files`, `level_file(n)`, `locate_in`,
  `first_complete` en `candidate_directories_in`; `locate()` doet precies
  hetzelfde als voorheen. `EgaGraphics.load_from(files, extension)`,
  `TileProperties.find_in_image(image, count, known_offsets)` en
  `FinaleImage.load_from(files, file_name)` kregen een optionele parameter.
  `EgaHeader` hoefde niet te veranderen.
- **KEEN2.EXE:** `Keen2Executable` pakt de EXE uit en vindt op inhoud (de
  bekende adressen van 1.31 eerst, alleen als de inhoud klopt): het
  geluidsblok (`SND\0`, gaat naar `SoundFile.parse`), de tile-eigenschappen
  (aantal uit `EGAHEAD.CK2`), de vier tekstblokken (eindtekst, help,
  previews, verhaal; klaar voor `TextDocument.layout`), de acht steden en
  `TO BE CONTINUED....`. De versie komt uit de grootte (1.31, 1.00 of
  "unknown"). Niets crasht als een stuk ontbreekt.
- **Startscherm:** een tweede icoon "Keen 2" rechts van Keen 1. Zonder
  bestanden grijs, met de uitleg dat ze in `game_data/keen2` horen (de tekst
  voor Keen 1 is letterlijk dezelfde gebleven). Met bestanden staat Keen uit
  de eigen Keen 2-graphics op het icoon, zoals bij Keen 1.
- **Voorlopig scherm:** `src/keen2/keen2_view.tscn` (`Keen2View`) zegt "Keen
  2 - coming soon"; Enter of Escape gaat terug naar het startscherm (via
  `call_deferred`, zoals de fix van mijlpaal 11).
- **Opdrachtregel:** `-- --game=2` (met of zonder `--level=N`) slaat het
  startscherm over en opent Keen 2. Zonder `--game=2` verandert er niets.
  Net als bij Keen 1 met `--level` komt "terug naar het startscherm" dan
  meteen weer in het spel uit.
- **Data viewer en export:** `-- --game=2` toont Keen 2 in de data viewer
  (met in de statusregel de versie van `KEEN2.EXE` en wat erin gevonden
  is) en exporteert met `tools/export_graphics.gd` naar `exported/keen2/`.
- **Tests:** `test_keen2_files` (zonder data: map zoeken, hoofdletters,
  vereiste bestanden, `.CK2`-levels, Keen 1-standaarden ongewijzigd, een
  zelfgemaakt EXE-beeld met geluid, teksten, steden en tile-tabel, een beeld
  zonder die stukken, versies, de catalogus met twee spellen, `--game=2`,
  het voorlopige scherm), `test_keen2_renamed_keen1` (de Keen 1-shareware
  onder Keen 2-namen laadt via het Keen 2-pad) en `test_keen2_data` (echte
  Keen 2-bestanden; wordt hier overgeslagen). In `tests/test_launcher.gd`
  is één regel aangepast (met toestemming van de architect): de catalogus
  heeft nu twee spellen in plaats van "one game for now".
- **Keen 1-controle:** alle bestaande tests slagen, gdlint is schoon. Van de
  screenshots verschilt alleen `launcher.png` (het tweede icoon, zoals
  verwacht). `tools/keen1_regression.sh` draait Godot nu met
  `--fixed-fps 60`; zonder dat wisselden de levelplaatjes van run tot run
  (timing). De referentie komt van `main` in een aparte worktree.
- **Nog niet gecontroleerd (wacht op echte bestanden):** 689 tiles en 134
  sprites, de grootte en versie van `KEEN2.EXE`, de plek en de namen van het
  geluidsblok (`EARTHPOW`), dat de teksten op 0x1A eindigen, de stadsnamen
  en hun lengtes, de tile-eigenschappen, en de open vragen 1-12 uit
  `research.md`. De berichten van de Vorticon-oudste en de eindteksten
  worden nog niet gelezen (komt met `Keen2Texts`).

## Mijlpaal B3: wat er nu is

Gebouwd zonder echte Keen 2-bestanden: getest met zelfgemaakte levels en
met de Keen 1-bestanden onder Keen 2-namen. De regels staan in
`docs/keen2/gameplay.md`.

- **Het spelscherm:** `Keen2View` (`src/keen2/keen2_view.gd`) bouwt nu op
  `GameScreen`, net als Keen 1: widescreen met HUD, F1-F6 (ook xBRZ en HD),
  de camera die Keen volgt, berichten. De scène heeft dezelfde opbouw als
  `level_view.tscn`. Het laden zit in `Keen2GameData` (graphics,
  tile-eigenschappen en geluid uit `KEEN2.EXE`; zonder geluidsblok een
  `SOUNDS.CK2` als die er ligt, alleen handig voor de testdata).
- **Voorlopig verloop** (`Keen2LevelPlay`, tot de kaart in B6): vanaf het
  startscherm level 1, met `-- --game=2 --level=N` level N (1-16). De
  uitgang gaat naar het volgende level, na level 16 terug naar het
  startscherm. Dood: een leven minder en hetzelfde level opnieuw ("Keens
  left: N"); geen levens meer: "Game over" en terug naar het startscherm.
  Escape gaat altijd terug. Cheats zoals bij Keen 1: Shift+N/P, Shift+I,
  Shift+G.
- **Een level** (`Keen2LevelSession`, een subklasse van `LevelSession`):
  punten (500/100/200/1000/5000), straalgeweer (+5), sleutelkaarten en
  deuren (worden tile 143), uitgang, dodelijke tiles, extra leven per
  20.000, item-tegels vanaf 305 laten 276 achter. Geen vijanden (B4), geen
  scheepsonderdelen, het gedrag 22 (de Vorticon-oudste) en 24 doen nog
  niets. Keen heeft de pogo vanaf het begin; schoten gebruiken de Keen
  2-sprites 122-125 (`Keen2Shot`).
- **Inventaris:** `Keen2Inventory`: 4 levens, pogo, 0 ladingen bij de start
  (*schatting*, nog naast het origineel leggen).
- **HUD:** levens, score, ladingen, sleutelkaarten; geen onderdelen. De
  plaatjes van het straalgeweer en de kaarten zoekt `Keen2Icons` op in de
  tile-eigenschappen (de eerste tile met dat gedrag).
- **Plaatjes achter de levels:** nog niet (B8); de Keen 1-plaatjes komen
  nooit achter een Keen 2-level.
- **Gedeelde code, gedragsneutraal:** `LevelSession.create` roept nu
  `_set_up` aan (dezelfde regels in dezelfde volgorde), plus drie haken
  met de oude code als standaard: `_is_item`, `_touch_special_tile`
  (teleporter en beelden) en `_create_shot`. `Hud` kreeg `raygun_tile` en
  `keycard_icons` (standaard de Keen 1-tiles) en `Hud.keycard_tiles` een
  optionele parameter. `GameScreen` hoefde niet te veranderen.
- **Tests:** `test_keen2_level` (zelfgemaakte levels: punten, straalgeweer,
  kaarten en deur, dodelijke tile, uitgang, pogo vanaf de eerste tick,
  extra leven, 22/24/onderdelen doen niets, info-waarden maken niets aan,
  schot-sprites, de scène) en `test_keen2_stand_in` (Keen 1-bestanden als
  Keen 2: laden, level 1 spelen, uitgang, dood, game over, na level 16).
  De B2-test van het voorlopige scherm is weggehaald (dat scherm bestaat
  niet meer). Screenshots met de testdata: stilstaan, lopen, springen,
  pogo, HUD met items, 4:3, xBRZ, level 2.
- **Keen 1-controle:** alle tests slagen, gdlint schoon, de screenshots van
  titel, level 1 (ook lopend) en kaart zijn byte voor byte gelijk aan
  `main`; alleen `launcher.png` verschilt (het icoon van B2, gelijk aan de
  B2-screenshots).

## Mijlpaal B4: wat er nu is

Gebouwd zonder echte Keen 2-bestanden: getest met zelfgemaakte levels en
met de Keen 1-bestanden onder Keen 2-namen. De regels en alle getallen
staan in `docs/keen2/gameplay.md`; elk getal uit Commander Genius heeft
`# estimate` in de code en staat in de lijst onderaan dat document.

- **Vijanden uit de info-laag** (`Keen2LevelSession.create_enemy`): 1
  grunt, 2 youth, 3 Elite, 4 Scrub, 5 Guard robot, 6 bewegend platform (4
  pixels boven zijn cel). 7 (de vonk) komt in B5; waarden van 0x100 en
  hoger zijn nooit vijanden. Ze worden wakker als ze in beeld komen, het
  platform is altijd wakker. Kansen gaan zoals in Commander Genius (n + 1
  op 1000 per tick) met de vaste seed van de sessie.
- **De vijanden** (`src/keen2/actors/`, op de gedeelde `Enemy` via
  `Keen2Enemy`): de grunt (kijkt rond, loopt, springt, springt uit een
  kuil; 1 schot; frame 86 en dan 87, geen witte flits; springt niet in het
  donker via `Keen2LevelSession.is_dark()`, nu altijd false), de youth
  (snel, huppelt; **verdooft** Keen), de Elite (4 schoten, stormt op Keen
  af als hij dichtbij op zijn hoogte staat, schiet met KEENFIRESND), de
  Scrub (kruipt langs vloer, muur en plafond, valt van een dunne richel,
  ongevaarlijk, SHOTHIT bij doodgaan), de Guard robot (zweeft, onkwetsbaar,
  houdt Keens schoten tegen, salvo's van 4 met TANKFIRE) en het platform
  (heen en weer, wacht 51 ticks bij een muur, slikt schoten).
- **Vijandschoten** (`Keen2EnemyShot`, sprite 123, 108/32): doden Keen,
  maar korten bij een verdoofde Keen alleen de verdoving in tot 20 ticks.
  Ze raken andere vijanden zoals in Commander Genius, achter één constante
  `ENEMY_SHOTS_HURT_ENEMIES := true  # estimate` (B10 kan hem omzetten);
  niet hun eigen soort, en een Elite blijft heel bij een schot van een
  Guard robot.
- **Verdoving** (`Keen2Body extends KeenBody`, `src/keen2/keen/`): omhoog
  met een volle sprong, pogo weg, kijkt de kant van de youth op, 250 ticks
  geen knoppen (vallen en wrijving gaan door), frames 28/29 om de 26 ticks
  en de laatste 20 ticks frame 31. Keen 1's `freeze()` past niet (andere
  frametijd, geluid, duw) en is niet aangeraakt.
- **Meerijden** op platform en Scrub (`Keen2Carrier`): Keen krijgt een
  eigen botsing (`Keen2RidingCollision extends LevelCollision`) waarin de
  bovenkant van zo'n drager een vloer is; de sessie schuift hem elke tick
  mee met de drager. Loopt hij tegen de zijkant, dan wordt hij opzij
  geduwd. Zolang hij meerijdt kan hij niet door de uitgang.
- **Gedeelde code: niets veranderd.** Alles zit in `src/keen2/` en in de
  Keen 2-tests; `git diff` buiten `src/keen2/` is leeg. De haken die er
  al waren (`KeenBody.collision`, de instance-methodes van `LevelSession`:
  `_spawn_enemies`, `_create_keen`, `_resolve_hits`, `_shoot_keens`,
  `_touch_tiles`, `_is_exit`) waren genoeg. Alle geluiden hadden al een
  `Sound.Id`.
- **Tests:** `test_keen2_enemies` (welke info-waarde wat maakt, wakker
  worden, grunt loopt/keert/springt en niet in het donker, één schot,
  dodelijk, youth verdooft 250 ticks met de juiste frames en Keen staat
  weer op, schot op verdoofde Keen, vijandschot doodt Keen, Elite stormt
  en schiet en kan 4 schoten hebben, Guard robot zweeft, salvo van 4 om de
  13 ticks, onkwetsbaar, dodelijk, friendly fire aan en uit, Elite heel bij
  Guard robot-schoten en eigen soort) en `test_keen2_riding` (Scrub rond
  een kamer en rond een blok, valt van een dunne richel, Keen rijdt mee op
  een Scrub, Scrub duwt Keen, platform neemt Keen mee en wacht 51 ticks,
  platform altijd actief, geen uitgang tijdens meerijden, platform houdt
  schoten tegen, Scrub sterft). `test_keen2_stand_in` speelt nu elk level
  600 ticks met de vijanden die uit de Keen 1-info komen (alle zes soorten
  komen voor). In `test_keen2_level` werd de B3-test "info-waarden maken
  niets" aangepast. De twee nieuwe suites staan in `tests/run_tests.gd`.
- **Screenshots met de testdata** (Keen 1-plaatjes onder Keen
  2-spritenummers, dus een grunt ziet eruit als een Vorticon en een youth
  als een Yorp; het platform en sprites vanaf 119 zijn onzichtbaar):
  grunts lopen, springen op een richel en gaan dood van schoten (level 3),
  een youth rent en maakt grote sprongen (level 13), level 8 met Scrubs en
  een Guard robot.
- **Keen 1-controle:** alle tests slagen, gdlint schoon, titel, level 1
  (ook lopend) en kaart byte voor byte gelijk aan `main`; alleen
  `launcher.png` verschilt (gelijk aan de B2-screenshot).
- **Open:** de botsingsvakken van de vijanden zijn schattingen (pas met
  `EGAHEAD.CK2` te lezen); de hoekregels van de Scrub zijn eigen werk; of
  vijandschoten in het origineel andere vijanden raken; de sprites 84/85
  (springen links/rechts).

## Mijlpaal B5: wat er nu is

Gebouwd zonder echte Keen 2-bestanden: getest met zelfgemaakte levels, een
zelfgemaakte map 81 en de Keen 1-bestanden onder Keen 2-namen. De regels
en de schattingen staan in `docs/keen2/gameplay.md`.

- **Schakelaars met de pogo-knop** (`Keen2Switches`, via `Keen2Body`):
  staat er een tile met gedrag 23, 25 of 26 in de kolom door Keens midden
  (van zijn voeten omhoog, stappen van 8 pixels), dan drukt de knop de
  schakelaar in en komt de pogo niet tevoorschijn (hij wordt weggezet).
  Elke druk klikt (CLICKSND); een hendel wisselt 493 ↔ 480.
- **Bruggen** (`Keen2Bridge`): info-waarde ≠ 0 = afstand naar het begin
  (lage byte kolom, hoge byte rij, met teken). Elke 4 ticks een tile 270,
  naar rechts tenzij daar een muur staat, tot de eerste blokkerende tile;
  nog eens drukken haalt hem tile voor tile terug vanaf het verre eind en
  zet de onthouden achtergrond terug. Keen kan erop staan, ook terwijl hij
  groeit.
- **Licht** (gedrag 23, info 0): `is_dark()` is nu echt; grunts en Elites
  springen niet in het donker; een level begint altijd met licht. Het
  donker is `Keen2Darkness` (een `CanvasModulate` in de World-viewport, 30 %
  helderheid, één constante): werkt met origineel, xBRZ, HD en widescreen,
  de HUD en vensters blijven helder.
- **Vorticon-oudste**: gedrag 22 spreekt alleen met tile 429 er direct
  onder, die daarna 182 wordt (dus maar één keer). Het bericht komt in
  het gedeelde venster (`GameWindow`), het spel wacht tot Enter.
  `Keen2Executable` zoekt de twee berichten op hun bekende plek (0x19FCC,
  0x1A08C) en accepteert ze alleen als leesbare tekst; anders geen venster.
  Level 8 heeft het eerste bericht, de andere het tweede (*schatting*).
- **De Tantalus-straalmachine**: de vonk (`Keen2Spark`, info 7, 128-131),
  ongevaarlijk, één schot van Keen (niet van vijanden) en de machine valt
  stap voor stap uit elkaar (`Keen2Tantalus`, elke 26 ticks: glas, koepel,
  schakelaar → 506, drie keer paars → 505 met 10.000 punten, vier
  gloeikolommen → 549, het scherm → 533). De sessie telt de machines
  (`machine_count`, `machines_destroyed`, `all_machines_destroyed()`) voor
  B6.
- **De verkeerde schakelaar**: gedrag 25/26 met info 0 naast een hele
  machine → licht aan, alles staat stil, Keen weg, het scherm schudt 2
  seconden, dan op map 81 `Keen2EarthExplosion`: de straal vliegt van (4,9)
  naar kolom 47, explosies rond de aarde, kleine en grote brokken alle
  kanten op (niet zoals CG allemaal één kant), de aarde wordt 561, na stap
  32 klaar; EARTHPOW bij de inslag (eigen keuze, `Keen2Sounds`). Dan GAME
  OVER (het plaatje of tekst) en terug naar het startscherm, hoeveel levens
  Keen ook had (`Keen2LevelPlay.State.EARTH_EXPLODED`).
- **Gedeelde code: niets veranderd.** Alles zit in `src/keen2/` en de Keen
  2-tests; alleen `tests/run_tests.gd` kreeg twee regels voor de nieuwe
  suites. Alle tile-wijzigingen gaan via `set_tile` → `tile_changed`, ook
  op map 81 (eigen signaal met dezelfde betekenis).
- **Tests:** `test_keen2_switches` (pogo op en naast een schakelaar,
  bruggen naar rechts en links, stoppen bij een muur, terughalen met
  achtergrond, erop staan, signed offsets, niets op een schakelaar, licht
  aan/uit, Vorticons in het donker, de oudste één keer, de zoekers van de
  berichten in een zelfgemaakte EXE) en `test_keen2_tantalus` (de vonk
  neerschieten: alle tiles en 30.000 punten, stappen van 26 ticks,
  schakelaar bij een kapotte machine doet niets, bij een hele machine
  ontploft de aarde ongeacht de levens, vijandschoten gaan door de vonk,
  de scène op een kleine map 81 eindigt met de aarde 561, de straal).
  `test_keen2_stand_in` drukt nu ook af en toe op de pogo-knop en speelt de
  explosie op Keen 1's map 81. In `test_keen2_level` en
  `test_keen2_enemies` maakt info 7 nu een vonk.
- **Screenshots met de testdata** (een tijdelijk script zette Keen 1's
  tile 271 met gedrag 23 naast Keen): een brug die uitschuift (Keen 1's
  tile 270), dezelfde brug met xBRZ (F5), donker met xBRZ en origineel,
  het venster van de oudste in het donker (leesbaar), het schudden, de
  straal, explosies en brokken op map 81, de aarde weg, GAME OVER.
- **Keen 1-controle:** alle tests slagen, gdformat en gdlint schoon,
  titel, level 1 (ook lopend) en kaart byte voor byte gelijk aan `main`;
  alleen `launcher.png` verschilt (gelijk aan de B2-screenshot).
- **Open:** hoe het donker er in het origineel uitziet; of de berichten
  van de oudste echt als één record met regeleinden in de EXE staan en in
  welke levels; hoe het origineel voorkomt dat Keen een stad verlaat
  zonder de machine te vernietigen (nu houdt niets hem tegen); 10.000 of
  30.000 punten; met de CG-snelheden eindigt de straal zo'n zes tiles
  onder de aarde (de explosies zitten daarom rond het midden van de aarde).

## Mijlpaal B5.1: wat er nu is

Op 17-10-2026 voor het eerst met echte Keen 2-bestanden (de eigen
bestanden van de gebruiker, versie 1.31, in `game_data/keen2` en naast de
app in `build/game_data/keen2`). Details in `docs/keen2/research.md`
("Checked with the real files") en `docs/keen2/file-formats.md`.

- **Klopte al:** versie 1.31 (58.335 bytes, beeld 118.160), 689 tiles, 134
  sprites, 18 bitmaps, alle levels (1-16, 80, 81, 90), de vier teksten op
  hun plek met 0x1A, het geluidsblok met `EARTHPOW`, de tile-tabel
  (hendels 480/493 met gedrag 25/26, geen ijs), de regel 276/143 achter
  items, de plek van de machine rond elke vonk (alle 8 steden), de
  bruggen (offsets in levels 5, 13 en 16), map 81 met tile 593, de HUD
  (175 en 190-193, dezelfde nummers als Keen 1), de botsingsvakken van
  grunt, Elite, Scrub en Guard robot.
- **Gerepareerd:**
  - De stadsnamen werden niet gevonden: de achtste heet `Wash D.C.` (punt
    toegestaan).
  - De berichten van de oudste werden niet gevonden: in de EXE is elke
    regel een eigen record (zoals bij de beelden van Keen 1), daarna
    `Press ENTER:`. Nu worden de regels samengevoegd; de test gebruikt het
    echte formaat.
  - Guard robot: 112-115 is links en 116-119 rechts (CG had het
    omgekeerd). Elite springen: 98 links, 99 rechts (was omgedraaid).
  - Botsingsvakken uit `EGAHEAD.CK2`: platform 32x16 (was 32x8), vonk
    (2,2,12,12) (was 16x16), youth (1,6,14,18) (was een gok). De
    rechterframes van de youth hebben het Yorp-vak van Keen 1, vermoedelijk
    een overblijfsel; we gebruiken het linkervak voor beide kanten
    (*schatting*, anders loopt hij bij het omdraaien een muur in).
  - De aarde op map 81 is 3x3 op (47,22), niet 4x4 op (47,21).
  - Commentaren en `# estimate` bijgewerkt: wat de bestanden vastleggen
    heeft geen `estimate` meer (spritenummers, vakken, 429, 480/493, 155,
    de aarde); tiles die erin gezet worden (270, 182, het wrak, 561) houden
    `estimate`, hun plaatjes passen wel.
- **Vastgesteld:** de oudsten staan alleen in **levels 8 en 10** (tile 559
  met 429 eronder); 375/376 hebben ook gedrag 22 maar zwijgen. 429-432 is
  een gloeiende blauwe vloer (dodelijk volgens de tabel), 182 dezelfde
  vloer zonder gloed. Wereldkaart: ingangen 1-16, 0x8001 en 0x8005, geen
  teleporters en geen 20.
- **Gespeeld** (met een wegwerp-stuurscript in de scratchpad): level 1, 4
  (Londen: vonk kapotgeschoten, het wrak met de juiste tiles, 30.000
  punten, de hendel doet daarna niets; de verkeerde hendel: schudden, de
  straal, de aarde ontploft; licht uit/aan), 5 (de brug over het vuur), 8
  (het bericht van de oudste, 8 regels) en 12 (platforms).
- **Gereedschap (additief):** `tools/scripted_play.gd` kreeg
  `WAIT_FOR_WINDOW=1`, omdat een nieuw macOS-venster een wisselend aantal
  frames wit blijft; `tools/keen1_regression.sh` zet het aan zonder xvfb.
  De buildscripts kopiëren `game_data/keen2` mee als die er is.
- **Tests:** `test_keen2_data` slaagt nu en controleert ook stadsnamen,
  berichten, spritenamen, vakken, hendels, iconen, de oudste-levels, de
  machines en map 81.
- **Keen 1-controle:** alle tests slagen, gdlint schoon, titel, level 1
  (ook lopend) en kaart byte voor byte gelijk aan `main` (bf394ed, met de
  nieuwe wachtstand); alleen `launcher.png` verschilt (het Keen 2-icoon, nu
  met de echte data). Opgemerkt: `level1.png` en `level1_walk.png` zijn in
  beide sets gelijk, dus het "lopen" in het regressiescript beweegt Keen 1
  niet; dat was op `main` al zo.
- **Nog open:** startlading van het straalgeweer (0, *schatting*; staat
  alleen in de code van de EXE, dus naast het origineel leggen), versie
  1.00, en alles wat alleen het origineel kan laten zien (research.md,
  vragen 13-20).

## Mijlpaal B6: wat er nu is

Gebouwd en gespeeld met de echte Keen 2-bestanden (v1.31). Keen 2 is nu van
begin tot eind uit te spelen. De regels staan in `docs/keen2/gameplay.md`
("The course of the game", "The status screen", "The ending").

- **Wereldkaart (map 80):** een nieuw spel begint op de kaart bij het
  schip, met "Keens Left". Lopen, met springen/pogo een level in, na de
  uitgang terug op de plek van de ingang met het "DONE"-bord (77 of
  78-81); een klaar level kan niet opnieuw. Ingangen met 0x8000 (levels 1
  en 5) houden de weg dicht tot dat level klaar is. Dood: een leven minder
  en terug op de kaart met "Keens Left". `--level=N` speelt eerst level N
  en gaat daarna naar de kaart.
- **Hergebruik zonder wijziging:** Keen 1's `MapSession`, `MapCollision`,
  `MapKeen` en `MapMessages` werken ongewijzigd voor Keen 2's kaart (geen
  schip, geen teleporters); er is dus geen `Keen2MapSession`. Afwijking
  van het plan, uitgelegd in `docs/keen2/architecture.md`.
- **Steden:** `Keen2Progress` (op `GameProgress`): een stad is gered als
  zijn level klaar is (levels 4, 6, 7, 9, 11, 13, 15, 16). Alle acht gered:
  het einde.
- **Statusscherm (Enter):** het vak met de teksten uit `KEEN2.EXE` (SCORE,
  EXTRA KEEN AT, KEENS, PISTOL, TARGETS SAVED, KEYS, PLEASE PRESS A KEY),
  score, volgende extra Keen, een Keentje per leven, het pistool (414) met
  ladingen, de geredde steden en de sleutelkaarten (424-427). Plekken uit
  Commander Genius (*schatting*).
- **Het einde** (`Keen2Ending`, `Keen2Flight`): Keens schip vliegt op map 81
  van het moederschip naar de aarde (met de getallen van CG landt het
  precies op de aarde), daarna het moederschip met de tweede tekst,
  `FINALE.CK2` met de vier pagina's en `TO BE CONTINUED....`, dan de
  eindtekst (scrollen), dan het startscherm. Alle teksten uit de EXE.
- **Scherm:** `Keen2View` werd te groot en is gesplitst: map 81 (aarde
  ontploft, het einde) zit nu in `Keen2SpaceScreen`. Drie methodes van
  `GameScreen` die Keen 1's einde of scheepsonderdelen kennen worden in
  Keen 2 overschreven; `GameScreen` zelf is niet veranderd.
- **Tests:** nieuwe suite `test_keen2_ending` (steden, statusscherm,
  vluchten, het einde, teksten in een zelfgemaakte EXE);
  `test_keen2_stand_in` speelt nu de kaart (start, level in, uitgang en
  dood terug naar de kaart, DONE, winnen); `test_keen2_data` controleert
  het statusvak, de eindteksten en de ingangen van map 80. De B3-tests
  "uitgang → volgend level" en "na level 16 klaar" zijn vervangen (Keen
  2-tests).
- **Gespeeld met screenshots:** de kaart met "Keens Left", het statusscherm
  met London en Cairo, Londen in via de ingang en terug met DONE, het hele
  einde (schip, moederschip, plaatje met pagina's, eindtekst).
- **Keen 1-controle:** alle tests slagen, gdlint schoon, titel, level 1
  (ook lopend) en kaart byte voor byte gelijk aan `main`; `launcher.png`
  gelijk aan die van B5.1. Buiten `src/keen2/` en de Keen 2-tests is niets
  veranderd.
- **Open:** of een stad in het origineel pas gered is als de machine kapot
  is (en hoe het origineel Keen tegenhoudt); de plekken op het
  statusscherm; of het origineel `TO BE CONTINUED....` en de eindtekst na
  de pagina's toont; de high scores na het einde (B7).

## Mijlpaal B7: wat er nu is

Gebouwd en gespeeld met de echte Keen 2-bestanden. Regels in
`docs/keen2/gameplay.md` ("Title, menus, saving and high scores").

- **Titelscherm:** map 90 met het `TITLE`-plaatje (ruimte, moederschip,
  aarde). Titel en high scores wisselen elke 8 seconden; een toets opent
  het hoofdmenu. Vanaf het startscherm gaat het menu meteen open.
- **High scores:** eigen tabel (`Keen2HighScores`) met naam, score en
  aantal geredde steden, onder het `SAVED`-plaatje ("Cities saved").
  Standaardnamen Yorpy, Gargile, Zzapp! uit `KEEN2.EXE`. Na GAME OVER of
  het einde: de high scores, en bij een goede score een naam invullen.
- **Hoofdmenu (gedeeld):** New Game, Continue Game, Save Game (alleen op
  de kaart), Story (uit de EXE), High Scores, Controls, Options, Quit to
  Title, Choose Game, Quit. Zonder Online Game, Player 2 en Extra levels.
- **Opslaan:** 9 plekken in `user://keen2/saves`, apart van Keen 1;
  high scores in `user://keen2/high_scores.json`. Toetsen en
  beeldinstellingen zijn gedeeld.
- **Gedeelde code:** één toevoeging: `MenuController` kreeg
  `offers_online`, `offers_second_player` en `offers_extra_levels`
  (standaard aan, dus Keen 1 blijft gelijk; getest). Keen 1's
  `Backdrops`, `ScoreTexts` en `SaveGames` worden ongewijzigd gebruikt.
- **Code:** nieuw `Keen2MenuScreen` (titel, high scores, menu, opslaan)
  tussen `Keen2SpaceScreen` en `Keen2View`; alle bestanden onder 500
  regels. Gerepareerd tijdens het testen: na "New Game"/"Continue" keek de
  HUD nog naar de oude voortgang.
- **Tests:** nieuwe suite `test_keen2_menus` (tabel, scherm, opslaan en
  laden, nieuw spel, menu's van Keen 2 en Keen 1); `test_keen2_data`
  controleert verhaal en high score-teksten.
- **Gespeeld met screenshots:** titel, high scores, hoofdmenu, verhaal,
  menu in het spel, opslaan in plek 1 en weer laden, GAME OVER → naam →
  high scores.
- **Keen 1-controle:** alle tests slagen, gdlint schoon; titel, level 1
  (ook lopend) en kaart byte voor byte gelijk aan `main`; `launcher.png`
  verschilt alleen op de plek van het Keen 2-icoon.
- **Open:** de plekken in de high score-tabel (schatting); het origineel
  toont na een spel waarschijnlijk "You saved N cities!" (de teksten staan
  in de EXE, nog niet gebruikt); de intro, "About ID", "Ordering Info" en
  "Previews!" zijn niet nagebouwd (net als bij Keen 1).

## Mijlpaal B8: wat er nu is

- **Besluit van de gebruiker (17-10-2026):** geen Real-ESRGAN/HD voor Keen
  2 (ook bij Keen 1 niet mooi genoeg; misschien gaat het daar ooit uit).
  xBRZ zat er al in.
- **xBRZ (F5), vloeiende beweging (F6), widescreen:** werken voor Keen 2
  via de gedeelde code; alle Keen 2-figuren, Keen op de kaart en de
  schepen van het einde bewegen vloeiend.
- **Plaatjes achter levels:** eigen map `assets/backgrounds/keen2/` (nog
  leeg) of die van de speler `game_data/keen2/backgrounds/levelNN.png`;
  nooit die van Keen 1. Omdat de meeste Keen 2-levels een ruitpatroon als
  achtergrond hebben (het plaatje zou door de stipjes heen schijnen), krijgt
  een level alleen een plaatje als zijn effen achtergrond ook de meest
  gebruikte tile is; in v1.31 is dat alleen level 12. Getest met een
  tijdelijk plaatje (weer verwijderd). In het donker wordt het plaatje mee
  donker.
- **Gedeelde code:** één toevoeging: `BackdropPictures.create` kreeg een
  optionele map (standaard die van Keen 1).
- **Builds:** macOS en Windows nemen `game_data/keen2` mee (sinds B5.1);
  vanaf nu worden na elke mijlpaal beide gebouwd.
- **Tests:** nieuwe suite `test_keen2_extras`. Keen 1-controle: alle tests
  slagen, gdlint schoon, screenshots gelijk aan `main` (alleen het icoon
  op het startscherm verschilt).
- **Voor de gebruiker:** wil je plaatjes achter Keen 2-levels, zet ze in
  `game_data/keen2/backgrounds/`. Voor levels met het ruitpatroon zou een
  andere aanpak nodig zijn (het patroon vervangen); dat kan later.

## Mijlpaal B9: wat er nu is

- **Twee spelers op één toetsenbord:** F7 of "Add Player 2" in het menu,
  zoals bij Keen 1: speler 2 (blauwe helm) in het level, split screen als
  ze uit elkaar gaan, gedeelde inventaris, één dood geldt voor beiden. Alles
  van Keen 2 werkt voor beide Keens: verdoofd door een youth, meerijden,
  schakelaars (ook de Tantalus-hendel), de oudste; het donker op beide
  helften. Geen gedeelde code veranderd.
- **Online:** hosten en meedoen via IP of Steam, zoals bij Keen 1. Keen 2
  heeft een eigen spel-id: een Keen 1-host en een Keen 2-speler komen niet
  bij elkaar ("The host plays another game: another Keen"); Steam toont
  alleen lobby's van hetzelfde spel; de vingerafdruk gebruikt de
  `.CK2`-levels. De snapshot stuurt de geredde steden mee (statusscherm
  van de meespeler), en als gebeurtenis: de oudste, "Keens Left", licht
  uit/aan. De ontploffing van de aarde is een eigen scène. Na game over of
  het einde wacht de meespeler bij zijn titel.
- **Gedeelde code (toevoegingen, Keen 1 byte voor byte gelijk):** de
  spel-id door handshake/sessie/Steam, de reden `OTHER_GAME`, een scène en
  een gebeurtenis achteraan de enums, `progress_bits` in de snapshot (0
  bij Keen 1), en de vingerafdruk via `files.level_file()` (zelfde
  bestanden voor Keen 1; getest).
- **Code:** nieuw `Keen2OnlineScreen` in de keten van schermklassen.
- **Getest:** nieuwe suites `test_keen2_coop` en `test_keen2_online`; de
  Keen 1-onlinetests slagen ongewijzigd. Gespeeld: split screen; online met
  een headless host en een meespeler in een venster (binnenkomen, de kaart,
  Londen met twee Keens, het statusscherm).
- **Meedoen met het andere deel (wens van de gebruiker):** via IP of uit de
  Steam-lijst (die nu de hosts van beide delen toont, met de naam van het
  deel erachter) kun je meedoen met een host van het andere deel: je spel
  schakelt dan vanzelf over naar dat deel en doet daar mee. Zonder de
  bestanden van dat deel krijg je een melding. Getest via IP in beide
  richtingen (Keen 2-speler → Keen 1-host en andersom); Steam kon hier niet
  getest worden (logica met tests gedekt). Keen 1's scherm is daarvoor niet
  veranderd: het zit in de gedeelde online-code en het startscherm.
- **Let op bij testen op één Mac:** met twee vensters tegelijk remt macOS
  het achterste venster af, waardoor de host de handshake te laat
  beantwoordt ("The host did not let you in"). Op twee computers, of met
  een headless host, werkt het (zie `docs/online.md`).

## Mijlpaal B10: wat er nu is

Het originele `KEEN2.EXE` (v1.31) gedraaid in js-dos (DOSBox in de browser,
lokaal geserveerd uit de scratchpad, niets in git) en de ruwe 320x200-beelden
gemeten. Aangepast naar wat het origineel laat zien:

- Een nieuw spel begint met **3 ladingen** voor de raygun (was 0).
- **Statusscherm:** score eindigt voor kolom 10, volgend extra leven voor
  kolom 26, raygun op kolom 21 en de ladingen vanaf kolom 24 (links
  uitgelijnd). Het origineel heeft grijze balken en witte vakjes; wij een
  gewoon venster.
- **Titel** over het eerste scherm van map 90 (muur met vuurtjes) in plaats
  van het ruimtescherm, met ook het bordje "PRESS F1 FOR HELP".
- **Highscores** op het juiste scherm van map 90 (cellen 84-103) en alle
  plekken gemeten. Verschil: het origineel schrijft in rood, wij in zwart.
- **GAME OVER** zonder wit venster eromheen (`GameWindow.framed`, een
  toevoeging met Keen 1 als standaard).
- Nieuwe testsuite `test_keen2_original.gd`.

Niet gemeten: Keen door levels sturen met een script lukte niet
betrouwbaar (de beelden van de emulator lopen achter op de toetsen, Keen
ging dood). Vijanden, verdoving, donker, de machine, de Tantalus-straal,
het einde en de geluidssnelheid houden hun `# estimate`. Gevonden: het
origineel heeft de cheat C+T+Space (alle keycards en veel ladingen).

## Mijlpaal 1: wat er nu is

- `GameFiles`: vindt de spelbestanden (`--data-dir=`, `game_data/keen1/`, of naast de exe) en negeert hoofd/kleine letters.
- `LzwDecompressor` en `RlewDecompressor`: de twee compressievormen van Keen 1.
- `EgaHeader`: inhoudsopgave van alle graphics, ondersteunt ook versie 1.34.
- `EgaGraphics`: font (256), tiles (611), bitmaps (18) en sprites (119, met transparantie).
- `LevelData`: tile- en info-laag van elk level en de wereldkaart.
- Data viewer: levels, tiles, sprites, bitmaps en font bekijken, met zoom. Openen met `godot --path . res://src/viewer/data_viewer.tscn`.
- `tools/export_graphics.gd`: alles als PNG naar `exported/`, de basis voor Real-ESRGAN later.
- Tests: `tests/run_tests.gd` (decompressie, EGA-decodering en de echte Keen 1-data).

Getest met de shareware-versie 1.1 en Godot 4.7.2: alle tests slagen, en de
geëxporteerde PNG's (titelscherm, level 1, wereldkaart, tiles, sprites) zijn
visueel gecontroleerd. De Steam-versie is nog niet getest. Probeer die op je
Mac: zet de bestanden in `game_data/keen1/` en open het project in Godot.

## Mijlpaal 2: wat er nu is

- `LevelView` (`src/game/`) is nu de hoofdscène: je kijkt rond in een level met pijltjes/WASD of de controller, en bladert met Page Up/Down door alle levels en de wereldkaart. Start in een ander level met `-- --level=N`.
- Het level wordt op de originele resolutie getekend in een `SubViewport` en daarna naar het venster geschaald. Zo blijven de pixels scherp en kan xBRZ later als shader op dat beeld.
- `LevelTileSet` en `LevelMap` (`src/level/`): alle tiles in één atlas, een `TileMapLayer` per level.
- `LevelCamera`: scrollt vloeiend en laat nooit iets buiten het level zien. De rand van 2 tiles rond elk level wordt niet getekend; het origineel laat die ook nooit zien. Smalle levels staan in widescreen in het midden met zwarte balken.
- `DisplaySettings`: F2 wisselt tussen origineel (320x200) en widescreen (426x200, 16:9). F3 wisselt tussen pixels zoals op een 4:3-monitor (1,2x zo hoog) en vierkante pixels (dan is widescreen 356x200).
- `FreeLook`: het punt dat de camera volgt. In mijlpaal 3 neemt Keen die rol over. De bewegingsacties heten al `move_left` enz., zodat Keen ze kan hergebruiken.
- `LevelData` kent nu het speelbare gebied (`playable_rect`) en Keens startpositie (info-waarde 255). Beide staan in `docs/file-formats.md`.
- Tests: `tests/test_level_rendering.gd` (zonder speldata), plus nieuwe controles op de echte data: elk level heeft één startpositie en is minstens 320x200 pixels groot.

Getest met Godot 4.7.2 en de shareware-versie 1.1. Alle tests slagen, en de
screenshots van level 1, 2, 90 en de wereldkaart in alle vier de
beeldinstellingen zijn visueel gecontroleerd.

## Mijlpaal 3: wat er nu is

- `DosExecutable` en `LzexeDecompressor` (`src/data/`): pakken `KEEN1.EXE` uit (LZEXE 0.91, eigen implementatie). Alleen datatabellen worden gelezen, geen code.
- `TileProperties`: per tile welke kanten massief zijn, vloertype (gewoon, glad, ijs), gedrag (dodelijk, deur, voorgrond, …) en animatie. De tabel staat in versie 1.1 op 0x131F8 in de uitgepakte EXE; voor onbekende versies (zoals 1.34) wordt hij gezocht aan zijn vorm. `KEEN1.EXE` is nu een verplicht bestand.
- `LevelMap` tekent voorgrond-tiles op een eigen laag vóór Keen en laat geanimeerde tiles (vuur, water, sterren, …) bewegen.
- `LevelCollision` (`src/level/`): botsingen per tilekant, dus ook platforms waar je van onderaf doorheen springt. Buiten het speelveld is muur, behalve onderin: daar val je uit het level.
- `src/keen/`: `KeenBody` (de logica, los testbaar), `KeenPhysics` (alle getallen op één plek), `KeenInput` en de `Keen`-node die tekent. Lopen, springen met aanloop (langer indrukken = hoger), pogo (Alt of X; springknop vasthouden = hoge sprong). Springen kan ook met Z, omdat Ctrl+pijltje op de Mac van bureaublad wisselt, ijs en gladde vloeren, hoofd stoten. Vaste ticks van 1/60 s, los van de framerate.
- Keen loopt in levels 1-16; op de wereldkaart en de speciale kaarten kijk je nog vrij rond (`FreeLook`), want lopen op de kaart is mijlpaal 5. De camera volgt Keen met een kleine dode zone.
- Raakt Keen iets dodelijks of valt hij uit het level, dan begint hij opnieuw bij de start (doodgaan en levens: mijlpaal 4).
- Uitleg en herkomst van alle getallen: `docs/keen-physics.md`. Het EXE-formaat en de gevonden gedragswaarden: `docs/file-formats.md`.
- Tests: `test_tile_properties.gd` en `test_keen_movement.gd` (zonder speldata, met kleine zelfgemaakte levels), plus op de echte data: de tabel wordt gevonden en Keen landt veilig aan het begin van elk level.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en level 1 is met gescripte invoer gespeeld (lopen, springen, pogo)
en via screenshots gecontroleerd. Het gevoel van de besturing is nog niet
naast het origineel gelegd.

## Mijlpaal 4: wat er nu is

- `Inventory` (`src/game/`): score, levens (4 bij de start, extra leven per 20.000 punten), ladingen van het straalgeweer, pogo-stick, sleutelkaarten (alleen binnen een level) en scheepsonderdelen (kwijt als Keen doodgaat in het level waar hij ze vond).
- `LevelSession` (`src/game/`): één poging aan een level, in vaste ticks, zonder nodes, dus volledig testbaar. Items oppakken, deuren openen met de juiste sleutelkaart, de uitgang, schieten, vijanden plaatsen vanuit de info-laag en alle botsingen tussen Keen, schoten en vijanden. Willekeur gebruikt een vaste seed, dus elke poging begint hetzelfde.
- `src/actors/`: `Actor` (basis), `RaygunShot`, `OpeningDoor` (zakt in de vloer), `Enemy` met `Yorp`, `Garg`, `Vorticon`, `Robot` (`ButlerRobot`, `TankRobot`), `IceCannon` met `IceChunk` en `IceBit`, en `StoneChain` (de ketting met de steen in level 16). `ActorLayer` tekent ze.
- `KeenBody`: begint zonder pogo-stick, schiet (met het geweer-frame; op de grond staat hij dan even stil), gaat dood met de `KEENISDEAD`-animatie en vliegt van het scherm, kan bevriezen door ijs, en kan geduwd worden door Yorps en robots.
- `LevelView`: de tick-lus zit nu hier (niet meer in de `Keen`-node, die alleen nog tekent). HUD met score, levens, munitie, pogo, sleutelkaarten en scheepsonderdelen. Doodgaan start het level opnieuw met één leven minder; na het laatste leven begint het spel opnieuw. De uitgang gaat naar het volgende level (tot de wereldkaart er in mijlpaal 5 is).
- Nieuwe knop: vuren met Spatie, C of X op de controller.
- De info-laag is ontcijferd (1-10 en 255), zie `docs/file-formats.md`. Gedrag en herkomst van alle getallen: `docs/enemies.md`.
- Tests: `test_keen_actions.gd` (schieten, pogo vinden, doodgaan), `test_level_session.gd` (items, deuren, uitgang, schoten, levens), `test_enemies.gd` (alle vijanden), plus op de echte data: elke deur heeft een sleutelkaart van zijn kleur in hetzelfde level, en geen enkele vijand valt bij de start uit het level.

Na de eerste speeltest van de gebruiker (14-10-2026) toegevoegd:

- Statusscherm op Enter (of Start op de controller): score, levens, volgende extra leven, straalgeweer met ladingen, pogo, sleutelkaarten en scheepsonderdelen, in de stijl van het origineel (`GameWindow` met de buisrand en het lettertype uit `EGALATCH`, `StatusScreen`). Het spel pauzeert zolang het open is.
- De beeldjes van Yorps en de Garg tonen hun bericht uit `KEEN1.EXE` (`HintTexts`), één keer per poging; daarna gloeien ze niet meer.
- Cheats om te testen: Shift+N / Shift+P (vorig/volgend level, naast Page Up/Down, die op een MacBook Fn+pijltje zijn), Shift+I (alle sleutelkaarten, pogo, 99 ladingen) en Shift+G (god mode).
- Bug opgelost: bij doodgaan sprong de camera even naar linksboven. De camera werd verhangen in de scèneboom, en in dat ene frame had de viewport geen camera. Nu hangt hij vast aan een eigen anker (`CameraAnchor`).
- De uitgang werkt nu zoals in het origineel: alleen als Keen op de grond staat (niet op de pogo-stick of met het geweer in de hand) loopt hij vanzelf langzaam de deur in, verdwijnt er stukje bij beetje achter, en na 200 ticks is het level klaar. Niets kan hem dan nog doden.
- Bug opgelost: in breedbeeld stonden vijanden net buiten het gewone beeld stil en een beetje in de lucht. Vijanden worden nu wakker zodra ze in het echte beeld komen (de view geeft zijn rechthoek door aan `LevelSession`), en ze landen bij de start van het level meteen op de vloer onder hun cel.
- macOS-build: `tools/build_macos.sh` maakt `build/CommanderPerfect.app` (universeel, ad-hoc ondertekend) met de speldata ernaast; `GameFiles` zoekt de data ook naast een `.app`. Hiervoor is de macOS-template van Godot 4.7.2 geïnstalleerd (alleen macOS; Windows volgt in mijlpaal 7).

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn level 1 (Yorps, items), level 4
(deur, schieten) en level 8 (robots, ijskanonnen) gespeeld en via
screenshots gecontroleerd. Een level helemaal uitspelen met de hand moet nog.

## Mijlpaal 5: wat er nu is

- De info-laag van de wereldkaart is ontcijferd (`MapInfo`): 1-16 zijn levelingangen, met `0x8000` erbij blokkeert de cel de weg tot het level klaar is (rechterhelft van level 1, bovenhelft van level 7), 20 is het schip, 38/41/46 zijn teleporters, 255 de start. Zie `docs/file-formats.md` en het nieuwe `docs/world-map.md`.
- `src/map/`: `MapSession` (de kaart in vaste ticks, zonder nodes, testbaar), `MapKeen` (lopen in acht richtingen met de MAPKEEN-sprites), `MapCollision` (tiles plus blokkerende ingangen) en `MapTeleport` (flikkeren, reizen, flikkeren).
- Springen of pogo op een ingang start het level; Keen komt daarna terug waar hij het level in ging, of hij het nu uitspeelde of doodging. Voltooide levels krijgen een DONE-bord (tile 77, of 78-81 voor grote ingangen) en kunnen niet meer in.
- Teleporters: 38 (achter level 7) ↔ 41 (ijs bij level 8, de oostkant van Mars); 46 (bij level 14) → 41. De teleporter in level 13 (gedrag 24) brengt Keen naar 46: zo bereik je level 14. Een test bewijst dat alle 16 levels vanaf de start bereikbaar zijn.
- `GameProgress`: inventaris, voltooide levels en de plek op de kaart. Doodgaan in een level kost een leven en brengt Keen terug naar de kaart; bij de start en na doodgaan verschijnt het "Keens Left"-venster.
- Het schip: zonder alle onderdelen het bericht "Your ship is missing these parts" met plaatjes van wat ontbreekt. Met alle vier de onderdelen begint het einde zodra Keen terug is op de kaart.
- Het einde (`EndingSequence`, `ShipFlight`): Keen repareert zijn schip, vlucht van Mars naar de aarde op kaart 81 (met "?" en "!"), het plaatje van zijn huis uit `FINALE.CK1` (`FinaleImage`) met het gesprek en het licht in de slaapkamer (`WINDON`/`WINDOFF`), de vlucht naar het moederschip en tot slot `ENDTEXT.CK1` (`TextDocument`, scrollen met omhoog/omlaag). Daarna begint een nieuw spel.
- Alle teksten komen uit de eigen `KEEN1.EXE` van de speler (`EndingTexts`, met de gedeelde helper `ExeStrings`, die ook `HintTexts` nu gebruikt).
- `LevelView` speelt nu het hele spel: kaart → level → kaart → einde. Het spel start standaard op de wereldkaart. Nieuwe optie `-- --ending` om meteen het einde te zien. Shift+N/P bladeren nu door alle kaarten.
- `tools/export_graphics.gd` exporteert ook het FINALE-plaatje.
- Tests: `test_world_map.gd` (lopen, ingangen, blokkades, DONE-borden, teleporters, schip), `test_ending.gd` (vluchten, de stappen van het einde, tekstopmaak, FINALE-decoder, teksten uit de EXE), een teleporter-test in `test_level_session.gd`, en op de echte data: alle ingangen bestaan, elk level is bereikbaar, Keen loopt level 1 in, alleen level 13 heeft een teleporter, en de eindbestanden zijn leesbaar.

- Bug opgelost (speeltest 14-10-2026): bij de start van een level viel Keen 8 pixels naar beneden. De startcel zet de bovenkant van zijn 24 pixels hoge sprite bovenaan de cel; nu staat hij meteen op de vloer eronder.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn de kaart (Keens Left, statusscherm,
het schipbericht, level 1 in) en het hele einde opgenomen en via screenshots
gecontroleerd. Het spel helemaal met de hand uitspelen moet nog.

## Mijlpaal 6: wat er nu is

- **Geluid.** `SoundFile` leest `SOUNDS.CK1` (41 geluiden met prioriteit; formaat in `docs/file-formats.md`). `SpeakerSynth` maakt van elk geluid een blokgolf zoals de PC-speaker (140 stappen per seconde, met een zacht laagdoorlaatfilter), en `SoundPlayer` speelt ze op één kanaal: een nieuw geluid onderbreekt alleen een geluid met een lagere of gelijke prioriteit. Keen (lopen, springen, landen, pogo, hoofd stoten, schieten, doodgaan, bevriezen), items, deuren, de uitgang, vijanden, de kaart (stappen, botsen, level in, teleporter), "Keens Left", game over en highscores hebben hun geluid. Welk geluid waarbij hoort (en wat nog een gok is) staat in `docs/sounds.md`.
- **Titelscherm.** Het spel start nu op het titelscherm: Keen bij zijn schip uit map 90 met het TITLE-plaatje erboven. Na 8 seconden wisselt het af met de highscores. Een toets opent het hoofdmenu. `Backdrops` snijdt de schermen uit map 90 (`LevelData.crop`), zodat breedbeeld zwarte balken geeft. `-- --level=N` start nog steeds direct in een level.
- **Menu's** (`src/menu/`): `Menu` (keuzes en cursor, testbaar), `MenuView` (tekent in een `GameWindow` met het draaiende bolletje uit het lettertype als cursor) en `MenuController` (alle schermen). Escape opent het menu tijdens het spel; het spel pauzeert dan. Keuzes: Return to Game, New Game, Continue Game, Save Game, Story (`STORYTXT.CK1`, scrollen), High Scores, Controls, Options, Quit to Title, Quit. Zie `docs/menus.md`.
- **Opslaan en laden.** `SaveGames`: 9 plekken, alleen op de wereldkaart (zoals het origineel), met een vraag voor overschrijven. `GameProgress` en `Inventory` kunnen zichzelf naar JSON schrijven en teruglezen. Bestanden in de gebruikersmap van Godot (op de Mac `~/Library/Application Support/Godot/app_userdata/CommanderPerfect/`).
- **Toetsen instellen.** `KeyBindings`: per actie de eerste toets vervangen; een toets hoort bij één actie; terugzetten kan. Controllerknoppen blijven zoals ze zijn.
- **Instellingen onthouden.** `UserSettings` bewaart volledig scherm, breedbeeld, 4:3-pixels, geluid aan/uit en de toetsen in `settings.cfg`. F2/F3/F4 slaan ook op.
- **Extra informatie in breedbeeld** (op verzoek van de gebruiker, 14-10-2026): op de kaart en in levels staan in breedbeeld twee kleine babyblauwe balkjes (de grijze achtergrond van de icoontjes is weggehaald) in de bovenhoeken (`Hud`): links Keen met het aantal levens en "Score" met de score, rechts het straalgeweer met de ladingen en de sleutelkaarten die je hebt (als icoontjes). De hulpregel bovenin toont dan alleen nog korte berichten, in het midden.
- De regel met toetsen onderin staat standaard uit (op verzoek van de gebruiker); F1 laat hem zien of verbergt hem.
- Met een menu open is de bovenkant van het scherm leeg (geen hulpregel meer erachter).
- **Volledig scherm** (op verzoek van de gebruiker, 14-10-2026): het spel start standaard in volledig scherm. F4 of Options > Full screen wisselt naar een venster en terug; de keuze wordt onthouden.
- **Game over en highscores.** Na het laatste leven het GAMEOVER-plaatje, daarna (en ook na het einde) de highscores: met een goede score vraagt het spel om een naam ("You got first place!"). `HighScores` (7 plaatsen, naam, score, scheepsonderdelen) wordt bewaard in `high_scores.json`. De standaardnamen en de woorden voor de plaatsen komen uit de eigen `KEEN1.EXE` (`ScoreTexts`).
- `GraphicsTextures`: gedeelde cache van texturen (lettertype, tiles, sprites, bitmaps) voor `GameWindow` en de nieuwe `PictureLayer` (plaatjes en tekst op een map). `GameWindow` kan nu ook bitmaps tonen.
- `tools/scripted_play.gd`: speelt het spel met gescripte toetsen en maakt screenshots (uitleg bovenin het script). Let op: dat schrijft wel naar de echte instellingen, saves en highscores.
- Tests: `test_sounds.gd` (geluidsbestand, synthese, prioriteit, welke gebeurtenissen geluid maken), `test_saving.gd` (voortgang, saves, highscores, toetsen, instellingen), `test_menus.gd` (cursor, hoofdmenu, opslaan, overschrijven, laden, toets wijzigen, opties, naam typen, story), een kaartgeluid-test in `test_world_map.gd`, `LevelData.crop` in `test_level_rendering.gd`, en op de echte data in het nieuwe `test_keen1_extras.gd`: alle geluiden bestaan, de highscoreteksten worden gevonden, de schermen van map 90 en de plaatjes bestaan, en de story past in het venster.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn het titelscherm, het hoofdmenu,
Controls, Continue, Story, game over, een naam invullen, de highscores (ook
in breedbeeld) en opslaan + laden op de wereldkaart via screenshots
gecontroleerd. Het geluid is nog niet met het oor naast het origineel gelegd.

## Mijlpaal 7: wat er nu is

Afspraak met de gebruiker (14-10-2026): het origineel blijft zoals het is.
Alle extra's zijn opties die standaard **uit** staan; alleen breedbeeld (met
de HUD-balkjes) staat standaard aan. Uitleg van alles: `docs/graphics.md`.

- **Instellingen.** Options heeft twee nieuwe regels: *Smooth motion* (aan/uit, of F6) en *Graphics* (ORIGINAL / XBRZ / HD, of F5). HD is pas kiesbaar als de speler HD-graphics heeft gemaakt. Beide worden onthouden in `settings.cfg`. F5 en F6 kunnen niet aan een spelactie worden gegeven.
- **Tekenen.** Bij het originele beeld is alles zoals het was (320x200 of 356x200, hele pixels). Anders tekent de `World`-viewport op een heel veelvoud (2-8x) van de spelresolutie, ongeveer zo groot als het scherm, zodat fijnere graphics en tussenposities te zien zijn. Daarna rekt `even_pixels.gdshader` het beeld uit met alle spelpixels even groot, ook bij vensters die geen heel veelvoud zijn (dat was een bekende beperking).
- **xBRZ** (`src/graphics/xbrz_scaler.gd`): een eigen implementatie van het idee van xBRZ, 6x, per plaatje. Alle graphics worden op de achtergrond over alle kernen gemaakt (`GraphicsLoader`, onder een seconde); het spel loopt intussen door.
- **HD-graphics met Real-ESRGAN.** `tools/make_hd_graphics.sh` zet alle graphics op een paar grote vellen (`HdPack`, `GraphicsSheet`), laat `realesrgan-ncnn-vulkan` ze 4x vergroten (model `realesrgan-x4plus-anime`) en zet het resultaat in `game_data/keen1/hd/` (en naast de Mac-app). De doorzichtigheid van de sprites gaat op een apart masker-vel mee. Op verzoek van de gebruiker is Real-ESRGAN v0.2.5.0 (macOS) gedownload naar `tools/realesrgan/` (genegeerd door git); het script gebruikt die map vanzelf. Draaien duurt ~7 s op de M5; het resultaat werkt in het spel, maar per tile wijkt de kleur van vlakke stukken een klein beetje af, waardoor je op de kaart en rond items zwakke vierkantjes ziet.
- **Alle textures via één plek.** `GraphicsTextures` levert nu ook de tile-atlas (met een rand per tile tegen naden), de deuren, het plaatje van het huis en de sprites voor Keen en de vijanden. Grotere plaatjes krijgen de maat van het origineel (`set_size_override`), zodat de rest van het spel niets hoeft te weten.
- **Vloeiende beweging** (`Interpolation`): Keen, vijanden, schoten, het schip en de tekens worden elk frame tussen de laatste twee ticks getekend; de camera volgt de getekende positie. Een sprong van meer dan 24 pixels (nieuw level, teleporter) wordt niet tussendoor getekend. De snap van Godot werkt in spelpixels en staat daarom alleen aan bij het originele beeld.
- **Windows.** `tools/build_windows.sh` maakt op de Mac `build/windows/CommanderPerfect.exe` (64-bit, alles in één .exe) met de speldata ernaast in `game_data/keen1`. De Windows-templates van Godot 4.7.2 zijn geïnstalleerd (alleen de twee .exe-bestanden uit het officiële pakket).
- Tests: `test_graphics.gd` (xBRZ: vlakken en rechte randen blijven, diagonalen worden glad, doorzichtigheid; kleurafstand; vellen heen en terug; HD-pakket heen en terug met een nep-upscaler; textures houden hun maat; randen van de atlas; interpolatie; wisselen van graphics), plus de nieuwe standaardinstellingen en opties in `test_level_rendering.gd`, `test_menus.gd` en `test_saving.gd`.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn level 1, het titelscherm en het
optiemenu in origineel, xBRZ, (nep-)HD en met vloeiende beweging via
screenshots gecontroleerd. De Windows-build is gemaakt maar nog niet op een
Windows-pc gestart. Vloeiende beweging moet met het oog beoordeeld worden.

## Mijlpaal 8: wat er nu is

Afspraken met de gebruiker (14-10-2026): twee spelers op één toetsenbord
(geen controllers), op elk moment in- en uitstappen, gedeelde voorraad,
doodgaan zoals het origineel (één Keen dood = allebei terug naar de kaart),
op de kaart loopt speler 1 alleen. Alleen spelen blijft precies zoals het
was, ook de toetsen. Uitleg van alles: `docs/two-players.md`.

- **Meedoen.** F7 of "Add Player 2" / "Remove Player 2" in het menu tijdens een spel. In een level verschijnt Keen 2 bij Keen 1; op de kaart doet hij mee vanaf het volgende level. Keen 2 heeft andere kleuren (alle tinten een halve kleurcirkel gedraaid, `player_colors.gdshader`): blauwe helm.
- **Toetsen** (`KeyBindings`): drie sets. Alleen: zoals altijd. Speler 1: WASD, linker Shift springen, Z vuren, ` pogo. Speler 2: pijltjes, . springen, / pogo, rechter Shift vuren. Linker en rechter Shift zijn verschillende toetsen (Godot `location`); een toets wordt bewaard als keycode + kant. Controls heeft nu drie pagina's. Op de kaart sturen alle toetsen samen speler 1 (`KeenInput.combine`). Geen Ctrl voor twee spelers: Ctrl+pijltje wisselt op de Mac van bureaublad.
- **Level-logica** (`LevelSession`): `keens` (speler 1 is nog steeds `keen`), `add_player`, `remove_player`, `step_players`. Items, deuren, schieten, beelden en de uitgang werken voor beide Keens. Vijanden gaan op de dichtstbijzijnde levende Keen af en raken beide; ze worden wakker in het beeld van elk van beide spelers (`view_rects`). De uitgang gaat niet open terwijl de andere Keen doodgaat; wie de uitgang in loopt, maakt het level voor allebei af.
- **Split-screen** (`SplitScreen` rekent, `TwoPlayerView` tekent): samen één beeld; als een speler verder komt dan halverwege het midden en de rand, glijden de camera's uit elkaar en splitst het scherm met een donkere lijn door het midden, loodrecht op de lijn tussen de spelers (draait mee). Bij de rand van een level blijft het langer één scherm, en het komt pas weer samen 8 pixels verder (geen flikkeren). Een tweede viewport (`World2`) deelt het level met `World`; `split_screen.gdshader` legt zijn beeld over de helft van speler 2, onder de HUD. Er is geen pijltje naar de andere speler: na de speeltest wilde de gebruiker het weg (je ziet aan de split welke kant je op moet). Voor online multiplayer is het wel nodig; dat staat beschreven in `docs/two-players.md` onder "Later: online".
- `LevelView` werd te lang: het twee-spelersdeel staat in `TwoPlayerView`, de hulpregel in `StatusLine`, het instellen van een viewport in `DisplaySettings.set_up_viewport`.
- `tools/scripted_play.gd` kent nu `LeftShift` / `RightShift`.
- Tests: `test_two_players.gd` (twee Keens: meedoen, eigen besturing, gedeelde items en munitie, doodgaan, uitgang, vijanden, wakker worden, vertrekken, god mode; de standaardtoetsen, linker/rechter Shift, overlappende sets, opslaan met kant, gecombineerde invoer op de kaart), `test_split_screen.gd` (één scherm, splitsen, geen sprong, binnen het level, bij de rand, smal level, dode speler, dode zone), plus menutests (speler 2 toevoegen, toets van speler 2 wijzigen).

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer is in level 1 gecontroleerd dat speler 2
erbij komt, apart bestuurd wordt (pijltjes en .), andere kleuren heeft, en
dat het scherm splitst met de lijn. De gebruiker heeft het gespeeld en vindt
het er goed uitzien (14-10-2026); alleen de pijltjes naar de andere speler
moesten weg.

## Mijlpaal 9: wat er nu is

Afspraken met de gebruiker (15-10-2026), zoals in Together Around: hosten
via Steam (alleen vrienden, App ID 480) of via IP met dezelfde poort (UDP
24800). Online twee Keens (host + 1), F7 doet dan niets. Optioneel
wachtwoord (via IP standaard aan, via Steam uit), basiscontrole op alle
berichten, geen kick-knop of security-log. Hosten kan vanuit het
hoofdmenu (nieuw spel) en vanuit het Escape-menu (huidig spel loopt door).
Naam: de Steam-naam, of via IP één keer intypen. Bij joinen een nieuwe
ping (eigen PC-speakergeluid) en "*Naam* joined" rechtsonder. Wie joint
staat altijd naast de Keen van de host. Op de kaart loopt alleen de host;
drukt de ander een pijltje of knop, dan "Only the host can walk on the
world map". Online pauzeert niets (zolang er echt samen gespeeld wordt; hosten zonder
dat iemand gejoind is gedraagt zich als alleen spelen). Pijltje naar de ander als hij uit beeld
is (alleen online). De host controleert een checksum van de levels en
weigert een andere versie. Uitleg van alles: `docs/online.md`.

- **Menu** (`MenuController`, `OnlineMenuInfo`): "Online Game" in het
  hoofdmenu met Host via Steam, Host via IP, Join via Steam (lijst van
  spellen van vrienden, `*` = wachtwoord), Join via IP (adres wordt
  onthouden) en Your Name. Tijdens hosten: de adressen (LAN, internet via
  api.ipify.org, poort, wachtwoord), wie meespeelt, en Stop Hosting. Wie
  joint heeft een eigen hoofdmenu: Return to Game, Leave Game, Story,
  Controls, Options, Quit. Tekstinvoer voor naam, adres en wachtwoord.
- **Netwerk** (`src/online/`): `OnlineSession` (eigen `SceneMultiplayer`,
  zelf gepold, dus testbaar zonder scèneboom), `EnetTransport` en
  `SteamTransport`, de handshake (`JoinHandshake`, `JoinGate`,
  `JoinTicket`: nonce + SHA-256, het wachtwoord gaat nooit over de lijn,
  5 keer fout = 1 minuut buiten), `LevelFingerprint`, `SteamService` en
  `SteamLobby` (overgenomen van Together Around, aangepast), `HostAddresses`.
- **Synchronisatie**: de host rekent alles. Elke tick een `Snapshot`
  (Keens, actors met een vast id, zinkende deuren, voorraad, geluiden),
  onbetrouwbaar verstuurd; scènes (kaart, level, game over, einde, wachten)
  met alle tiles die afwijken van het levelbestand; tile-wijzigingen en
  vensters (beeldje, Keens Left, scheepsonderdelen, "Level n completed!")
  als events. Wie joint stuurt alleen zijn knoppen als ze veranderen
  (`OnlineInput`, één wijziging per tick, dus een tikje blijft een tik) en
  af en toe wat hij ziet (vijanden worden daar wakker). `SnapshotBuffer`
  houdt 2 plaatjes reserve.
- **Spelscherm**: `LevelView` werd te lang (gdlint max 1000 regels); wat er
  op het scherm staat en hoe het getekend wordt (beeld, graphics, F1-F6,
  statusregel, HUD, vensters) staat nu in de basisklasse `GameScreen`
  (letterlijk verplaatst, niets aan veranderd). Online: `OnlinePlay`
  (netwerk, menukeuzes, meldingen, ping), `RemoteGame` (wat wie joint ziet,
  in de nieuwe mode `REMOTE`, en het pijltje), `OnlineNotice`,
  `PartnerArrow`, `OnlineSpawn` (naast de host, eerst ervoor),
  `PingSound`. `TwoPlayerView` kan nu ook zonder split-screen (online) en
  tekent de eigen Keen van wie joint.
- **Steam-plug-in**: GodotSteam GDExtension 4.23.1 in `addons/godotsteam/`,
  meegecommit met alleen de macOS- en Windows-bibliotheken (zoals in
  Together Around). Op Linux zegt Godot dat hij hem niet kan laden; dat is
  verwacht.
- `tools/scripted_play.gd` kan nu tekst typen (`type_127.0.0.1`).
- Tests: `test_online_session.gd` (handshake: wachtwoord, buitensluiten,
  andere versie/levels, vol, rommel; een echte host en joiner via ENet op
  deze machine, verkeerd wachtwoord, geen antwoord), `test_online_sync.gd`
  (snapshot heen en terug, kapotte berichten, kopieën van actors, knoppen,
  tikje, flood, buffer, berichten, gewijzigde tiles, plek naast de host,
  pijltje, Steam-lobbydata, adressen, ping), `test_online_menus.gd`
  (hoofdmenu's, hosten via IP/Steam, joinen via IP/Steam, hostinfo), plus
  naam en adres in `test_saving.gd` en de checksum op de echte data.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met twee instanties op deze machine (elk een eigen
gebruikersmap) is via het menu gehost en gejoind via IP: de Keen van wie
joint staat naast de host, beweegt bij de host mee, "GUEST joined" en
"Joined HOST's game" verschijnen, Shift+N (ander level) en New Game (de
kaart met Keens Left) komen bij wie joint aan, de kaartmelding verschijnt,
de pijltjes wijzen naar de ander, en als de host stopt gaat wie joint terug
naar zijn titel met "The host has left the game". Steam kon hier niet
getest worden (geen Steam in de cloud) en is ook in Together Around nog
niet met twee echte accounts geprobeerd. De ping is niet beluisterd.

## Mijlpaal 10: wat er nu is

Afspraken met de gebruiker (15-10-2026): het spel begint altijd op een
startscherm met het aangeleverde CommanderPerfect-plaatje, heel en zo groot
als past, met daaronder een donkergrijze balk die altijd ruimte heeft
(minstens 10% van de hoogte; op 16:9 wordt het plaatje iets kleiner met
grijs ernaast). Linksonder een icoon per spel (Keen 1 helemaal links, op
verzoek van de gebruiker), nu alleen "Keen 1" (niet
"Commander Keen", zie CLAUDE.md), met Keen uit de eigen speldata. Hover
of kiezen met pijltjes/controller maakt het icoon iets donkerder; klik,
Enter of A opent het bestaande hoofdmenu. Zonder speldata een grijs icoon
met uitleg. "Quit to Title" blijft naar de Keen 1-titel gaan; nieuw in het
hoofdmenu is "Choose Game" (terug naar het startscherm). Met `--level=N` of
`--ending` wordt het startscherm overgeslagen.

- `src/launcher/`: `Launcher` (de scène, nu de hoofdscène in
  `project.godot`), `LauncherLayout` (waar plaatje, balk en iconen komen),
  `GameIcon` (het icoon, getekend in icoonpixels en met een heel getal
  vergroot), `GameCatalog` (de spellen; hier komen latere delen bij) en
  `GameLaunch` (geeft door dat het hoofdmenu meteen open moet, en welke
  opstartopties het startscherm overslaan).
- Het plaatje staat in `assets/launcher/background.png` (eigen plaatje van
  de gebruiker, mag in de repo).
- Escape op het startscherm: "Press Escape again to quit"; nog een keer
  Escape sluit het programma. Volledig scherm volgt de instelling van het
  spel.
- `tools/scripted_play.gd`: `SCENE=` voor een andere scène (zoals het
  startscherm), `mouse_X_Y` en `click_X_Y`, en de scène wordt nu echt de
  huidige scène (anders bleef bij wisselen de oude staan).
- Tests: `test_launcher.gd` (indeling op 16:10 en 16:9, iconen linksonder,
  donkerder onder de muis, grijs zonder bestanden, de uitleg, alleen
  "Keen 1", het hoofdmenu één keer openen, opstartopties, "Choose Game").

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn het startscherm (1280x800 en
1600x900), hover en het pijltje, klik en Enter naar het hoofdmenu, "Choose
Game" terug naar het startscherm en de Escape-melding via screenshots
gecontroleerd.

## Mijlpaal 11: wat er nu is

Gemeld door de gebruiker (16-10-2026) na het mergen van mijlpaal 10.

- **Crash bij "Choose Game"** (macOS en Windows) opgelost. De scène wisselde
  terwijl `LevelView` de toets nog afhandelde; Godot haalt de oude scène dan
  meteen uit de boom, en de rest van de afhandeling liep op een node zonder
  viewport (hier een scriptfout, in de builds een crash). Beide wissels die
  vanuit invoer gebeuren (naar en van het startscherm) gaan nu met
  `call_deferred`. Nagespeeld met gescripte invoer: "Choose Game" vanuit een
  lopend spel en vanuit het titelmenu, en daarna weer Keen 1.
- **Nieuw app-icoon** (Dock en taakbalk). Eerst een pixel-Keen met "CP" op
  grijs; de gebruiker vond Keen lelijk, dus nu alleen de letters "CP" (dik,
  geel met rode diepte en zwarte rand, zoals het logo op het startplaatje)
  voor een kleurrijke sterrenhemel met planeet, paarse bergen en grijze
  grond, pixel-art op 64x64. Niets uit de originele bestanden.
  `tools/make_app_icon.py` (Python + Pillow) tekent het en schrijft `assets/icon/app_icon.png` (macOS-build),
  `assets/icon/app_icon.ico` (Windows-build) en `icon.svg` (venster en
  editor). In `export_presets.cfg` staan de iconen nu ingesteld; voor
  Windows staat `modify_resources` daarvoor aan (Godot zet het icoon dan zelf
  in de .exe).

- **Achtergronden achter levels** (op verzoek van de gebruiker, met zijn
  eigen plaatje voor level 1): in widescreen toont een level met een eigen
  plaatje dat achter zich in plaats van de egale achtergrond. Optie
  *Backgrounds* in Options; **standaard aan** (keuze van de gebruiker, een
  uitzondering op "extra's standaard uit", ook in CLAUDE.md gezet), in 4:3
  altijd uit (niet te kiezen). Zonder plaatje: het origineel.
  - Plaatjes: `assets/backgrounds/levelNN.png/.webp/.jpg` (nu
    `level01.webp`, 1536x1024). Om te proberen zonder te bouwen: een
    plaatje met dezelfde naam in `backgrounds/` naast de speldata (bijv.
    `game_data/keen1/backgrounds/level01.png`) gaat voor.
  - De egale achtergrond-tile van een level wordt gevonden (meest gebruikt,
    één kleur, nergens op te staan; level 1: tile 143, lichtgrijs). Die
    kleur wordt uit alle tiles weggelaten waar hij de rand raakt, zodat het
    grijs rond snoep, pilaren en platforms weg is en grijs binnen in dingen
    blijft (`GraphicsTextures.backdrop_tile_atlas`; voor xBRZ/HD worden de
    gaten mee vergroot).
  - Het plaatje bedekt het beeld (15% ruimer), bovenkant aan de bovenkant
    (lucht en horizon altijd in beeld), en schuift van links naar rechts
    mee met hoe ver je in het level bent (`LevelBackdrop`, ook in de tweede
    helft van het split-screen).
  - Het plaatje is 3:2; daardoor schuift het weinig (een breder plaatje,
    zoals 3840x1080, geeft meer diepte) en de zijkanten sluiten niet
    naadloos aan (maakt niet uit: het herhaalt niet).
- Tests: `test_backdrops.gd` (achtergrond-tile, gaten alleen rond dingen,
  plaats van het plaatje links/rechts/smal level, standaard aan en alleen
  in widescreen, onthouden, menu-optie, eigen map gaat voor, level 1 heeft
  een plaatje).
- **Builds pakten te veel in.** `.gitignore` geldt niet voor Godot: de
  export ("all_resources") nam ook de plaatjes uit `exported/` en `build/`
  mee in het pakket (afgeleid van de originele bestanden). Beide presets
  sluiten nu `build/*, exported/*, game_data/*` uit; het spel laadt daar
  niets uit via `res://` (de speldata wordt naast de app gelezen). App
  184 → 172 MB, .exe 119 → 106 MB.

Getest: alle tests slagen, gdlint is schoon; met gescripte invoer is level 1
met de achtergrond bekeken (lopen, origineel, xBRZ, 4:3 = origineel, optie
uit = origineel). Op de Mac (16-10-2026) beide builds gemaakt: geen
meldingen over het icoon, `icon.icns` in de app is het "CP"-icoon, en de
gebouwde app start level 1 met de achtergrond. De gebruiker heeft
"Choose Game" in de gebouwde app geprobeerd: geen crash meer.

## Mijlpaal 11.2: wat er nu is

Op verzoek van de gebruiker (16-10-2026). Alles valt onder de nieuwe optie
**Extra levels** in Options, standaard aan (keuze van de gebruiker); uit =
het origineel. Details in `docs/world-map.md` onder "Extra levels".

- **Het schip als level** (nummers 100 buiten, 101 binnen; `ShipLevels`,
  `ShipVisit`, `ShipRepair`, `ShipSmoke`, `ShipInterior`, `ShipPicture`).
  Op de kaart start het schip het level, ook als Keen ernaast staat (idee
  van de gebruiker). Buiten: het schip van het titelscherm met rook op
  Mars; links/rechts uit beeld = terug naar de kaart; achter in het schip
  loopt Keen naar binnen met de animatie van de einddeuren (onzichtbare
  ingang, op verzoek van de gebruiker; eerst stond er een zichtbare deur).
  Binnen: een kleine getekende cabine (ramen, buizen, kabels, tank,
  cockpit met radar en knipperlampjes); vier plekken met grijze
  silhouetten; met het onderdeel loop je ertegenaan en het gaat erin, zonder
  verschijnt een bordje "... still missing". Door het luik links weer
  naar buiten. Na het vierde onderdeel begint het einde (keuze van de
  gebruiker: niet meer vanzelf bij vier onderdelen). Ingebouwde onderdelen
  staan in het opgeslagen spel (`installed_parts`, oude saves werken).
- Opgelost na de eerste test van de gebruiker: in de cabine liep Keen
  zonder animatie, kon hij niet springen en "gleed" hij (de eigen vaste
  cellen telden niet als vloer, dus Keen viel steeds; vermoedelijk ook het
  harde gekraak: elke tick een landingsgeluid). De meldingen staan nu als
  één bordje bovenaan in het midden (`ScreenNote`); een nieuwe vervangt de
  oude.
- De melding "Level N completed!" is weg (hoorde niet bij het origineel,
  besluit van de gebruiker); na een level is er alleen het "done"-bord.
- **Level 5 (pogo) opnieuw** zolang Keen de pogo niet heeft; punten tellen
  dan niet, munitie wel (keuze van de gebruiker).
- **Onderdelen in de HUD** rechtsboven, op de kaart en in het schip.
- `level_view.gd` liep over de 1000 regels: het volgen van de camera staat
  nu in `GameScreen`.
- Tests: `test_ship.gd` (zonder speldata) en `test_keen1_ship.gd` (speelt de
  echte scheepslevels).

## Bekende beperkingen

- De natuurkunde-getallen zijn startwaarden (overgenomen van Commander Genius als documentatie, zie `docs/keen-physics.md`). Ze moeten nog naast het origineel (DOSBox) worden gelegd; de lijst met punten staat onderaan dat document.
- Veel getallen voor vijanden zijn schattingen (gemarkeerd met *estimate* in de code); de lijst met wat nog naast het origineel moet staat onderaan `docs/enemies.md`. Vooral: levenspunten van Vorticons (4) en de commandant (105).
- Gedrag 23 (lichtschakelaar) wordt door geen enkel level van Keen 1 gebruikt en doet niets.
- Veel getallen op de kaart en in het einde zijn overgenomen van Commander Genius of geschat: loopsnelheid op de kaart, de teleporter, de vluchten van het schip (de vlucht naar de aarde duurt nu ~28 s). De lijst staat onderaan `docs/world-map.md`.
- De doelen van de teleporters staan in de code van `KEEN1.EXE`, niet in een tabel; ze zijn als vaste waarden in `MapSession` gezet (volgens de documentatie van Commander Genius wijst elk doel precies naar een andere teleporter). Mods met andere doelen werken dus niet.
- In de EXE zijn de vraag van de ouders en Keens antwoord ("Aw, Mom...") één bericht; het origineel toont ze misschien als twee vensters.
- In 4:3-beeld staat de hulpregel linksboven (levelnaam, beeldinstelling, score, levens, munitie) alleen nog onder F1 (besluit van de gebruiker, 16-10-2026); zonder F1 alleen korte meldingen in het midden. De regel bovenin en de toetsenregel onderin zijn hulpmiddelen; het origineel heeft alleen het statusscherm. De toetsenregel noemt de standaardtoetsen, ook als ze zijn veranderd.
- De snelheid van de geluiden is sinds C8 145,65 Hz (1.193.182 / 8192, Chocolate Keen; besluit van de gebruiker, voor alle drie de delen) en is nog niet met het oor vergeleken. Een paar koppelingen van geluid aan gebeurtenis zijn gokken (zie `docs/sounds.md`); `CLICKSND`, `CRYSTALSND` en `GOINDOORSND` worden niet gebruikt.
- Niet nagebouwd: de intro (Apogee- en id-schermen), de demo, "About ID...", "Ordering Info" en "Previews!". De helptekst (`HELPTEXT.CK1`) wordt niet getoond, omdat die de toetsen van het origineel beschrijft.
- De scores in een nieuwe highscorelijst (100) en de plek van de tabel in de rode lijst zijn geschat.
- Level overslaan (cheat of Page Up/Down) houdt de inventaris, en een level dat zo gekozen is telt wel mee als het wordt uitgespeeld.
- De data viewer toont tiles nog zonder animatie en zonder voorgrond-markering.
- Gemaskeerde tiles (gedrag -2) zonder zwart-wit masker als volgende tile (Keen 2: 371-373) worden als gewone voorgrond-tiles getekend, zoals Commander Genius ze als tile-fout ziet; of het origineel ze anders tekent, is niet nagekeken.
- In de data viewer wordt de info-laag nog alleen gemarkeerd, zonder namen van de vijanden.
- Zodra het beeld niet het originele is (xBRZ, HD of vloeiende beweging), scrolt de camera ook in delen van een spelpixel, ook als vloeiende beweging uit staat. Sprites staan dan wel op hele spelpixels.
- Real-ESRGAN is gemaakt voor foto's en tekeningen, niet voor pixelart; of `realesrgan-x4plus-anime` mooi is, moet blijken. Een ander model kiezen kan met `MODEL=`.
- Op schermen hoger dan 1200 pixels (Retina) wordt xBRZ (6x) nog een beetje glad vergroot.
- Vloeiende beweging toont alles één tick (17 ms) later.
- Of de wereldkaart ook precies een rand van 2 tiles verbergt, is aangenomen maar niet vergeleken met het origineel.
- Twee spelers: de controller bestuurt alleen speler 1; twee controllers worden nog niet uit elkaar gehouden. Of speler 2 meespeelt, wordt niet in een opgeslagen spel bewaard. De toetsenregel (F1) noemt alleen de toetsen voor één speler.
- Met 4:3-pixels is de scheidslijn liggend iets dikker dan staand (hij wordt in spelpixels getekend).
- Online: geen voorspelling, de eigen Keen van wie joint reageert één rondreis later (thuisnetwerk of Steam in Nederland meestal 20-40 ms). Maximaal twee spelers; niet lokaal en online tegelijk. Wie joint ziet het einde in zijn eigen tempo, en op de kaart tijdens het einde ontbreken bij hem de DONE-borden. Of er online gespeeld wordt, gaat niet mee in een opgeslagen spel.

## Open beslissingen

- **Licentie** voor de code (bijv. MIT of GPL-3.0): nog kiezen voordat de repo publiek wordt.
- **HD met nieuwe details (generatieve AI)**, besproken op 14-10-2026, voor nu geparkeerd door de gebruiker. Oordeel van de gebruiker: de Real-ESRGAN-HD is "best lelijk", xBRZ ziet er mooier uit, maar hij mist nieuwe details. Real-ESRGAN kan geen details verzinnen; daarvoor is een generatief model nodig. Het plan staat in `docs/graphics.md` onder "Plan: HD with new details". Eerste stap als de gebruiker verder wil: toestemming vragen om Stable Diffusion 1.5 + ControlNet Tile te downloaden (~6 GB, Hugging Face, naar een map die git negeert) en een proef doen met ~10 plaatjes naast xBRZ.

- **Keen 2: besluiten van de gebruiker (16-10-2026, B1).** Gedeelde code mag alleen toevoegingen krijgen met Keen 1 als standaard; Keen 1-code blijft onaangeroerd. Chocolate Keen mag als bron voor datatabellen (adressen, namen, groottes), nooit voor code met gedrag. De architect (deze sessie) stuurt een developer-subagent aan en controleert zijn werk.
- **Keen 3: besluiten van de gebruiker (17-10-2026, C1).** Keen 1- en Keen 2-code blijven onaangeroerd; Keen 3 mag hun klassen gebruiken en er subklassen van maken. Branches `milestone-c<n>-<onderwerp>`. Uit Chocolate Keen mogen nu ook de feiten en getallen uit de gedragscode komen (gemarkeerd `(Choco)`), nooit de code zelf (`CLAUDE.md`). Versie 1.00 is goed genoeg; geen nieuwere versie nodig.
- **Keen 3: besluiten van de architect (C1), te melden aan de gebruiker.** De lijst-van-spellen-asserties in `tests/test_launcher.gd` en `tests/test_keen2_files.gd` gaan van twee naar drie (zoals in B2); `GameLaunch.skips_launcher`/`scene_for`, de data viewer en `export_graphics.gd` kiezen uit drie spellen, met hetzelfde antwoord voor alles wat vroeger werkte. De bugs van versie 1.00 (level 10, level 13) blijven zoals ze zijn.
- **Keen 3: antwoorden van de gebruiker op de vragen van C1 (17-10-2026).** (1) Real-ESRGAN voor Keen 3: overslaan, zoals bij Keen 2. (2) Geluidssnelheid: alle drie de delen naar 145,65 Hz (de gedeelde `SpeakerSynth`; verandert Keen 1 en 2 een klein beetje, goedgekeurd); gebeurt in C8. (3) Keen 1 en 2 bijwerken met de getallen uit Chocolate Keen: later, na Keen 3, in een eigen mijlpaal (C12), samen met de te hoge sprongen voor alle drie. (4) De randflits bij een geraakte vonk of het hart in level 16: als korte flits van de rand rond het 4:3-beeld (C7).
- **Sprongen te hoog in Keen 1 en 2 (en dus ook Keen 3)** (gemeten door de gebruiker in een ander venster, 17-10-2026; nog niets aangepast). In het originele Keen 2 is de gewone sprong ~54-55 px (wij 58), de pogo zonder springknop 50 px (wij 58, een halve tile te hoog) en met springknop ~104 px (wij 109); de tijd van een stuit klopt. Chocolate Keen geeft dezelfde hoogtes (48 en 104 px, sprong 55,7 px), dus de oorzaak zit in onze natuurkunde-getallen (overgenomen van Commander Genius). Details: [docs/keen3/choco-keen1-keen2.md](docs/keen3/choco-keen1-keen2.md). Keuzes: (a) de gedeelde `src/keen/keen_physics.gd` aanpassen naar de getallen van Chocolate Keen, voor alle drie de delen (verandert Keen 1 en 2, mag alleen met toestemming); (b) eerst nog nauwkeuriger meten (de eerste hoge stuit, Keen 1 op een vrije plek); (c) alleen voor Keen 3 lager (`Keen3Body`), Keen 1 en 2 laten zoals ze zijn. **Beslissen vóór C3**, want daar gaat Keen 3 springen. *Besluit van de gebruiker (C3): de sprongen blijven voorlopig zoals ze zijn, later beslissen voor alle delen samen; Keen 3 gebruikt de gedeelde natuurkunde ongewijzigd.*
- **Keen 2: de knop op het startscherm** (besluit van de gebruiker, 16-10-2026): lettertype en Keen-mannetje komen altijd uit de Keen 2-data. Zonder die bestanden blijft de knop grijs met een gewoon lettertype (geen Keen 1-data als vervanging).
- **Keen 2: speldata.** De gebruiker heeft Keen 2 op floppies maar geen floppylezer. Keen 2 is geen shareware en wordt nog verkocht, dus het wordt niet gedownload van onofficiële sites. Opties: de Complete Pack op Steam/GOG, of een USB-floppylezer. Tot dan: bouwen en testen met zelfgemaakte testdata; de suites met echte data slaan zich over, en de vragen die alleen de echte bestanden beantwoorden blijven open (research.md).
- **Keen 2: sprong van de youth** (B4, architect): met de getallen uit Commander Genius (200/32 omhoog, zwaartekracht 4/32) springt hij ruim 10 tiles hoog. Dat lijkt te veel; vermoedelijk heeft de youth in het origineel een eigen zwaartekracht. Naast het origineel leggen in B10.
- **Geluidssnelheid (ook Keen 1):** Commander Genius speelt de geluiden met 145,6 Hz, `docs/sounds.md` zei 140 Hz. *Besluit van de gebruiker (17-10-2026): alle drie de delen 145,65 Hz; gedaan in C8.* Nog naast het origineel leggen (met het oor).

### Toegevoegd op 15-10-2026 (op `milestone-10-menu`)

Na de eerste eigen test van de gebruiker:

- **Adressen zichtbaar.** Het scherm *Host via IP* toont nu meteen het adres op het eigen netwerk en het internetadres (wordt opgezocht zodra het scherm opent: eerst "looking up...", daarna het adres of "not found"). Het venster *Hosting* vult het internetadres in zodra het binnen is; eerder bleef daar "?" staan omdat het venster niet ververste.
- **Eigen wachtwoord.** In de host-setup: *Type Password* (zelf intypen, tot 20 tekens, hoofdletters tellen) en *Random Password*. Een getypt wachtwoord wordt onthouden in `settings.cfg` en de volgende keer weer gebruikt; *Random Password* maakt een nieuw willekeurig wachtwoord en vergeet het getypte.
- Tests in `test_online_menus.gd`: adressen in de setup, het hosting-venster ververst, `address_lines`, eigen wachtwoord typen en onthouden.

## Volgende stap

Keen 3:

1. **Voor de gebruiker (C6):** Keen 3 proberen in `build/` (Mac en Windows): de
   wereldkaart (lopen, levels in en uit, de bordjes, de muren die opengaan),
   de teleporters, het schip, Messie (opstappen door tegen haar aan te
   lopen, afstappen met een pijltje naar het eiland van level 16 of naar
   de Hidden City), het statusscherm (Enter) op de kaart en in een level.
2. **Voor de gebruiker:** Keen 3 van begin tot eind spelen in `build/`
   (Mac en Windows): level 16 met Mortimer (Spatie slaat over), de
   machine (vonken, armen, benen, het hart), de randflits, het einde; of
   direct met `-- --game=3 --level=16` en `-- --game=3 --ending`.
3. **Architect:** C9 controleren (branch `milestone-c9-extras`), de app
   bouwen op de Mac met `tools/build_macos.sh` en `tools/build_windows.sh`
   (kon hier niet: macOS alleen op de Mac, geen export templates).
4. **Voor de gebruiker (C8):** in `build/` proberen: de titel en de
   highscores (wisselen elke 16,5 s, een toets opent het menu), het menu
   (Story, High Scores, Controls, Options, Choose Game), een nieuw spel,
   opslaan op de kaart (Escape, Save Game) en weer laden (Continue Game),
   GAME OVER en de highscores met je naam (ook na het einde), en de
   geluiden met het oor: alle drie de delen spelen nu op 145,65 Hz
   (luister ook even naar Keen 1 en 2), een pogo-stuit klinkt als een
   sprong, van een rand lopen, tegen een muur springen, de eindtekst
   (eerst keensleft, dan MORTIMER).
5. **Voor de gebruiker (C9):** in `build/` proberen: F5 (xBRZ) en F6
   (vloeiende beweging) in een level, op de kaart (Messie, een
   teleporter), in level 16 (de machine) en in het einde; en eventueel
   een eigen plaatje achter een level met lucht (1-8, 11, 13, 14, 15):
   `game_data/keen3/backgrounds/level01.png` (breedbeeld, optie
   Backgrounds aan).
6. **Architect:** C10 controleren (branch `milestone-c10-coop`), de app
   bouwen op de Mac met `tools/build_macos.sh` en `tools/build_windows.sh`.
7. **Voor de gebruiker (C10):** in `build/` proberen: F7 in een level
   (split screen, de ankh per speler in de HUD en op het statusscherm),
   op de kaart met twee spelers (Messie, een teleporter), level 16 met
   twee spelers; online met een vriend (via Steam, of IP op twee
   computers): Keen 3 hosten en meedoen, en meedoen met een Keen 3-host
   vanuit Keen 1 of 2 (het spel schakelt over).
8. **Architect:** C11 controleren (branch `milestone-c11-origineel`), de
   app bouwen op de Mac met `tools/build_macos.sh` en `tools/build_windows.sh`.
9. **Voor de gebruiker (C11):** in `build/` het einde van Keen 3 bekijken
   (`-- --game=3 --ending`, of level 16 uitspelen): de vakken staan nu
   onderaan zoals in het origineel, het balletje onder "The End... For
   now!", de eindtekst met de grijze titelbalk en de regel "ESC to Exit";
   en de highscores van een nieuwe lijst (zeven namen; eerst
   `keen3/high_scores.json` in de gebruikersmap weggooien).
10. Daarna C12 (Keen 1 en 2 bijwerken, branch `milestone-c12-keen1-keen2`):
   de natuurkunde voor alle drie (Keen 3 gemeten: 53/50/105 px), en wat in
   C11 aan Keen 3 is gezien om in Keen 1 en 2 na te kijken
   (`docs/keen3/choco-keen1-keen2.md`). Eventueel ook het GAME OVER-venster
   met naaminvoer (alle drie).
11. Later: Eigen achtergrondplaatjes voor Keen 1 en Keen 2, later in een
   eigen branch (wens van de gebruiker, 19-10-2026).

Keen 2:

1. **Voor de gebruiker:** B7, B8 en B9 proberen in `build/` (Mac en
   Windows): menu's, opslaan, high scores, F7 voor twee spelers, online
   met een vriend (via Steam, of IP op twee computers).
2. B10 proberen: titel, highscores, statusscherm (3 ladingen), GAME OVER.
3. B10 afmaken (optioneel): de punten die nog `# estimate` zijn (lijst in
   `docs/keen2/gameplay.md`) kan de gebruiker zelf in het origineel
   bekijken; zeg wat afwijkt en het wordt aangepast.
4. `milestone-b10-origineel` bevat alle eerdere B-branches en kan in één
   keer naar `main`.

Keen 1:

1. **Voor de gebruiker:** de scheepslevels proberen in
   `build/CommanderPerfect.app` (nieuwe binnenkant, onzichtbare ingang,
   bordjes bij de plekken) en zeggen wat er beter kan; daarna committen en
   pushen naar `milestone-11.2-extra-mini-game`.
2. Mijlpaal 9 (online): probeer via IP op het thuisnetwerk en via Steam met
   een vriend.
3. Eventueel een breder plaatje voor level 1 en plaatjes voor andere
   levels (in `assets/backgrounds/`), en de openstaande
   punten (natuurkunde en vijanden naast DOSBox leggen, de intro, de
   hulpregel in 4:3, xBRZ/vloeiende beweging bekijken).
