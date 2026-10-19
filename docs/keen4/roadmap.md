# Roadmap Keen 4

De mijlpalen voor het vierde deel ("Secret of the Oracle"). Hoe Keen 4
naast Keen 1, 2 en 3 komt te staan, staat in
[architecture.md](architecture.md). Wat er over het spel bekend is, staat in
[research.md](research.md), de bestanden in [file-formats.md](file-formats.md).

## Waarom deze roadmap anders is dan die van Keen 2 en 3

Keen 2 en 3 waren dezelfde engine als Keen 1 met andere vijanden: elke
mijlpaal duurde 20-50 minuten. Keen 4 is een **andere engine** (Galaxy):
andere bestanden, andere natuurkunde (hellingen, palen, randen, zwemmen),
een andere klok (35 logische frames per seconde), een wereldkaart die zelf
een level is, en AdLib-muziek. Alleen de buitenkant (startscherm, menu's,
instellingen, opslaan, schalen, online, tools) is te hergebruiken. Reken
op **ongeveer zoveel werk als Keen 1** (12-15 uur), maar met de lessen en
tools van Keen 1-3 erbij.

Wat Keen 4 bouwt aan "Galaxy" (`src/galaxy/`), kunnen Keen 5 en 6 later
gebruiken zonder Keen 4 te veranderen.

## Afspraken

- Elke mijlpaal heeft een branch `milestone-d<n>-<onderwerp>`.
- **D1 (dit onderzoek) begint vanaf `main`** en verandert geen bestaand
  bestand: alleen nieuwe documenten in `docs/keen4/`. Een andere sessie
  werkt aan Keen 3; daarom zijn `PROGRESS.md`, `docs/doorlooptijden.md` en
  `docs/new-episode-guide.md` nu niet bijgewerkt (zie "Voortgang" onderaan;
  bijwerken zodra Keen 3 op `main` staat).
- **D2 begint bij voorkeur nadat Keen 3 op `main` staat** (vraag 10 in
  research.md): dan wordt Keen 4 het vierde icoon bovenop een afgemaakt
  Keen 3. Moet het eerder, dan begint D2 vanaf de nieuwste C-branch (zoals
  C1 vanaf B10) en neemt elke D-branch nieuwere C-branches op, nooit
  andersom.
- **Keen 1, 2 en 3 blijven zoals ze zijn.** Elke mijlpaal eindigt met de
  controle uit [architecture.md](architecture.md): alle bestaande tests
  slagen zonder dat ze zijn aangepast, `gdlint` is schoon, de
  regressie-screenshots van Keen 1 en 2 (en 3 zodra die er zijn) zijn
  gelijk, en de bestanden van Keen 1-3 zijn niet veranderd.
- De architect schrijft per mijlpaal de opdracht (hieronder). De developer
  bouwt die, met tests, en werkt `PROGRESS.md` bij. De architect controleert
  daarna de diff tegen de opdracht en de regels, en vult
  `docs/doorlooptijden.md` aan.
- Getallen komen eerst uit Omnispeak (`(Omni)`, als de gebruiker dat
  toestaat, vraag 1), anders uit Commander Genius (`# estimate`). Nooit code
  overnemen.
