# Roadmap Keen 5

De mijlpalen voor het vijfde deel ("The Armageddon Machine"). Hoe Keen 5
naast Keen 1-4 komt te staan, staat in [architecture.md](architecture.md).
Wat er over het spel bekend is, staat in [research.md](research.md), de
bestanden in [file-formats.md](file-formats.md).

## Waarom deze roadmap korter is dan die van Keen 4

Keen 4 bouwde de Galaxy-engine helemaal opnieuw (~21 uur). Keen 5 is
**dezelfde engine**: de lezers van de bestanden werken al op Keen 5 (E1:
alle headers, plaatjes, sprites, maps en geluiden gevonden, met twee kleine
aanvullingen), en de klok, het actiesysteem, de botsingen met hellingen,
Keens bewegingen (precies dezelfde getallen), de camera, het tekenen, de
OPL2-synthesizer, de menu's, Paddle War, split-screen en online liggen klaar
in `src/galaxy/`.

Wat Keen 5 nieuw nodig heeft:

1. **Het spel rond de engine** (schermen, level- en kaartsessie, opslaan,
   statusvenster, titel, einde): dat zit nu in `src/keen4/`. Het advies
   (architecture.md, "weg 3") is om dat één keer **algemeen** te maken in
   `src/galaxy/game/`, door de Keen 4-klassen te kopiëren en de Keen
   4-getallen en -inhoud eruit te halen. Keen 4 zelf blijft onaangeroerd;
   Keen 5 en later Keen 6 gebruiken de algemene versie.
2. **De inhoud van Keen 5**: 14 soorten wezens, de sleutelkaart en
   beveiligingsdeuren, zekeringen en de Quantum Explosion Dynamo, platforms
   die pijlen volgen, de kaart met teleporters en liften, Korath III, het
   geheime einde en de exploderende melkweg bij game over.

Reken op **ongeveer 10-12 uur** (de helft van Keen 4).

## Afspraken

- Elke mijlpaal heeft een branch `milestone-e<n>-<onderwerp>`, vanaf
  `main` (wens van de gebruiker: de letter e voor Keen 5).
- **E1 (dit onderzoek)** verandert geen code: alleen nieuwe documenten in
  `docs/keen5/` en de voortgang (`PROGRESS.md`, `docs/doorlooptijden.md`,
  `docs/new-episode-guide.md`).
- **Keen 1-4 blijven zoals ze zijn.** Elke mijlpaal eindigt met de controle
  uit [architecture.md](architecture.md): alle bestaande tests slagen
  zonder dat ze zijn aangepast (op de uitzonderingen na), `gdlint` is
  schoon, de regressie-screenshots van Keen 1, 2 en 4 zijn gelijk, en de
  bestanden van Keen 1-4 zijn niet veranderd. In `src/galaxy/` alleen
  toevoegingen die niets aan Keen 4 veranderen.
- **Vragen aan de gebruiker gaan altijd als keuzemenu** (AskUserQuestion,
  2-4 opties, het advies eerst met "(Recommended)").
- De architect schrijft per mijlpaal de opdracht (hieronder). De developer
  bouwt die, met tests, en werkt `PROGRESS.md` bij. De architect controleert
  daarna de diff tegen de opdracht en de regels, en vult
  `docs/doorlooptijden.md` aan.
- Getallen komen uit Omnispeak (`(Omni)`, als bij Keen 4; besluit van de
  gebruiker, 22-10-2026), anders uit Commander Genius (`# estimate`). Nooit code
  overnemen.
- De gebruiker heeft Keen 5 **versie 1.4**, dezelfde versie als Omnispeak
  beschrijft. Alles wordt op **inhoud** gezocht, zodat een 1.0 ook kan
  werken.
- **Naast het origineel tijdens het werk:** elke mijlpaal met iets
  zichtbaars eindigt met een korte vergelijking in js-dos met de eigen
  Keen 5 v1.4 van de gebruiker (`tools/original/`, start `KEEN5E`).
