# Voortgang

Dit bestand is het geheugen van het project tussen sessies. Werk het aan het
eind van elke sessie bij.

## Mijlpalen

Wat elke mijlpaal precies inhoudt, staat in [docs/roadmap.md](docs/roadmap.md).

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
| B10 | Naast het origineel leggen (DOSBox) | ⬜ |

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
- **Let op bij testen op één Mac:** met twee vensters tegelijk remt macOS
  het achterste venster af, waardoor de host de handshake te laat
  beantwoordt ("The host did not let you in"). Op twee computers, of met
  een headless host, werkt het (zie `docs/online.md`).

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
- De snelheid van de geluiden (140 Hz) komt uit openbare documentatie en is nog niet met het oor vergeleken. Een paar koppelingen van geluid aan gebeurtenis zijn gokken (zie `docs/sounds.md`); `CLICKSND`, `CRYSTALSND` en `GOINDOORSND` worden niet gebruikt.
- Niet nagebouwd: de intro (Apogee- en id-schermen), de demo, "About ID...", "Ordering Info" en "Previews!". De helptekst (`HELPTEXT.CK1`) wordt niet getoond, omdat die de toetsen van het origineel beschrijft.
- De scores in een nieuwe highscorelijst (100) en de plek van de tabel in de rode lijst zijn geschat.
- Level overslaan (cheat of Page Up/Down) houdt de inventaris, en een level dat zo gekozen is telt wel mee als het wordt uitgespeeld.
- De data viewer toont tiles nog zonder animatie en zonder voorgrond-markering.
- Gemaskeerde tiles (gedrag -2) worden als gewone voorgrond-tiles getekend; Keen 1 gebruikt ze niet.
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
- **Keen 2: de knop op het startscherm** (besluit van de gebruiker, 16-10-2026): lettertype en Keen-mannetje komen altijd uit de Keen 2-data. Zonder die bestanden blijft de knop grijs met een gewoon lettertype (geen Keen 1-data als vervanging).
- **Keen 2: speldata.** De gebruiker heeft Keen 2 op floppies maar geen floppylezer. Keen 2 is geen shareware en wordt nog verkocht, dus het wordt niet gedownload van onofficiële sites. Opties: de Complete Pack op Steam/GOG, of een USB-floppylezer. Tot dan: bouwen en testen met zelfgemaakte testdata; de suites met echte data slaan zich over, en de vragen die alleen de echte bestanden beantwoorden blijven open (research.md).
- **Keen 2: sprong van de youth** (B4, architect): met de getallen uit Commander Genius (200/32 omhoog, zwaartekracht 4/32) springt hij ruim 10 tiles hoog. Dat lijkt te veel; vermoedelijk heeft de youth in het origineel een eigen zwaartekracht. Naast het origineel leggen in B10.
- **Geluidssnelheid (ook Keen 1):** Commander Genius speelt de geluiden met 145,6 Hz, `docs/sounds.md` zegt 140 Hz. Niet aangepast (Keen 1 blijft zoals het is); naast het origineel leggen.

### Toegevoegd op 15-10-2026 (op `milestone-10-menu`)

Na de eerste eigen test van de gebruiker:

- **Adressen zichtbaar.** Het scherm *Host via IP* toont nu meteen het adres op het eigen netwerk en het internetadres (wordt opgezocht zodra het scherm opent: eerst "looking up...", daarna het adres of "not found"). Het venster *Hosting* vult het internetadres in zodra het binnen is; eerder bleef daar "?" staan omdat het venster niet ververste.
- **Eigen wachtwoord.** In de host-setup: *Type Password* (zelf intypen, tot 20 tekens, hoofdletters tellen) en *Random Password*. Een getypt wachtwoord wordt onthouden in `settings.cfg` en de volgende keer weer gebruikt; *Random Password* maakt een nieuw willekeurig wachtwoord en vergeet het getypte.
- Tests in `test_online_menus.gd`: adressen in de setup, het hosting-venster ververst, `address_lines`, eigen wachtwoord typen en onthouden.

## Volgende stap

Keen 2:

1. **Voor de gebruiker:** B7, B8 en B9 proberen in `build/` (Mac en
   Windows): menu's, opslaan, high scores, F7 voor twee spelers, online
   met een vriend (via Steam, of IP op twee computers).
2. Alles van Keen 2 kan in één keer naar `main`: `milestone-b9-coop`
   bevat alle eerdere B-branches.
3. B10: naast het origineel leggen (DOSBox), zie `docs/keen2/roadmap.md`
   en de lijst "Estimates" in `docs/keen2/gameplay.md`.

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