- **Naast het origineel tijdens het werk:** elke mijlpaal met iets
  zichtbaars eindigt met een korte vergelijking in js-dos met de eigen
  Keen 4 v1.0 van de gebruiker (`tools/original/`, research.md "Watching
  the original"). Wat dan gemeten is, vervangt de schatting meteen.
- De gebruiker heeft Keen 4 **versie 1.0**. Alles wordt in de EXE op
  **inhoud** gezocht, zodat 1.4 (Steam, GOG, shareware) ook werkt.
- Extra's zijn standaard uit, met dezelfde uitzonderingen als bij Keen 1-3
  (widescreen, plaatjes achter de levels in widescreen).
- Na elke mijlpaal: de app opnieuw bouwen voor macOS en Windows, committen
  en de branch pushen.

Na D8 is Keen 4 van begin tot eind uit te spelen (zonder geluid). D9 en D10
maken het compleet (geluid, menu's, opslaan), D11 mooier, D12 voegt co-op
toe en D13 werkt de laatste punten naast het origineel af.

## D1. Onderzoek (`milestone-d1-onderzoek`)

- De huidige code in kaart (developer-agent): wat Keen 4 van Keen 1-3 kan
  gebruiken, wat Vorticons-specifiek is, en welke gedeelde plekken een
  vierde spel moeten kennen ([architecture.md](architecture.md)).
- Omnispeak en Commander Genius als documentatie (onderzoeksagent):
  klok, eenheden, acties, natuurkunde, Keen, vijanden, kaart, menu's,
  geluid ([research.md](research.md)).
- De Keen 4-bestanden van de gebruiker uitgelezen (in de scratchpad, niets
  in git): **versie 1.0**, LZEXE-ingepakt; alle zes headers op inhoud
  gevonden; 107 plaatjes, 397 sprites, 1296 + 2916 tiles, 20 maps die
  allemaal goed uitpakken; de info-waarden per map; de tileinfo-volgorde.
- De architectuur, deze roadmap en de vragen aan de gebruiker.
- Er komt nog geen code.

## D2. De bestanden van Keen 4 inlezen (`milestone-d2-bestanden`)

Doel: alle data van Keen 4 is leesbaar en te bekijken; het startscherm
heeft vier iconen. Er beweegt nog niets.

Opdracht voor de developer:

1. `Keen4Files`: vindt `game_data/keen4` (of `--data-dir-keen4=PATH`, of
   naast de app) met `KEEN4E.EXE` (of `KEEN4.EXE`), `EGAGRAPH.CK4`,
   `GAMEMAPS.CK4`, `AUDIO.CK4`.
2. `GalaxyExecutable`: pakt de EXE uit (`DosExecutable`), herkent de versie
   (de tekst "(v1.0)" of "(v1.4)" in het opstartscherm, of de grootte), en
   vindt **op inhoud** de zes headers (`AUDIOHED`, `EGAHEAD`, `MAPHEAD`,
   `TILEINFO`, `AUDIODCT`, `EGADICT`; file-formats.md), de tabel met
   willekeurige getallen, en de teksten (levelnamen, "Keen enters …", de
   berichten van de raad en Lindsey). De bekende posities van 1.0 en 1.4
   eerst proberen, alleen gebruiken als de inhoud klopt. Losse
   header-bestanden naast het spel gaan voor.
3. `GalaxyHuffman`, `GalaxyCarmack`, `GalaxyRlew` (eigen tag).
4. `GalaxyGraphicsFile` en `GalaxyGraphics`: de chunks, de bereiken uit de
   tabellen afgeleid (nooit vaste chunknummers), plaatjes, gemaskeerde
   plaatjes, sprites met oorsprong en hitbox (`GalaxySpriteInfo`), 8×8- en
   16×16-tiles (achter en voor, met masker), de drie lettertypen, de
   teksten, de demo's.
5. `GalaxyMapFile` en `GalaxyMap`: alle maps met drie lagen, naam en maat;
   `GalaxyTileInfo` met de zeven voorgrond-tabellen en de twee
   achtergrond-tabellen.
6. `GalaxyAudioFile`: de chunks als bytes (PC-geluiden, AdLib-geluiden,
   liedjes); nog niets afspelen.
7. Het startscherm: een vierde icoon "Keen 4" rechts van Keen 3, met Keen
   uit de eigen Keen 4-sprites, via de nieuwe optionele
   `GameCatalog.Game.icon_picture` (architecture.md, "The seams"); zonder
   bestanden grijs met uitleg. Met bestanden voorlopig "Keen 4 - coming
   soon". Nakijken dat vier iconen passen.
8. `--game=4` (met of zonder `--level=N`), ook in de data viewer (een
   Galaxy-pagina: beide tilesets, sprites met hitbox, plaatjes, maps met de
   drie lagen) en `tools/export_graphics.gd` (naar `exported/keen4/`).
9. Bouwscripts nemen `game_data/keen4` mee; `game_data/README.md` krijgt
   een stukje over Keen 4 (versie 1.0 of 1.4, welke bestanden).
10. `docs/keen4/file-formats.md` bijwerken met wat de code leerde.
11. Tests: `tests/galaxy_fixtures.gd` (zelfgemaakte Huffman-boom, chunks,
    Carmack/RLEW-lagen, tileinfo, een klein EXE-beeld met de headers op
    andere plekken dan 1.0 en 1.4), `test_galaxy_data.gd` (decoders, de
    zoektochten, ook de "digitale gaten" in `AUDIOHED`) en
    `test_keen4_data.gd` (met echte data: versie, 397 sprites, 1296 + 2916
    tiles, 20 maps, de levelnamen, de info-waarden van map 0).

Klaar als: het startscherm vier iconen toont, de data viewer alle tiles,
sprites, plaatjes en maps van Keen 4 laat zien, en de controle van Keen 1-3
slaagt.

## D3. Een level tekenen (`milestone-d3-level`)

Doel: elk level van Keen 4 staat op het scherm zoals in het origineel, met
een Keen die stilstaat; je kunt rondkijken.

- `Keen4View` (eigen scène, node-indeling van `level_view.tscn`) bovenop
  `GameScreen`; `--game=4 --level=N`.
- `GalaxyLevelMap`: drie `TileMapLayer`s (achter, voor achter de sprites,
  voor vóór de sprites volgens bit 0x80), één atlas per tileset;
  `GalaxyTileAnimator` met de tijden uit `TILEINFO` (achter en voor);
  één `set_tile` voor tiles die veranderen.
- `GalaxyObjectLayer`: sprites op positie + oorsprong, in de volgorde van
  de prioriteiten, met `Interpolation`.
- De camera: `LevelCamera` met de regels van het origineel (Keen tussen
  33 en 167 px van boven) en de **scroll-blokken** (info 25/26). In
  widescreen wordt wat voorbij een scroll-blok zou komen afgedekt (vraag
  3).
- xBRZ via een kleine `GalaxyScaledGraphics` die `XbrzScaler` gebruikt;
  plaatjes achter de levels (`BackdropPictures`) in widescreen.
- Vrij rondkijken (`FreeLook`) zoals in Keen 1-3.
- `tools/keen4_regression.sh` (titel volgt later: level 1 en level 11 als
  screenshot, ook in widescreen).
- In js-dos: level 1 op dezelfde plek naast elkaar leggen (tiles,
  animaties, wat vóór Keen staat).

Klaar als: alle 19 maps er goed uitzien in 4:3 en widescreen, met en
zonder xBRZ.

## D4. Keen beweegt (`milestone-d4-keen`)

Doel: Keen kan door elk level lopen, springen, pogo'en, klimmen en
schieten; items, edelstenen en deuren werken. Nog geen vijanden.

- `GalaxyClock` (2 tics per logisch frame, absolute tic-nummers),
  `GalaxyUnits`.
- Het actiesysteem: `GalaxyAction` (sprites, type, protect, stick to
  ground, timer, snelheid, think/contact/react, next) en `GalaxyObject`;
  `GalaxyWorld` (wakker worden en slapen, botsingen tussen objecten).
- `GalaxyClip`: botsen met tiles, **hellingen**, plafonds, muren, de
  middenkolom-regel; zwaartekracht hoog/midden; versnellen en afremmen op
  oneven tics.
- `GalaxyKeen` met al zijn toestanden uit research §5: staan, lopen (ook op
  hellingen), omhoog/omlaag kijken, door een dunne vloer zakken, springen,
  vallen, pogo, schieten (ook omhoog, in de lucht omlaag, aan een paal),
  **palen** (klimmen, glijden, springen), **randen** (hangen, optrekken),
  deuren (info-doel), dood (dodelijke tiles en uit beeld vallen),
  wachtanimaties.
- De verdover (schot tegen muren, paalgaten), lading.
- Items en tiles: punten, druppels (100 = leven), edelstenen, houders en de
  deur die opengaat, extra leven, lading; extra leven bij 20.000, 40.000 …
- Het **scorebord** (score box) linksboven, in 4:3 en widescreen (vraag 4).
- Het einde van een level: uit beeld lopen links of rechts; voorlopig
  volgt het volgende level; dood → opnieuw; game over → startscherm.
- `Keen4LevelSession`, `Keen4Inventory`.
- Tests met de getallen uit research §5: hoogte van sprong (70 px) en pogo
  (108 px) in tics, loopsnelheid, de hellingen, palen en randen in
  zelfgemaakte mini-levels.
- **In js-dos**: springen, pogo (vasthouden en niet), lopen op een
  helling, paal, rand. Meet en pas aan (research §12, punten 1-3).

Klaar als: je elk level zonder vijanden kunt uitlopen en de sprong en pogo
in js-dos zijn nagemeten.

## D5. Vijanden (`milestone-d5-vijanden`)

- Elk wezen een eigen klasse met eigen actietabel (research §7): slak (met
  slijm), paddenstoel, ei en vogel, Arachnut, Skypest (alleen dood door
  pogo), Wormmouth, wolk (met bliksem), Berkeloid (met vuurbal), Lick,
  Mimrock, Bounder (meerijden en sturen), Smirky (eet items, teleporteert),
  inchworms en de Foot, de dart-guns.
- De verdoving (sterren, hoe lang, wie er niets van merkt), wat Keen doodt.
- Moeilijkheidsgraad in de info-laag (Easy/Normal/Hard, research §6);
  voorlopig Normal.
- In js-dos: elk wezen bekijken met Keen stil of in god mode (snelheden,
  frames, wachttijden).

Klaar als: levels 1-16 met alle wezens te spelen zijn.

## D6. Platforms, schakelaars, de raad en onder water (`milestone-d6-mechaniek`)

- Platforms (vier richtingen, keerpunten, het vallende platform), Keen
  rijdt mee.
- Schakelaars (keerpunt aan/uit) en bruggen (misc 15).
- De **raadsleden**: redden met het Oracle-bericht en Keens antwoord (acht
  verschillende), de conciërge in level 14 (vijf vakken, telt niet mee);
  Lindsey; het wetsuit (bericht, level klaar).
- **Level 17** (Well of Wishes): zwemmende Keen, Dopefish (eet Keen),
  scholen vissen, de sprites die schieten, mijnen.
- In js-dos: een platform, een schakelaar, het zwemmen en de Dopefish.

Klaar als: elk level uit te spelen is, ook level 17.

## D7. De wereldkaart (`milestone-d7-kaart`)

- Map 0 als level met `GalaxyMapKeen` (8 richtingen, 24 per tic), het
  scorebord, de camera.
- Levels in (0xC000 + n) met het vak "Keen enters …", terug na het level.
- Gedane levels: de vlag die gegooid wordt, de wapperende vlaggen, de
  hekken die verdwijnen (0xD0/0xF0), niet opnieuw naar binnen.
- Water: "I can't swim!" zonder wetsuit, zwemmen met.
- **Miragia** die verschijnt en verdwijnt.
- De **Foot**-vlucht naar de Pyramid of the Forbidden.
- Het **statusvenster** (Enter) en het vak "Try Again / Exit to
  Shadowlands" na een dood; game over.
- Map 18 (de Megarocket) zoals het origineel doet (research §12, punt 6).
- `Keen4Progress`: welke levels klaar zijn, wie gered is, wetsuit.
- In js-dos: het lopen, een vlag, Miragia, het statusvenster.

Klaar als: je vanaf de kaart alle levels kunt spelen.

## D8. Het einde, de titel en de demo's (`milestone-d8-einde-titel`)

- Het einde na de achtste redding: de eindtekst met de knipperende pijl,
  dan de highscores (map 19, acht namen met de geredde raadsleden).
- De **cheat E+N+D** werkt (handig om het einde te testen), B+A+T ook.
- De titel: de intro-aftiteling, het verhaal, de highscores en de **vijf
  demo's** (3 tics per frame, de vaste toevalstabel, "two-button firing";
  vraag 8).
- Help (F1): de vijf onderwerpen uit de teksten (`GalaxyTextPages`, met
  `^G`-plaatjes).
- Na deze mijlpaal kun je Keen 4 van begin tot eind uitspelen.

Klaar als: een nieuw spel van titel tot highscore te spelen is, en de
demo's lopen zoals in het origineel (in js-dos naast elkaar gelegd).

## D9. Geluid en muziek (`milestone-d9-geluid`)

- PC-speaker: de 52 geluiden via de gedeelde `SpeakerSynth` (bytes × 60,
  140 Hz; als C8 de snelheid van `SpeakerSynth` verandert, krijgt Galaxy de
  snelheid als optionele parameter), met prioriteiten.
- **`GalaxyOpl`**: een eigen OPL2-synthesizer (twee operatoren per kanaal,
  golfvormen, envelopes, vibrato/tremolo, negen kanalen), geschreven vanuit
  de openbare documentatie van de YM3812, getest met zelfgemaakte
  registerreeksen.
- AdLib-geluiden (140 Hz, één kanaal) en de zes liedjes (560 Hz),
  gerenderd op de achtergrond naar `user://keen4/cache/` (vraag 5); het
  lied per level, het lied van de raad, van het einde en van het verhaal.
- Instellingen: geluid uit / PC-speaker / AdLib, muziek aan/uit.
- In js-dos: een paar geluiden en het begin van een lied naast elkaar
  opnemen.

Klaar als: alle geluiden en liedjes klinken en de cache werkt (tweede
start zonder rekenen).

## D10. Menu's en opslaan (`milestone-d10-menus`)

- Het hoofdmenu met de gedeelde `MenuController` en een `GalaxyMenuView`
  in de stijl van het origineel: Nieuw spel (Easy/Normal/Hard), Laden,
  Opslaan, Instellingen (geluid, muziek, scorebord aan/uit, toetsen),
  Terug naar spel, Spel beëindigen, "Choose Game" terug naar het
  startscherm.
- Moeilijkheidsgraad in de info-laag en bij de verdover (+8 op Easy) en
  de sprong (Easy: zwaartekracht midden).
- Opslaan en laden in `user://keen4/saves` (los van Keen 1-3), highscores
  in `user://keen4/high_scores.json`; toetsen en beeld gedeeld.

## D11. Mooier maken en Paddle War (`milestone-d11-extras`)

- Vloeiende beweging en xBRZ nakijken (gedeeld), de plaatjes achter de
  levels in `assets/backgrounds/keen4/` (alleen eigen plaatjes), de builds
  voor macOS en Windows.
- **Paddle War** in het menu (vraag 7).
- Real-ESRGAN: overslaan zoals bij Keen 2 en 3, tenzij de gebruiker het
  anders wil (vraag 9).

## D12. Co-op (`milestone-d12-coop`)

- Twee spelers op één toetsenbord met split-screen; de toetsen voor twee
  spelers krijgen omhoog/omlaag (vraag 6).
- Online: `GAME_ID_KEEN_4`; meedoen met een host van een ander deel
  schakelt over, zoals bij Keen 1-3. Eigen berichten voor Galaxy (drie
  lagen, de inventaris van Keen 4, de raad, de kaart), achteraan de enums.

## D13. Naast het origineel (`milestone-d13-origineel`)

- Wat na D3-D12 nog `# estimate` is, in js-dos nakijken (lijst in
  research.md, "Only the original can answer").
- Het statusvenster, de menu's, de highscores en het einde op de pixel
  nameten, zoals B10.
- Als de gebruiker een 1.4 heeft: beide versies naast elkaar testen.

## Inschatting

| Mijlpaal | Schatting (agent) | Waarom |
|---|---|---|
| D2 Bestanden | ~1 u | Nieuwe decoders, zoeken op inhoud, viewer, icoon |
| D3 Level tekenen | ~1 u | Drie lagen, animatie, camera met scroll-blokken |
| D4 Keen beweegt | ~2 u | De grootste: klok, acties, hellingen, palen, randen |
| D5 Vijanden | ~1,5 u | 15 soorten |
| D6 Mechaniek | ~1 u | Platforms, raad, onder water |
| D7 Kaart | ~1 u | |
| D8 Einde, titel, demo's | ~1 u | Demo's moeten precies kloppen |
| D9 Geluid | ~1,5-2 u | De OPL2-synthesizer is nieuw |
| D10 Menu's | ~45 min | |
| D11 Extra's | ~45 min | |
| D12 Co-op | ~1 u | |
| D13 Origineel | ~45 min | |
| **Totaal** | **~13-15 u** | Ongeveer Keen 1 |

## Voortgang

| Mijlpaal | Datum | Status |
|---|---|---|
| D1 Onderzoek | 19-10-2026 | Klaar; wacht op de antwoorden op de vragen in research.md §13 |

Volgende stap: de gebruiker beantwoordt de vragen in
[research.md](research.md) §13; daarna begint D2 (bij voorkeur nadat Keen 3
op `main` staat).