- Keen 5 is geen shareware: zonder de bestanden van de gebruiker slaan de
  tests met echte data over. In een cloud-sessie moet de gebruiker ze
  uploaden, samen met Keen 2-4 voor de controle (besluit van de
  gebruiker, 22-10-2026; Keen 1 haalt `tools/get_shareware.sh`).
- Extra's zijn standaard uit, met dezelfde uitzonderingen als bij Keen 1-4
  (widescreen met het scorebord, plaatjes achter de levels in
  widescreen).
- **Origineel spelen** (wens van de gebruiker, 22-10-2026): met alle
  opties uit (4:3, geen plaatjes achter de levels, geen xBRZ, geen
  vloeiende beweging) ziet Keen 5 er precies uit als het origineel en
  speelt het precies zo; dat geldt ook voor Keen 4. Elke nieuwe extra
  moet uit te zetten zijn. E12 bewijst het voor Keen 5.
- Na elke mijlpaal: de app opnieuw bouwen voor macOS en Windows (op de
  Mac), committen en de branch pushen.

Na E7 is Keen 5 van titel tot highscores uit te spelen (zonder geluid). E8
en E9 maken het compleet, E10 mooier, E11 voegt co-op toe en E12 werkt de
laatste punten naast het origineel af. E13 is optioneel.

## E1. Onderzoek (`milestone-e1-onderzoek`)

- De huidige code in kaart (developer-agent): wat in `src/galaxy/` al
  algemeen is, wat in `src/keen4/` Keen 4-inhoud is en wat niet, en waar
  Keen 4 in de gedeelde code is aangemeld (architecture.md).
- Omnispeak en Commander Genius als documentatie (onderzoeksagent): alles
  wat Keen 5 anders doet dan Keen 4 (research.md).
- De Keen 5-bestanden van de gebruiker uitgelezen met de bestaande
  Galaxy-lezers (in de scratchpad, niets in git): **versie 1.4**; alle zes
  headers op inhoud gevonden; 93 plaatjes, 346 sprites, 1512 + 2952 tiles,
  16 maps, 206 geluidsblokken; twee dingen die de lezers anders moeten
  doen (file-formats.md).
- De architectuur, deze roadmap en de vragen aan de gebruiker.
- Er komt nog geen code.

## E2. De bestanden van Keen 5 inlezen (`milestone-e2-bestanden`)

Doel: alle data van Keen 5 is leesbaar en te bekijken; het startscherm
heeft vijf iconen. Er beweegt nog niets.

Opdracht voor de developer:

1. `GalaxyEpisode` krijgt twee velden, allebei met de huidige werking als
   standaard: `back_tile_count` (0 = uitrekenen zoals nu; Keen 5: 1512) en
   `texts_before_misc` (false; Keen 5: true). `GalaxyChunkRanges` gebruikt
   ze. Test met een zelfgemaakte EGAGRAPH waarin de laatste
   achtergrondtiles leeg zijn en de teksten vóór de misc-blokken staan;
   de bestaande Keen 4-fixtures geven hetzelfde als voorheen.
2. `Keen5Files` (`game_data/keen5`, `--data-dir-keen5=`, naast de app),
   `KEEN5E.EXE` of `KEEN5.EXE`, `EGAGRAPH.CK5`, `GAMEMAPS.CK5`,
   `AUDIO.CK5`.
3. `Keen5Episode`: de getallen van file-formats.md (headerplaatsen van
   1.4, 3 fonts, 5 misc, 7 teksten, 5 demo's, de grootte van de EXE per
   versie zodat 1.4 herkend wordt), de levelnamen (16: maps 0-15) en de
   berichtreeksen die E3-E7 nodig hebben (de zekering, "Keen steps out
   onto Korath III", het statusvenster, het verhaal, de highscores), op
   vorm gevonden zoals bij Keen 4.
4. Het startscherm: een vijfde icoon "Keen 5" met Keen uit de eigen Keen
   5-sprites (`GameCatalog.Game.icon_picture`/`icon_title`); zonder
   bestanden grijs met uitleg; met bestanden voorlopig "Keen 5 - coming
   soon" (`Keen5View`).
5. `--game=5` (de laagste `--game=` wint), de data viewer (de
   Galaxy-pagina krijgt een titelparameter, standaard "Keen 4") en
   `tools/export_graphics.gd` (naar `exported/keen5/`; `_export_galaxy`
   krijgt parameters met Keen 4 als standaard).
6. Bouwscripts nemen `game_data/keen5` mee; `game_data/README.md` en
   `README.md` krijgen Keen 5.
7. De online-id `Keen5Files.GAME_ID` ("commanderperfect-keen5") bestaat,
   maar staat nog **niet** in `OnlineProtocol.GAME_IDS` (pas in E11).
8. Tests: `tests/keen5_fixtures.gd`, `test_keen5_data.gd` (echte data: 1.4,
   93 plaatjes, 346 sprites, 1512 + 2952 tiles, 16 maps, 206
   geluidsblokken, de levelnamen, de info-waarden van map 1), de
   uitzondering voor het aantal spellen (drie tests).

Klaar als: vijf iconen op het startscherm, de data viewer alles van Keen 5
laat zien, en de controle van Keen 1-4 slaagt.

## E3. Het gedeelde Galaxy-spel en een level spelen (`milestone-e3-level`)

Doel: elk level van Keen 5 staat op het scherm en Keen kan erdoor lopen,
springen, pogo'en, klimmen en schieten; items, de sleutelkaart,
beveiligingsdeuren, edelsteendeuren en de uitgang werken. Nog geen
wezens.

- **`src/galaxy/game/`** (weg 3, besluit van de gebruiker 22-10-2026): `GalaxyGameRules` (de getallen van een
  deel) en de eerste algemene klassen, gemaakt uit de Keen 4-versies:
  `GalaxyLevelScreen`, `GalaxyPlayScreen`, `GalaxyLevelSession`,
  `GalaxyStart`, `GalaxyFiles`, `GalaxySettings`, `GalaxyIcon`. Keen 4's
  bestanden blijven precies zoals ze zijn. Elke klasse krijgt een eigen
  test met een klein deel van fixtures.
- De haken in de engine (architecture.md, "The seams"): Keen als
  subklasse plaatsen, andere tile-soorten, een 13e item.
- `Keen5View` (`keen5_view.tscn`, de node-indeling van Keen 4) bovenop de
  algemene keten; `--game=5 --level=N`.
- `Keen5Keen`: de sleutelkaart (item 12), de beveiligingsdeur (misc 32:
  zonder kaart geluid 14, met kaart de deur die in drie stappen opengaat
  en `enter_security_door`), de uitgang (0xB1B1) en gewone deuren, het
  verlies van kaart en edelstenen na elk level.
- Scrollblokken alleen info 25; het scorebord; plaatjes achter de levels
  (nog geen eigen plaatjes).
- `tools/keen5_regression.sh` (level 1 en level 11, ook in widescreen).
- In js-dos: level 1 op dezelfde plek naast elkaar leggen; de
  beveiligingsdeur.

Klaar als: alle 15 maps er goed uitzien (4:3, widescreen, xBRZ) en je elk
level zonder wezens kunt uitlopen.

## E4. Wezens (`milestone-e4-wezens`)

- Elk wezen een eigen klasse met eigen actietabel (research.md §7):
  Sparky, Little Ampton (met palen en computers), Slicestar (drie soorten,
  met levenspunten), Shelley (ontploft, ook door vijandschoten), Volteface
  (volgt pijlen), Shikadi-mijn (zoekt Keen, scherven), Robo Red, Spirogrip,
  Spindred, Shikadi Master (schiet, teleporteert), Shikadi (zapt palen),
  Shockshund, Sphereful (met vier diamanten), Korath, de laserkanonnen.
- `Keen5Creatures`: de info-waarden met moeilijkheidsgraad (ook de
  omgekeerde 33-35 voor E5).
- De haken: slapen op 6 tiles, schoten die alleen in beeld bestaan, wit
  oplichten, extra getekende sprites (architecture.md).
- De bugs van het origineel blijven (research.md §11, punt 13).
- In js-dos: elk wezen bekijken met Keen stil of in god mode.

Klaar als: levels 1-13 met alle wezens te spelen zijn.

## E5. Platforms, zekeringen en de QED (`milestone-e5-mechaniek`)

- Platforms: rode en paarse asplatforms, GoPlats die pijlen volgen,
  vallend, staand (moeilijkheid omgekeerd), het sneak-platform; Keen
  "surft" erop (`ride_platform`).
- Schakelaars die B-blokken of pijlen omdraaien, bruggen,
  krachtvelden (nakijken in de maps en js-dos, research.md §12).
- Zekeringen: breken met een pogo-landing (snelheid ≥ 48), de explosie,
  het puin uit de linkerbovenhoek, het bericht met Keen (twee plaatjes),
  level klaar (14).
- De QED in level 12: scherven van een mijn vernietigen hem; het einde
  van het level.
- De bliksem bij deuren; de deur naar Korath III (0x0000).
- In js-dos: een GoPlat, een zekering, het bericht, level 12.

Klaar als: elk level uit te spelen is, ook 12 en 13.

## E6. De wereldkaart (`milestone-e6-kaart`)

- `GalaxyMapSession` (algemeen, uit Keen 4's) en `Keen5MapSession`: map 0
  als level, levels in (0xC000 + n) met het vak "Keen ...", terug na het
  level, wapperende vlaggen (geen geworpen vlag), hekken die verdwijnen.
- **Teleporters** en **liften** (de deuren uit de sjablonen, Keen
  onzichtbaar onderweg), de schachten die opengaan na de vier
  zekeringlevels, **Korath III**.
- Het statusvenster met KEYCARD (algemeen `GalaxyStatusWindow` met een
  eigen middenrij), "Try Again / Exit to Armageddon", `Keen5Progress`
  (levels klaar met 1 of 14, zekeringen).
- In js-dos: een lift, een teleporter, het statusvenster.

Klaar als: je vanaf de kaart alle levels kunt spelen, ook Korath III.

## E7. Einde, game over, titel en demo's (`milestone-e7-einde-titel`)

- `GalaxyFrontScreen`, `GalaxyTitleLoop`, `GalaxyHelp`, `GalaxyEnding`,
  `GalaxyHighScoreBoard` (algemeen, uit Keen 4's).
- Het einde na de QED (en E+N+D): de eindpagina's, het **geheime einde**
  als de zekering van Korath III kapot is; highscores op map 15.
- **Game over**: de melkweg die ontploft (het plaatje, de knipperende
  kleuren, 4000 sterren uit het misc-blok, GAMEOVER, 24 s).
- De titel: intro, verhaal, highscores en de demo's 0-3, frame voor frame
  naast het origineel.
- Help (F1).
- Na deze mijlpaal is Keen 5 van titel tot highscores uit te spelen.

## E8. Geluid en muziek (`milestone-e8-geluid`)

- `Keen5Sounds`: de 64 geluiden en de 14 liedjes (lied = mapnummer; het
  verhaal 17, game over 18, help 19, het einde 14), de cache in
  `user://keen5/cache/`.
- De OPL2-synthesizer, de speler en de instellingen zijn al gedeeld.
- In js-dos: een paar geluiden en het begin van een lied naast elkaar.

## E9. Menu's en opslaan (`milestone-e9-menus`)

- `GalaxyMenuScreen` en `GalaxySavedGame` (algemeen, uit Keen 4's):
  het controlepaneel met de kaartplaatjes van Keen 5, moeilijkheid,
  opslaan en laden in `user://keen5/saves`, highscores in
  `user://keen5/high_scores.json`, Paddle War.
- Een test dat Keen 5 nooit in de mappen van Keen 4 schrijft.

## E10. Mooier maken (`milestone-e10-extras`)

- Vloeiende beweging en xBRZ nakijken (gedeeld), eigen plaatjes achter de
  levels in `assets/backgrounds/keen5/` (besluit van de gebruiker, 22-10-2026), de
  builds voor macOS en Windows.

## E11. Co-op (`milestone-e11-coop`)

- `GalaxyCoopScreen`, `GalaxyJoinedScreen`, `GalaxyOnlineScreen`,
  `GalaxyOnlineState`, `GalaxyBoxNames` (algemeen, uit Keen 4's).
- Twee spelers op één toetsenbord met split-screen; online met
  `GAME_ID_KEEN_5` achteraan `OnlineProtocol.GAME_IDS`; overschakelen
  tussen delen. Uitzondering: `tests/test_keen4_online.gd:26`.

## E12. Naast het origineel (`milestone-e12-origineel`)

- Wat na E3-E11 nog `# estimate` of onzeker is, in js-dos nakijken
  (research.md §12).
- **Alle opties uit = het origineel** (wens van de gebruiker): de demo's
  frame voor frame en de schermen op de pixel met alle extra's uit, en
  een test die elke optie van Keen 5 uitzet en nakijkt dat er geen extra
  meer te zien is.
- Het statusvenster, de menu's, de highscores, het einde en game over op
  de pixel nameten; de demo's frame voor frame.

## E13 (optioneel). Keen 4 op het gedeelde Galaxy-spel (`milestone-e13-keen4`)

Alleen als de gebruiker dat wil (vraag 6 in research.md §13): Keen 4's
schermketen en sessies vervangen door de algemene klassen, zodat er één
versie overblijft. Bewijs: de vijf demo's van Keen 4 blijven frame voor
frame gelijk, `tools/keen4_regression.sh` geeft dezelfde beelden, en de
Keen 4-tests slagen (hun namen van privéleden blijven bestaan).

## Inschatting

| Mijlpaal | Schatting (agent) | Waarom |
|---|---|---|
| E2 Bestanden | ~40 min | Twee velden, het vijfde icoon, viewer, export |
| E3 Gedeeld spel + level | ~1,5 u | Het eerste deel van de algemene keten, de haken, Keens deuren |
| E4 Wezens | ~1,5 u | 15 soorten, veel met eigen regels |
| E5 Mechaniek | ~1 u | Platforms op pijlen, zekeringen, de QED |
| E6 Kaart | ~1 u | Teleporters, liften, schachten, Korath III |
| E7 Einde, titel | ~1,25 u | De algemene voorkant, game over als scène, demo's |
| E8 Geluid | ~30 min | Alleen tabellen |
| E9 Menu's | ~45 min | Algemene menuketen, opslaan |
| E10 Extra's | ~45 min | Plaatjes, builds |
| E11 Co-op | ~1 u | Algemene co-op- en online-keten |
| E12 Origineel | ~1 u | |
| **Totaal** | **~10-11 u** | Ongeveer de helft van Keen 4 |
| E13 (optioneel) | ~2 u | Keen 4 overzetten, met de demo's als bewijs |

## Voortgang

| Mijlpaal | Datum | Status |
|---|---|---|
| E1 Onderzoek | 22-10-2026 | Klaar; vragen beantwoord op 22-10-2026 (research.md §13) |
| E2 Bestanden | 22-10-2026 | Klaar (branch `milestone-e2-bestanden`); vijf iconen, viewer en export voor Keen 5 |
| E3 Gedeeld spel + level | 22-10-2026 | Klaar (branch `milestone-e3-level`); `src/galaxy/game/` (regels, start, levelsessie, level- en speelscherm), Keen 5 speelt elk level zonder wezens; sleutelkaart, beveiligingsdeuren, uitgang |
