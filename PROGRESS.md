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
| C9 | Mooier maken (framerate, xBRZ, achtergronden, builds) | ✅ Klaar en gecontroleerd door de architect, met eigen plaatjes achter de levels (branch `milestone-c9-extras`); Real-ESRGAN bewust overgeslagen |
| C10 | Co-op lokaal en online | ✅ Klaar en gecontroleerd door de architect (branch `milestone-c10-coop`); Steam niet te testen in de cloud |
| C11 | Naast het origineel (wat nog geschat is) | ✅ Klaar en gecontroleerd door de architect; C8-C11 gemerged naar `main` (PR #15); een deel blijft geschat (research.md) |
| C12 | Keen 1 en 2 bijwerken met de getallen uit Chocolate Keen (ook de sprongen) | ⬜ |

## Keen 4: mijlpalen D

Het vierde deel is een **andere engine** (Galaxy): nieuwe bestanden,
natuurkunde, klok en geluid. De Galaxy-engine komt in `src/galaxy/` (ook
voor Keen 5 en 6), Keen 4 zelf in `src/keen4/`; Keen 1-3 blijven zoals ze
zijn. Wat elke mijlpaal inhoudt staat in
[docs/keen4/roadmap.md](docs/keen4/roadmap.md), de opzet in
[docs/keen4/architecture.md](docs/keen4/architecture.md), wat er over Keen 4
bekend is in [docs/keen4/research.md](docs/keen4/research.md) en de
bestanden in [docs/keen4/file-formats.md](docs/keen4/file-formats.md).

| # | Mijlpaal | Status |
|---|---|---|
| D1 | Onderzoek: code in kaart, Keen 4 v1.0 van de gebruiker uitgelezen, Omnispeak, architectuur, mijlpalen | ✅ Klaar (branch `milestone-d1-onderzoek`); vragen beantwoord op 19-10-2026 |
| D2 | De bestanden van Keen 4 inlezen, data viewer, vierde icoon | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d2-bestanden`) |
| D3 | Een level tekenen | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d3-level`) |
| D4 | Keen beweegt (klok, acties, hellingen, palen, randen) | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d4-keen`) |
| D5 | Vijanden | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d5-vijanden`) |
| D6 | Platforms, schakelaars, de raad, onder water | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d6-mechaniek`) |
| D7 | De wereldkaart | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d7-kaart`) |
| D8 | Het einde, de titel en de demo's | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d8-einde-titel`) |
| D8.1 | Fix: tekenen op de pixelstappen van het origineel | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d8.1-pixelstappen`) |
| D9 | Geluid en muziek (eigen OPL2-synthesizer) | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d9-geluid`; developer + tester) |
| D10 | Menu's en opslaan | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d10-menus`; developer + tester) |
| D11 | Mooier maken en Paddle War | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d11-extras`; menu-developer + tester en een tekenaar tegelijk) |
| D12 | Co-op | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d12-coop`; developer + tester) |
| D13 | Naast het origineel | ✅ Klaar en gecontroleerd door de architect (branch `milestone-d13-origineel`; drie developers en een tester) |
| D13.2 | Fixes na de test van de gebruiker: split-screen kijken, trillen in pauzes, cheats, online-pagina, glas in Miragia | 🔶 Gebouwd, in test bij de gebruiker (branch `milestone-d13.2-fixes`) |

## Keen 5: mijlpalen E

Het vijfde deel ("The Armageddon Machine") is **dezelfde engine** als Keen
4 (Galaxy). Het spel rond de engine (schermen, sessies, opslaan, titel)
wordt één keer algemeen gemaakt in `src/galaxy/game/`, uit de Keen
4-klassen; Keen 4 zelf bleef bevroren (besluit van de gebruiker,
22-10-2026) tot E13 het op het gedeelde spel zette (besluit van 23-10-2026). Keen 5 komt in `src/keen5/`. Wat elke mijlpaal inhoudt staat
in [docs/keen5/roadmap.md](docs/keen5/roadmap.md), de opzet in
[docs/keen5/architecture.md](docs/keen5/architecture.md), wat er over Keen
5 bekend is in [docs/keen5/research.md](docs/keen5/research.md) en de
bestanden in [docs/keen5/file-formats.md](docs/keen5/file-formats.md).

| # | Mijlpaal | Status |
|---|---|---|
| E1 | Onderzoek: code in kaart, Keen 5 v1.4 van de gebruiker uitgelezen, Omnispeak, architectuur, mijlpalen | ✅ Klaar (branch `milestone-e1-onderzoek`); vragen beantwoord op 22-10-2026 |
| E2 | De bestanden van Keen 5 inlezen, data viewer, vijfde icoon | ✅ Klaar (branch `milestone-e2-bestanden`) |
| E3 | Het gedeelde Galaxy-spel en een level spelen (sleutelkaart, beveiligingsdeuren, uitgang) | ✅ Klaar (branch `milestone-e3-level`) |
| E4 | Wezens (alle 15 soorten van levels 1-13, elk een eigen klasse) | ✅ Klaar (branch `milestone-e4-wezens`) |
| E5 | Platforms op pijlen, zekeringen en de QED | ✅ Klaar (branch `milestone-e5-mechaniek`) |
| E6 | De wereldkaart (teleporters, liften, Korath III, statusvenster) | ✅ Klaar (branch `milestone-e6-kaart`) |
| E7 | Einde, game over (de melkweg ontploft), titel en demo's | ✅ Klaar (branch `milestone-e7-einde-titel`) |
| E8 | Geluid en muziek | ✅ Klaar (branch `milestone-e8-geluid`) |
| E9 | Menu's en opslaan | ✅ Klaar (branch `milestone-e9-menus`) |
| E10 | Mooier maken (plaatjes achter de levels, builds) | ✅ Klaar (branch `milestone-e10-extras`) |
| E11 | Co-op lokaal en online | ✅ Klaar (branch `milestone-e11-coop`) |
| E12 | Naast het origineel; alle opties uit = het origineel | ✅ Klaar (branch `milestone-e12-origineel`) |
| E12.1 | Fixes plaatjes: sterren op de kaart, gepakte items, wolken, ramen (en het schip van Keen 1) | 🔶 Gebouwd, in test bij de gebruiker (branch `milestone-e12.1-fixes`) |
| E13 | Keen 4 op het gedeelde Galaxy-spel | ✅ Klaar (branch `milestone-e13-keen4`) |

**Volgende stap:** E12.1 (de plaatjes) en E13 samen testen. Keen 5 is af (E1-E12) en Keen 4 speelt sinds E13 op
hetzelfde gedeelde Galaxy-spel (`src/galaxy/game/`). Op de Mac: de apps
bouwen (`tools/build_macos.sh`, `tools/build_windows.sh`) en Keen 4 even
naspelen (titel, een level, opslaan en laden, het einde) om te zien dat
alles is zoals het was; de plaatjes in breedbeeld bekijken (vraag bij E10)
en Keen 5 met twee spelers en online proberen (twee computers, of de host
headless; Steam alleen daar). Daarna kan Keen 6 op het gedeelde spel
(docs/new-episode-guide.md, "Keen 6 on the Galaxy game").

## Realistische graphics voor alle spellen: mijlpalen R

Branch `milestone-r1-realistisch-onderzoek` (vanaf `main`, 24-10). Wens van
de gebruiker: alle spellen veel mooier, "foto realistisch", met een extra
optie in het menu om het aan en uit te zetten; alles blijft werken zoals nu.
Onderzoek en voorstel: [docs/realistic/research.md](docs/realistic/research.md).

| # | Mijlpaal | Status |
|---|---|---|
| R1 | Onderzoek: grafische code van alle vijf de spellen, lagen (sfeer, licht, achtergronden, AI-graphics), modellen, menu-optie, mijlpalen | ✅ Klaar; vragen beantwoord op 24-10-2026 |
| R2 | De optie REALISTIC (F8) in alle vijf de spellen + sfeer (bloom, kleur, vignet) | ⬜ |
| R3 | Licht en reliëf (normal maps, lichtbronnen per spel, schaduw) | ⬜ |
| R4 | Realistische achtergronden (o.a. NASA-foto's van Mars voor Keen 1) | ⬜ |
| R5 | AI-proef: ~10 plaatjes naast xBRZ (SDXL + ControlNet Tile) | ⬜ toestemming gegeven (24-10): SDXL, met de originele plaatjes als invoer |
| R6-R8 | AI-graphics Keen 1-3, Keen 4-5, naast elkaar leggen | ⬜ |

**Besluiten van de gebruiker (24-10-2026, R1):** realistisch belicht
(vormen blijven, echte materialen, licht en sfeer; sprites niet volledig
fotografisch); een eigen optie REALISTIC AAN/UIT (F8) in alle vijf de
spellen; de SDXL-proef mag, maar met de **originele plaatjes** als invoer,
niet xBRZ ("iets minder mooi"); eerst R2. Daarna (zelfde dag): het mag
ook tegen fotorealistisch aan zitten, sprites ook, mits de risico's zijn
afgedekt en alles goed loopt. Per risico een maatregel en een meetbare
controle in `docs/realistic/research.md` §10 (o.a. optie uit = elk beeld
gelijk aan `main`, spelstand gelijk met de optie aan, minstens 60 fps op de
Mac en de Windows-pc, geen flikkeren of naden, gemeten door tools);
een mijlpaal is pas klaar als die controles slagen.

**Volgende stap:** R2 op branch `milestone-r2-realistisch-optie`.

## Achtergronden Keen 1 en 2: mijlpalen AB

Branch `milestone-a-b-backgrounds` (vanaf `main`, 22-10). Onderzoek en plan:
[docs/backgrounds/research.md](docs/backgrounds/research.md) en
[docs/backgrounds/roadmap.md](docs/backgrounds/roadmap.md).

| # | Mijlpaal | Status |
|---|---|---|
| AB1 | Onderzoek: elk level bekeken en gemeten, keuzes van de gebruiker | ✅ Klaar |
| AB2 | De vaste wand (`LevelWall`, patroonregel voor het rooster, schaduwen, lichtbundels) | ✅ Klaar en gecontroleerd door de architect (developer) |
| AB3 | De plaatjes: Keen 2-wanden, Keen 1-luchten en -wanden | ✅ Klaar en gecontroleerd door de architect (tekenaar, tegelijk met AB2) |
| AB4 | Samenvoegen en nakijken | ✅ Klaar |
| AB-fix | Fixes na de test van de gebruiker: items, ramen, HUD, sneeuwplatforms, trappen van driehoeken | 🔶 Gebouwd, in test bij de gebruiker |

**Wat er nu is.** In breedbeeld (optie Backgrounds, standaard aan; 4:3
blijft het origineel):

- **Keen 2** speelt in het moederschip: het grijze ruitjespatroon is de
  achterwand van elke kamer. Die wand is nu een eigen textuur die 1:1 met
  de tiles meeschuift (vast aan het level, keuze van de gebruiker). Het
  spel vindt het rooster pixel voor pixel (ook rond items, die heel
  blijven); de schaduw van de muren is het rooster één kleurstap donkerder
  en valt nu als donkere band over de nieuwe wand, zonder ruitjes (wens van
  de gebruiker). Het rooster in het donker (levels 5 en 14) wordt een
  gedimde wand, het teal van level 12 ook wand. Per soort kamer een wand:
  gangen (1-3), Tantalus-centra (elke stad een eigen tint), Home A en B,
  wapenkamers en de donkere schacht. Keen 2's donker (lichten uit) dimt de
  wand mee.
- **Keen 1**: buiten een glijdende Mars-lucht in de sfeer van het plaatje
  van level 1 (dat bleef zoals het was), per stad eigen: ijs (8, 9, 10),
  groen kristal (7), rode rots (13), een kasteel op een rots (16). Binnen
  (de heiligdommen, het kasteel, de tunnel van 13) een vaste stenen wand
  achter het zwart. Het grijs onder een blauwe lamp is een lichtbundel en
  blijft grijs, net als smalle grijze stroken tussen donkere muren (de
  schuine stroken in het kasteel van 16).
- Gemaakt door eigen tekenprogramma's (`tools/make_keen1_backgrounds.py`,
  `tools/make_keen2_walls.py`); niets komt uit de spelbestanden. Een eigen
  plaatje of wand in `game_data/keenN/backgrounds/` wint
  (`levelNN`, `wallNN`).

- [x] Tests: 129 suites groen, 0 SCRIPT ERROR, gdlint schoon.
- [x] Regressies tegen `main`: Keen 1 gelijk; Keen 2 verschilt alleen in
  breedbeeld (de nieuwe wand). In 4:3 alleen verschillen door timing aan
  het begin van een level (ook tussen twee runs van `main`; op frame 300
  identiek).
- [x] Alle 32 levels in breedbeeld gefotografeerd en nagekeken.
- Open: een Keen 2-level indelen kost de eerste keer ~0,6 s (drie soorten
  levels); kleine gaatjes houden het oude rooster (tussen de Yorp-beelden
  in 5 en 14, het glas van de Tantalus-machines); met xBRZ blijft een
  dunne rand roosterkleur rond items, zoals rond de lucht nu; Keen 2's
  donker, split-screen en vloeiende beweging niet per schermafbeelding
  nagekeken (de wand hoort bij het level zelf, dus volgt ze).

### Fixes (22-10)

Zes meldingen uit de test van de gebruiker (breedbeeld, plaatjes aan), alle
van één soort: een pixel in de kleur die wegvalt hoorde bij de tekening
van een tile, of lucht bleef grijs. Regel nu: alleen wat áchter de dingen
ligt wordt een gat (`docs/graphics.md`, onderzoek §8).

1. **Keen 2: oud rooster naast items.** De patroonregel wil groepen van
   2x2; de kolommen van één pixel tussen een item en de rand van zijn tile
   (chocolade, kaarten, flesje, hamburger, taart, beer, straalgeweer)
   bleven rooster. Nu is bij items elk roosterpixel dat via roosterpixels
   aan de rand vastzit wand (items hebben een donkere rand, daar stopt
   het); bij andere tiles met wand hetzelfde tot 2 pixels van de rand
   (lampen, borden).
2. **Keen 2: het glas valt weg.** De witte glasstrepen van een raam zijn
   losse pixels tussen roosterpixels; de "spikkel"-regel maakte ze wand, en
   dan tekende de maskerlaag niets meer vóór Keen. Nu blijven ramen
   (gemaskeerde tiles met masker: 403-422, 371-373) heel, zoals het
   origineel: het rooster achter het glas en de strepen vóór Keen. Levels
   6, 7 en 9. **Keuze van de gebruiker (22-10): achter het glas de nieuwe
   wand.** Nu toont elk raam van Keen 2 (levels 6, 7 en 9) achter het glas
   de wand, naadloos met de cellen eromheen (onder de bovenrand de schaduw
   van het kozijn); alleen de glasstrepen en het kozijn (het masker) staan
   vóór Keen. 4:3 en zonder plaatjes blijft het rooster (origineel).
3. **Keen 2: HUD-icoontjes.** De HUD haalde alleen het effen grijs weg; de
   witte en donkere lijnen van het rooster bleven (al sinds B3). Nu valt
   het hele roosterpatroon rond straalgeweer en kaarten weg
   (`Hud.background_tile`). Keen 1 en 3 ongewijzigd.
4. **Keen 1: plaatje in de onderrand van de sneeuwplatforms** (levels 8,
   9, 10, ...). De grijze schaduw onder het wit raakt links en rechts de
   rand van de tile. Nu blijft grijs (en zwart) dat door de tekening van
   het level is ingesloten (`ColorGroups`: groepen over de tiles heen,
   open als ze effen lucht of de rand van het level raken). Ook het glas
   van de ijsblokken en het "ID"-paneel van level 1 blijven daardoor grijs,
   zoals in het origineel.
5. **Keen 1: plaatje in de donkere muur boven Keen (level 9) en twee grijze
   driehoeken links van Keen (level 10).** Dezelfde trap van grijze
   driehoeken waar de muur van het heiligdom naar de vloer afloopt naast
   de lucht: de AB2-regel maakte de eerste trede lucht en hield de
   volgende grijs. In het origineel zijn ze effen luchtgrijs. Nu is een
   grijze cel met het donker aan maar één kant lucht als ze aan de lucht
   vastzit, hoe ver ook; smalle grijze stroken tussen donkere muren (de
   lange helling in het kasteel van 16) blijven grijs. In 16 zijn ook de
   randen van het brede grijze vlak nu lucht (geen grijze zoom meer).
6. **Gevonden onderweg: Keen 1's zwarte omlijningen werden wand** in levels
   met een wand (platforms, blokken, paddenstoelen). Nu is zwart alleen
   wand als het 2x2 dik is en niet ingesloten.

- [x] Nieuwe suites `test_level_walls_fixes` (tiles en levels van code) en
  `test_level_walls_fixes_data` (echte bestanden); elke fix uitgezet laat
  ze falen. Bestaande tests niet aangepast. 131 suites: 130 groen,
  `test_keen4_v14` overgeslagen, 0 fouten, geen SCRIPT ERROR, gdlint
  schoon.
- [x] Regressies Keen 1, 2 en 4 tegen fe57224: in 4:3 alles gelijk (ook 10
  eigen 4:3-beelden van de plekken); in breedbeeld Keen 1 en 4 gelijk,
  Keen 2 alleen level 1 (items zonder roosterrand) en de HUD (ook op de
  kaart). Apps gebouwd (Mac en Windows).
- Kosten: een Keen 1-level indelen kost nu ~0,15 s bij het starten.
- [x] Ramen met de wand achter het glas (`BackdropHoles.windows`,
  `window_kinds`): tests aangepast (de raamtests van 964f9a8 verwachtten
  het rooster), regressies Keen 1, 2 en 4 tegen 964f9a8 gelijk (4:3 en
  breedbeeld; daar zitten geen ramen in), eigen foto's van de ramen: 4:3
  gelijk, breedbeeld alleen anders binnen de ramen. Apps gebouwd.
- [x] **Tweede ronde (22-10, de volgende test van de gebruiker).** Keen 2:
  geen rooster meer aan de uiteinden van de kleine platforms (schaduw
  zonder eigen lijn hoort bij de schaduw ernaast) en van de rode balk
  (smalle strook tussen rand en zwarte omlijning is wand); de zapper heeft
  in elk beeld zijn armen en dezelfde wand (frames delen hun gaten); de
  uitgang heeft een rechte rand (rechte lijnen van de tekening zijn nooit
  wand); gevonden: de deur in level 12 was doorzichtig (teal, nu
  ingesloten). Keen 1: de zwarte driehoek van de donkere noppenblokken en
  het uitgangsbord (beide beelden) blijven zwart; het licht door de muur
  van het kasteel (level 16) is grijs vanaf de muur, de opening zelf
  toont de lucht. Ook: het "ID"-paneel (level 1) en de ranken (7, 14) per
  animatiebeeld gelijk. Suites `test_level_walls_fixes2` en `_data`
  (falen op de oude regels); 133 suites groen (keen4_v14 overgeslagen),
  gdlint schoon. Regressies tegen 4ccfcfc: Keen 1 en 4 gelijk, Keen 2
  alleen level 1 breedbeeld (balk, platform, zapper); 12 eigen plekken in
  4:3 gelijk, breedbeeld alleen anders waar bedoeld. Kost: een Keen
  1-level indelen ~0,3-0,4 s (was ~0,15 s). Open: twee zwarte pixels in
  tegel 158 (levels 5, 14).
- De testcel van AB2 in het kasteel van 16 is opgelost (zie hierboven):
  de opening in de muur toont de lucht, daarachter grijs.
- [x] **Keen 2: de paarse Guard robot keek achteruit.** `EGAHEAD.CK2` noemt
  112-115 GUARDLEFT en 116-119 GUARDRIGHT, maar de plaatjes zeggen het
  omgekeerde (geweer en oog rechts in 112-115). Links/rechts omgewisseld
  in `Keen2GuardRobot`; nu kijkt hij de kant op waar hij heen zweeft en
  schiet. Alleen namen/plaatjes gecontroleerd (js-dos overgeslagen op
  verzoek). Test `test_guard_robot_faces_the_way_it_floats_and_fires`.

## Mijlpaal E13: wat er nu is

Keen 4 op het gedeelde Galaxy-spel, op `milestone-e13-keen4` (23-10, 05:28 -
07:25 UTC), op verzoek van de gebruiker (23-10-2026: `src/keen4/` mocht
alleen voor deze mijlpaal veranderen). De afwijkingen staan in
`docs/keen5/architecture.md` ("Keen 4 on the Galaxy game (E13)",
"Deviations in E13").

- [x] **`Keen4View` op `GalaxyOnlineScreen`**, net als `Keen5View`: de zeven
  Keen 4-schermen (level, spelen, voorkant, menu, co-op, meespeler, online)
  zijn weg. In de view zit alleen nog wat Keen 4 alleen doet: de raad,
  Lindsey, de conciërge, het duikpak, "I can't swim!", de vlucht op de
  Voet, E+N+D als achtste redding, de geredde leden in de highscores, de
  testcheats, en de naam en de demo's zoals Keen 4 ze deed.
- [x] **De spelklassen dun gemaakt**: `Keen4LevelSession`,
  `Keen4MapSession`, `Keen4Start`, `Keen4Progress`, `Keen4StatusWindow`,
  `Keen4GameBoxes`, `Keen4Help`, `Keen4Ending`, `Keen4Cheats`,
  `Keen4TitleLoop`, `Keen4Audio`, `Keen4Settings`, `Keen4SavedGame` zijn
  subklassen van de Galaxy-klassen met de regels van Keen 4
  (`Keen4Episode.game_rules()`) en alleen Keen 4's eigen inhoud (zwemmen
  in level 17, Miragia, het duikpak, RESCUED, het opslagformaat);
  `Keen4FrontScreen` en `Keen4HighScoreBoard` bewaren alleen namen voor de
  tests. Keen 4's eigen nummering van de vakjes en de getallen online
  blijven (`Keen4BoxNames`, `Keen4OnlineState`, met twee kleine adapters).
  `src/keen4/`: 4.410 regels eruit, 574 erbij; `src/galaxy/game/`: 184
  erbij, 70 eruit.
- [x] **Keen 4 doet alles zoals vroeger** door zeven vlaggen in
  `GalaxyGameRules` (standaard aan, dus Keen 5 verandert niet; Keen 4 zet
  ze uit): de tekenvolgorde van het origineel, de lucht in geplaatste
  tegels, de muziek die stopt tussen de maps (Keen 4's liedje speelt door),
  het stille naspelen van een geladen level, de geluiden van het scherm
  online, de eerste cel van een map zonder Keen, en Return to Game buiten
  een spel.
- [x] **Geen enkele Keen 4-test veranderd.** Zeven Galaxy-functies kregen
  een andere naam (GDScript weigert een statische functie in een subklasse
  met andere parameters, en Keen 4's tests roepen Keen 4's functies aan):
  `start_level`, `start_map`, `begin_replay`, `replay_all`,
  `save_inventory`, `load_inventory`; daardoor riepen drie andere
  testbestanden de nieuwe namen aan (alleen de namen:
  `test_galaxy_game_session`, `test_galaxy_game_saved`,
  `test_keen5_save_play`). Nieuw: `test_keen4_framed_pages` (de rode
  helppagina's van v1.4 in het kader, zonder de bestanden: dezelfde code
  als Keen 5's kader; `test_keen4_v14` slaat over zonder een 1.4-kopie).
- [x] **Bewijs**: **168 suites groen, 1 overgeslagen (Keen 4 v1.4), 0
  FAIL, 0 SCRIPT ERROR**; `gdformat`/`gdlint` schoon. Regressies: Keen 4
  alle 11 gelijk aan de referentie van vóór E2, Keen 5 alle 17 gelijk aan
  E12's, Keen 2 alles gelijk, Keen 1 gelijk aan E12's (alleen het
  startscherm van vóór E2 anders: het vijfde icoon). De demo-suite (alle
  vijf demo's) gelijk. En **naast de E12-build** (een `git worktree`), elk
  beeld van het venster vergeleken: de titellus 15.000 beelden (intro,
  demo's 0-4, verhaal, highscores), een spel van 7.500 beelden (nieuw
  spel, kaart, level 1, statusvenster, help, opslaan, dood en Try Again,
  laden, E+N+D met de raad en de eindpagina's, naam, highscores), 4:3 met
  vloeiend over maps 0, 19, 18, 17 (zwemmen) en 1, de kaart met "I can't
  swim!" en opslaan/laden op de kaart, en een opgeslagen level van de
  E12-build geladen en verder gespeeld: alles gelijk (de enkele beelden
  die verschilden, verschilden net zo tussen twee runs van E12 zelf: het
  naspelen van een geladen level en het xBRZ-voorbereiden lopen op de
  klok van de computer; het geladen level: E12 deed er in vijf runs één of
  twee beelden over, en met evenveel beelden zijn alle 1.000 beelden
  gelijk).
- [x] Niets veranderd in Keen 1-3, `src/game/` of `src/galaxy/` buiten
  `game/`; `git diff origin/main` op Keen 1-3: alleen de goedgekeurde
  regels van eerder.
- **Twee verschillen die je niet ziet**: zonder de Keen 4-bestanden opent
  Escape geen leeg bedieningspaneel meer; B+A+T komt in de beelden van een
  opgeslagen level bij het sluiten van het vak in plaats van bij het
  openen (naspelen geeft hetzelfde).
- **Niet gedaan**: de builds voor macOS en Windows (de gebruiker bouwt op
  de Mac).

## E12.1: fixes (23-10)

Vier meldingen van de gebruiker over Keen 5 in breedbeeld met plaatjes,
en één over Keen 1, op `milestone-e12.1-fixes` (23-10, 10:50 - 11:30).
De regels staan in `docs/keen5/gameplay.md` ("Pictures behind the
levels"), de afwijkingen in `docs/keen5/architecture.md` ("Deviations in
E12.1"), het schip in `docs/graphics.md`.

- [x] **Wereldkaart: geen sterren meer in het plaatje.** De sterren van
  het plaatje schoven tegen de sterren van de kaart zelf in als Keen liep
  (het plaatje beweegt trager). `tools/make_keen5_backgrounds.py` tekent
  voor kaart 0 geen sterren meer; de melkweg en de maan staan op dezelfde
  plek (zelfde seed), de vage nevel heeft een iets andere vorm. De
  sterren van de kaart zelf blijven (het origineel). Alleen
  `level00.webp` is veranderd.
- [x] **Gepakte items lieten een vierkant achter** (level 13: een licht
  blauw vierkant per flesje/snoepje boven de lucht; in de ramen zwarte
  vakjes: level 6 het "dambord" van zes, level 11 en ook 1, 3, 4 en 12).
  Oorzaak: sinds E12 kreeg élke tegel die tijdens het spelen verandert de
  luchtkleur in zijn hele vak (voor de kapotte QED). Nu: een gepakt item
  (voorgrondtegel weg, achtergrond onveranderd) laat zien wat eromheen
  is: een vrijgekomen stukje toont het plaatje als het aansluit op wat
  het plaatje al toonde (in het vak zelf of over de rand), anders de
  luchtkleur (`GalaxyRevealedSky`). Elke andere verandering (QED, deuren)
  houdt de E12-regel. Ook de meespeler online doet dit nu.
- [x] **De paarse wolken van level 13** hadden licht blauwe blokjes in en
  naast zich: lucht in de krul van een wolk en tussen de stippen van haar
  rand bleef licht blauw, afgesneden op de rand van de tegel. Nu is een
  tegel van alleen lucht- en wolkkleuren (721-768) lucht met een wolk:
  al zijn lucht toont het plaatje, en zo'n vak telt als open lucht. De
  tekening van de wolk (ook de donkerblauwe rand) blijft.
- [x] **Ramen met zwarte vakken** (level 11 en het tweede voorbeeld):
  dat waren de gepakte items hierboven. Alle ramen van alle levels
  nagelopen (per level de ramen gezocht, origineel / start / na het
  pakken van alle items naast elkaar): vóór de fix in levels 1, 3, 4, 6,
  11, 12 en 13 vakken na het pakken; daarna nergens meer, behalve waar
  het item over de zwarte binnenrand van het kozijn hing (die blijft
  zwart, zoals de rest van die rand). Gevonden onderweg: **een paal vóór
  een raam** sloot de strook tussen kozijn en paal af (zwart in levels 6
  en 12, al bij de start); nu is sterrenlucht achter een paal open lucht
  waar ze de rand van het vak raakt. Andere tekeningen ervoor (het donker
  in een item, het glas van de QED, de boog van een deur) blijven zoals
  ze waren.
- [x] **Keen 1, het schip als level: grijs onder het schip.** De regel
  van 22-10 (grijs dat door de tekening is ingesloten blijft grijs) zag
  het grijs tussen romp, poten en grond als ingesloten. Op wens van de
  gebruiker een uitzondering alleen voor dit eigen level
  (`ShipLevels.open_sky_under_ship`): het grijs dat vanaf de onderrand van
  het schip bereikbaar is, is lucht; de grijze schaduw van het schip zelf
  blijft. De algemene Keen 1-regel is niet veranderd: de gatenkaarten van
  levels 1-16 zijn byte voor byte gelijk.
- [x] **Tests**: nieuw `test_keen5_picture_fixes` (zonder bestanden: een
  vrijgekomen stuk sluit aan of blijft dicht, een wolk verliest al zijn
  lucht en telt als open, een paal sluit de strook niet af, het donker
  in een item blijft, geen sterren in het kaartplaatje; met bestanden op
  het scherm: flesje in level 13, item in het raam van level 11, de
  wolken, de strook naast de paal in level 12, niets in 4:3) en
  `test_keen1_ship_sky`. De schermtests en de sterrentest falen op de oude
  code (9 fouten). **169 suites groen, 1 overgeslagen (Keen 4 v1.4), 0
  FAIL, 0 SCRIPT ERROR**; `gdformat` en `gdlint` schoon.
- [x] **Regressies** tegen e69bccd: Keen 1 (5) en Keen 4 (11) gelijk;
  Keen 2 gelijk (de eerste run van de basis verschilde door timing bij een
  koude start, een tweede run is gelijk); Keen 5: alleen
  `keen5_level13_wide` (de wolken) en `keen5_world_wide` (geen sterren in
  het plaatje), alle 4:3-beelden gelijk. Niets veranderd in `src/galaxy/`
  buiten `game/`, niets in `src/keen1-4`; Keen 4 gebruikt `src/galaxy/game/`
  niet.
- [x] **Schermafbeeldingen** (macOS, venster, 60 fps): de kaart tijdens
  het lopen, level 13 met gepakte items en de wolken, het raam van level
  6 en 11 met gepakte items, het raam met de paal in level 12, het schip
  van Keen 1; voor en na bekeken.
- [x] **Apps gebouwd** (Mac en Windows).
- **Open punten:** een vrijgekomen stuk wordt beslist met wat de vakken
  eromheen op dat moment tonen (geen nieuwe berekening van de hele map);
  in alle levels gaf dat het goede beeld.
- **Om te proberen:** `godot --path . -- --game=5 --level=13` (pak de
  flesjes in de schacht), `--level=6` (het raam met zes flesjes),
  `--level=0` (lopen op de kaart); Keen 1: `godot --path . -- --level=100`.

## Mijlpaal E12: wat er nu is

Keen 5 naast het origineel, op `milestone-e12-origineel` (23-10, 03:20 -
04:58 UTC, met een herstart van de container halverwege). De metingen
staan in `docs/keen5/research.md` ("Watched in E12"), de regels in
`docs/keen5/gameplay.md`, de afwijkingen in `docs/keen5/architecture.md`
("Deviations in E12").

- [x] **Alle wezens die E4 niet zag, in js-dos (v1.4) bekeken** met twee
  kladkopieën van `GAMEMAPS.CK5` (Keen naast elk wezen) en onze engine op
  dezelfde bestanden; de sprites in elk beeld gevonden op al hun pixels:
  **Spirogrip** (150 tics vast, 64 tics los, draaien op dezelfde plek:
  vraag 5 van §12 beantwoord), **Volteface**, de **rechte en schuine
  Slicestars**, **Spindred**, **Shockshund** (4 s lang dezelfde keuzes),
  de **lasers** (elke 120 tics), de **mijn** (het pad van zijn oog op de
  pixel gelijk, ontploffing op dezelfde plek, 4 × 10 tics pulseren), de
  **Little Ampton** (keerpunt op de pixel gelijk: E4's ~93 px was de
  meetmethode). Alles gelijk, behalve:
- [x] **De Shikadi Master gerepareerd**: in het origineel bleef hij 4, 4,
  8, 8, 3, 1 en 8 rondes staan (Omnispeak: bijna altijd na één ronde
  handelen) en twee van drie teleports eindigden op zijn eigen plek. Nu:
  hij handelt alleen onder 64 van 256, en een plek met een muur in zijn
  5 × 5 tegels wordt opnieuw geprobeerd (Omnispeak's controle kijkt naar
  geen enkele tegel). Twee nieuwe tests.
- [x] **Lift (E6)**: het beeld na de rit stond in js-dos 8 pixels lager:
  dat komt door js-dos's beelden van 3-4 tics (onze rit met 3-tic-beelden
  geeft precies 8 pixels lager). Machinesnelheid, geen regel: niet
  veranderd. Hetzelfde voor een halve stap van de Volteface (de lengte
  van het eerste beeld na het laden).
- [x] **Op de pixel**: het doodsvak (Try Again / Exit to Armageddon) 0
  pixels anders, het bericht van Korath III's zekering (beide beelden) 0,
  **het geheime einde: alle 9 pagina's 0** (geen fade ervoor: zwart tijdens
  het laden), game over beeld voor beeld (64 van 65 opgenomen beelden
  gelijk, één half getekend).
- [x] **`estimate`/`uncertain`/`guess`/`TODO`** in `src/keen5` en
  `src/galaxy/game`: geen enkele meer.
- [x] **Alle opties uit = het origineel**: 4:3, Backgrounds uit, xBRZ uit,
  vloeiend uit: de **vijf demo's opnieuw beeld voor beeld** tegen E7's
  opnamen: demo 0 819/820 (de ander de fade), demo 1 990/991, demo 2
  1343/1343, demo 3 1247/1275 (27 half getekend, 1 fade), demo 4 687/754
  (66 half getekend, 1 fade): elk beeld van ons dat de opname ving is
  gelijk. Statusvenster 0 pixels, paneelkaarten 0 (Configure en Quit
  verschillen door eerdere besluiten). Nieuwe test
  **`test_keen5_original_mode`**: alle opties uit op de wereldkaart en
  levels 1, 4, 11, 12, 13: 320 × 200 op het beeld van het origineel, geen
  plaatje, geen weggehaalde kleur, niets eroverheen geschilderd, geen
  xBRZ, elke sprite op de pixel van het origineel, het scorevak 4 pixels
  binnen; ook met de QED kapot en na het uitzetten tijdens het spelen.
  Keen 4: zijn demo-suite en regressiebeelden ongewijzigd (bevroren).
- [x] **Open punt van E10 opgelost**: een tegel die tijdens het spelen
  verandert houdt de luchtkleur in zijn hele vak (alleen breedbeeld met
  plaatjes), dus de kapotte QED toont geen plaatje meer in zijn raam.
- [x] **Lessen voor Keen 6** in `docs/new-episode-guide.md` (E3-E12) en
  een stuk "Keen 6 on the Galaxy game": de velden van `GalaxyGameRules` en
  de haken die een nieuw deel invult.
- [x] **Tests**: nieuw `test_keen5_original_mode`; `test_keen5_creatures_more`
  (de Master: handelt alleen onder 64, blijft staan zonder vrije plek) en
  `test_keen5_backgrounds` (de kapotte QED blijft zwart, niets in 4:3)
  uitgebreid. **167 suites groen, 1 overgeslagen (Keen 4 v1.4), 0 FAIL, 0
  SCRIPT ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Regressies**: Keen 1 alleen `launcher.png` anders t.o.v. de
  referentie van vóór E2 (gelijk aan E11's: het vijfde icoon), Keen 2 (4)
  en Keen 4 (11) alles gelijk; Keen 5 alle 17 gelijk aan E11.
  `git diff origin/main` op `src/keen2-4`, hun tests, `src/actors`,
  `src/map`, `src/game`: alleen de drie regels met het aantal spellen en
  de ene goedgekeurde regel in `test_keen4_online.gd`; niets veranderd in
  `src/galaxy/` buiten `game/`.
- **Wat nog anders is dan het origineel (bewust)**: de laadpauzes van
  js-dos (zwart voor het einde en de melkweg) niet nagedaan; Configure
  (Keen 4's toetsenkaart, Two Players, Online) en REALLY QUIT? (de regel
  van de gebruiker); de willekeurige volgorde van de fizzle in de titel
  (de onze vast); het gele vlak van de wereldkaart is ook in 4:3 zwart
  (het beeld van het origineel komt er nooit); de stukken van een mijn en
  de keuzes van wezens hangen af van de plek in de toevalstabel (in het
  origineel bij het starten willekeurig); niet gezien (blijven
  Omnispeak's): de bal van de Master en het schot van de Shockshund die
  Keen raken, de Spirogrip die naar Keen vliegt, een verdoofde Volteface.
- **Open punten:** de apps zijn hier niet gebouwd (de gebruiker bouwt op
  de Mac).
- **Om te proberen:** `godot --path . -- --game=5 --level=12` (de Master
  wacht nu langer; Shift+G god mode), F2 voor 4:3 en Options voor de
  rest uit.

## Mijlpaal E11: wat er nu is

Keen 5 speelt met twee spelers op één toetsenbord en online, op
`milestone-e11-coop` (23-10, 02:50 - 03:20 UTC). De regels staan in
`docs/keen5/gameplay.md` ("Two players", "Online"), de klassen en
afwijkingen in `docs/keen5/architecture.md` ("Keen 5's co-op and online
(from E11)", "Deviations in E11").

- [x] **Algemene keten uit Keen 4** (D12) in `src/galaxy/game/`:
  `GalaxyCoopScreen`, `GalaxyJoinedScreen`, `GalaxyOnlineScreen` tussen
  `GalaxyMenuScreen` en `Keen5View` (de volgorde van Keen 4), met
  `GalaxyOnlineState` (de gedeelde getallen + haken voor die van een deel),
  `GalaxyBoxNames`/`GalaxyNamedBoxes` (gedeelde soorten vakjes + vanaf 32
  die van een deel). Het paneel is nu `GalaxyCoopMenuController` (via
  `_new_panel()`). Privénamen van Keen 4 behouden. `src/keen4/` en
  `src/galaxy/` buiten `game/` niet aangeraakt.
- [x] **Twee spelers op één toetsenbord**: F7 of Configure > Two Players,
  split-screen met de gedeelde toetsen (ook omhoog/omlaag), speler 2 is
  `Keen5Keen` in zijn eigen kleuren, de inventaris gedeeld: **de
  sleutelkaart** die de een pakt opent de beveiligingsdeur voor de ander
  (en is dan voor beiden op), zonder kaart zegt de deur nee tegen elk;
  **zekeringen** breekt ieder (level 4: elk één, het level telt 14); de
  uitgang, de deur naar Korath III en de laatste zekering door wie dan
  ook beëindigen het level; elke dood kost één leven; wezens gaan op de
  dichtstbijzijnde Keen af; het sluipplatform let op beiden (E5).
- [x] **De kaart en de ritten**: één Keen op de kaart, gestuurd met de
  toetsen van beiden (Keen 4's regel); **wat hij berijdt (teleporter,
  liften) berijdt hij voor beiden** — er is geen tweede kaart-Keen, dus
  de rit van het origineel blijft precies zo (opgeschreven in
  gameplay.md). Het paneel wacht tijdens een rit, als alleen.
- [x] **Online**: `OnlineProtocol.GAME_ID_KEEN_5` (= `Keen5Files.GAME_ID`)
  **achteraan** `GAME_IDS`; wie bij een host van een ander deel aanklopt
  schakelt over (Keen 1-4 ↔ 5, ook via ENet getest). Geen nieuwe
  berichtsoort: Keen 4's Galaxy-berichten met `Keen5OnlineState` (ook
  sleutelkaart, resterende zekeringen, levels met 14, aankomst op Korath
  III); het zekeringbericht en het Korath III-vak gaan bij naam en de
  meespeler tekent ze uit zijn eigen bestanden; zijn eindpagina's zijn de
  geheime als de host Korath III's zekering brak. Keen 1-4's berichten
  byte voor byte gelijk.
- [x] **Live geprobeerd**: twee vensters (xvfb) via ENet op 127.0.0.1:
  host Keen 5 level 1, de meespeler erin als speler 2, beiden lopen, het
  Try Again-vak op beide schermen; level 4: het zekeringbericht op beide
  schermen gelijk. Split-screen op één toetsenbord in level 2 bekeken
  (schuine lijn, speler 2 met blauwe helm).
- [x] **Tests**: nieuw `test_keen5_online` (volgorde van de ids, wisselen
  tussen Keen 4- en Keen 5-hosts ook via ENet, Steam-lobby's, de getallen
  heen en terug, foute getallen genegeerd, de bytes van een Keen
  5-snapshot vast), `test_keen5_coop` (echte data: sleutelkaart en
  beveiligingsdeur, twee zekeringen, uitgang, Korath-deur, dood, wezens),
  en de boomsuites `test_keen5_coop_screen` (F7, paneel, split-screen,
  kaart met lift voor beiden, Try Again met speler 2's toetsen,
  zekeringbericht, opslaan) en `test_keen5_online_play` (twee echte
  schermen via ENet: speler 2, inventaris met kaart, tegels,
  zekeringbericht, Korath-vak, alleen de host loopt op de kaart, geheim
  einde, weggaan en stoppen). Goedgekeurde uitzondering:
  `tests/test_keen4_online.gd:26` zegt nu "Keen 4 is de vierde".
  **166 suites groen, 1 overgeslagen (Keen 4 v1.4), 0 FAIL, 0 SCRIPT
  ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Regressies**: Keen 1 alleen `launcher.png` anders t.o.v. de
  referentie van vóór E2 (gelijk aan E9's en E10's: het vijfde icoon),
  Keen 2 (4) en Keen 4 (11) alles gelijk; Keen 5 alle 17 gelijk aan E10.
  `git diff origin/main` op `src/keen2-4`, hun tests, `src/actors`,
  `src/map`, `src/game`: alleen de drie regels met het aantal spellen en
  de ene goedgekeurde regel in `test_keen4_online.gd`.
- **Open punten:** Steam niet te testen in de cloud. `test_keen5_online_play`
  gebruikt (als Keen 4's) de echte poort 24800. Eén keer viel
  `test_keen4_coop_screen` ("the screen splits") toen er tegelijk andere
  Godot-processen draaiden; alleen en in de volle run daarna groen (niet
  door E11: Keen 4 is niet veranderd). De apps zijn hier niet gebouwd (de
  gebruiker bouwt op de Mac). In `docs/keen5/roadmap.md` staat de
  voortgangsregel van E10 in de tabel "Inschatting" (niet verplaatst).
- **Om te proberen:** `godot --path . -- --game=5 --level=1`, F7 voor
  speler 2 (zijn toetsen onder Configure > Two Players); online via
  Configure > Online Game.

## Mijlpaal E10: wat er nu is

Keen 5 heeft zijn eigen plaatjes achter de levels, op
`milestone-e10-extras` (23-10, 02:07 - 02:50 UTC). De regels staan in
`docs/keen5/gameplay.md` ("Pictures behind the levels"), de klassen en
afwijkingen in `docs/keen5/architecture.md` ("Keen 5's pictures behind
the levels (from E10)", "Deviations in E10").

- [x] **Alle 14 maps bekeken** (breedbeeld, met de dekking): Keen 5's
  muren en vloeren zijn voorgrondtegels, de achterwanden patronen. Effen
  achtergrond is er alleen buiten: **zwarte ruimte** (tegel 0 en 34
  sterrentegels; rond het station in level 1 en op de kaart, in de ramen)
  en **de lichtblauwe lucht van Korath III** (tegel 105, level 13). Maar
  tegel 0 is ook de binnenkant van elke deur, en zwart zit overal in de
  tekening (strepen, lijnen, roosters).
- [x] **Eigen regel** (`Keen5BackdropPictures`, `Keen5OpenSky`): een tegel
  verliest de luchtkleur aan de rand helemaal als hij grotendeels lucht
  is, anders alleen brede stukken (4×4), nooit een streep of lijn; en
  alleen wat pixel voor pixel verbonden is met open lucht (sterrentegels,
  Korath's lucht, de rand van de map) toont het plaatje, de rest wordt in
  zijn kleur teruggeschilderd. Deuren, dichte zwarte vakken, paalgaten en
  de ontsnappingscapsules in level 1 blijven zwart; ramen met sterren
  tonen het plaatje. Een map krijgt er een als hij ergens open lucht
  heeft: **de wereldkaart en levels 1, 3, 4, 6, 10, 11, 12 en 13**; 2, 5,
  7, 8 en 9 hebben geen ruimte of lucht.
- [x] **Negen plaatjes uit code** (`tools/make_keen5_backgrounds.py`,
  vaste seeds 5000 + map, grove pixels, op het canvas van Keen 3/4): de
  planeet onder het station (1), een nevelband (3, breed), een
  blauwwitte ster (4), een geringde reus (6), zwevende rotsen (10), een
  zwart gat (11), een ontploffende ster (12), een daglucht met twee zonnen
  en het station hoog in de lucht (13), diepe ruimte met een melkweg
  (wereldkaart). Het eigen plaatje van de speler in
  `game_data/keen5/backgrounds/levelNN` wint.
- [x] **De wereldkaart**: met Backgrounds aan toont de ruimte buiten het
  sterrenveld (E6: zwart) en het sterrenveld zelf het plaatje (de sterren
  van de kaart blijven); uit: zwart. 4:3 onveranderd.
- [x] **Vloeiende beweging en xBRZ nagekeken**: niets te repareren. Alle
  sprites die Keen 5 tekent (ook de diamanten van de Sphereful en het oog
  van de mijn) worden door xBRZ geschaald; overlays bewegen vloeiend mee;
  wit oplichten is een shader. Bekeken: levels 1, 6, 13, de kaart, de
  Sphereful, een mijn en een GoPlat met Keen, origineel en xBRZ+vloeiend;
  het controlepaneel blijft met xBRZ scherp in de originele pixels (als
  Keen 4).
- [x] **Builds**: niets nodig; beide scripts kopiëren `game_data/keen5`,
  de export neemt `assets/backgrounds/keen5` mee (zoals Keen 4).
- [x] **Gedeelde code**: alleen `src/galaxy/game/` (nieuw
  `GalaxyGameBackdrops` met twee haken, `rules.make_backdrops`); de
  standaard is precies het oude gedrag. Niets veranderd in `src/galaxy/`
  buiten `game/`.
- [x] **Tests**: nieuw `test_keen5_backgrounds` (zonder bestanden: de
  map met precies deze negen plaatjes, 16:9 of breder, het eigen plaatje
  van de speler wint, regels op zelfgemaakte tegels en maps: deur zwart,
  raam met sterren en de rand open, welke maps; met bestanden: de echte
  maps met een plaatje, de sterrentegels, en op het scherm: level 4's deur
  zwart en raam met plaatje, **niets in 4:3, niets met de optie uit**, de
  ruimte van de wereldkaart met plaatje en zwart met de optie uit);
  `test_keen5_keen` kent de luchttegels. **162 suites groen, 1 overgeslagen
  (Keen 4 v1.4), 0 FAIL, 0 SCRIPT ERROR.**
  `gdformat` en `gdlint` schoon.
- [x] **Regressies**: Keen 5 tegen E9: alleen `keen5_level1_wide` en
  `keen5_level11_wide` anders (het plaatje naast het station en in het
  raam), de rest gelijk; nieuw: level 13 en de kaart direct gespeeld, in
  beide beeldverhoudingen. Keen 1 alleen `launcher.png` anders (gelijk aan
  E9's: het vijfde icoon), Keen 2 (4) en Keen 4 (11) alles gelijk.
  `git diff origin/main` op `src/keen2-4`, hun tests, `src/actors`,
  `src/map`, `src/game`: alleen de twee regels met het aantal spellen.
- **Open punten:** als de QED breekt (level 12) tonen ~70 pixels in het
  raam even het plaatje tot het level eindigt (de map wordt niet opnieuw
  doorgerekend). Naast de spuitmonden op de romp van level 1 blijven
  smalle zwarte randjes. Real-ESRGAN niet (besluit). De apps zijn hier
  niet gebouwd (de gebruiker bouwt op de Mac).
- **Vraag voor de gebruiker (advies gebouwd):** de wereldkaart toont het
  plaatje ook achter het sterrenveld (één ruimte, geen harde rand); de
  ramen van het station tonen het plaatje ook. Alternatieven: alleen
  buiten het sterrenveld, of niet in de ramen.
- **Om te proberen:** `godot --path . -- --game=5 --level=1` (breedbeeld,
  F2 wisselt naar 4:3), `--level=13`, `--level=0`; Options:
  Backgrounds uit geeft het origineel.

## Mijlpaal E9: wat er nu is

Keen 5 heeft zijn controlepaneel en kan opslaan, op `milestone-e9-menus`
(23-10, 01:12 - 02:05 UTC). De regels staan in `docs/keen5/gameplay.md`
("The control panel", "Saving and loading", "Difficulty"), de klassen en
afwijkingen in `docs/keen5/architecture.md` ("Keen 5's control panel (from
E9)", "Deviations in E9"), de vergelijking met het origineel in
`docs/keen5/research.md` ("Watched in E9").

- [x] **Het gedeelde spel**: `GalaxyMenuScreen` (uit `Keen4MenuScreen`,
  tussen `GalaxyFrontScreen` en `Keen5View`: het paneel, nieuw spel per
  moeilijkheid, laden, opslaan, End Game, Paddle War op eigen tics, Sound,
  Music, stille AdLib en scorebox, F1 boven een kaart; de help en "nieuw
  spel" verhuisden mee uit de voorkant, die nu 535 regels heeft, het
  menuscherm 513) en `GalaxySavedGame` (uit `Keen4SavedGame`: op de kaart
  de plek, in een level de start plus elk frame sindsdien, bij laden
  opnieuw gespeeld; nu stil en zonder de god mode van nu). Nieuwe regels:
  de kaartplaatjes vanaf het eind, zes slots, `saves_folder()`. Haak
  `_level_began` in de flow.
- [x] **Keen 5**: elke toets in de titellus en Escape in het spel openen
  het paneel (E7 begon direct een spel); Keen 5's eigen horloge en
  kaartplaatjes (één plek dichter bij het eind dan Keen 4's: MAIN MENU 32
  … horloge 17, op het oog nagekeken); `Keen5SavedGame` bewaart sleutelkaart,
  resterende zekeringen, levels met 1/14 en de aankomst op Korath III; Escape
  wacht tijdens een rit op de kaart (teleporter, liftdeur, vlucht).
  Opslaan in `user://keen5/saves`, instellingen in
  `user://keen5/settings.cfg`, nooit in die van Keen 4.
- [x] **Naast het origineel (js-dos, v1.4)**: hoofdkaart (titellus en in
  het spel), New Game, Load, Save met getypte naam en opgeslagen, Sound en
  het begin van Paddle War **0 pixels verschil**; Configure en REALLY QUIT?
  verschillen alleen waar dat bedoeld is (onze rijen, de regel Choose
  Game). Laden geeft PAUSED, End Game vraagt en toont de highscores, zoals
  Keen 4.
- [x] **Bewijs opslaan/laden**: in level 1 een schermafbeelding, opslaan,
  verder spelen, laden: het beeld is buiten het PAUSED-vak pixel voor
  pixel gelijk (1280×800). Op de kaart staat Keen op dezelfde plek; alleen
  de vlam van de raket begint haar cyclus opnieuw (als Keen 4).
- [x] **Tests**: nieuw `test_galaxy_game_saved` (fixtures: slot heen en
  terug, kaart die niet bestaat, frames en gebeurtenissen, een level
  opnieuw gespeeld, kaartplaatjes Keen 4/5, Keen 5's eigen staat, **elk pad
  in `user://keen5` en geen `user://keen4` in de bronnen**),
  `test_keen5_save_play` (echte data: levels 1, 4, 12, 13 op elke
  moeilijkheid halverwege opgeslagen en terug, met god mode en B+A+T),
  `test_keen5_menus` (boomsuite: paneel uit de titellus, **elke kaart met
  Keen 5's plaatje**, nieuw spel per moeilijkheid met 8 ladingen op Easy,
  opslaan/laden op de kaart en in een level, instellingen bewaard, Paddle
  War, End Game, F1, rit, **niets veranderd in `user://keen4`**);
  `test_keen5_front` opent nu het paneel. **161 suites groen, 1
  overgeslagen (Keen 4 v1.4), 0 FAIL, 0 SCRIPT ERROR.** `gdformat` en
  `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (gelijk aan E7's en E8's: het vijfde icoon), Keen 2
  (4) en Keen 4 (11 beelden) alles gelijk. `git diff origin/main` op
  `src/keen2-4`, hun tests, `src/actors`, `src/map`, `src/game`: alleen de
  twee regels met het aantal spellen. Niets veranderd in `src/galaxy/`
  buiten `game/`.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op de
  Mac). Co-op en online in het paneel komen in E11. De kaarten voor
  joystick en Gravis-pad van het origineel zijn er niet (als Keen 4).
  Opslaan tijdens de vlucht in de lift kan niet (Escape wacht).
- **Om te proberen:** `godot --path . -- --game=5`, een toets: het
  paneel; New Game op Easy, in een level Escape, Save Game, naam typen,
  verder spelen, Escape, Load Game: hetzelfde moment terug onder PAUSED.
  Configure, Options: SCORE BOX uit.

## Mijlpaal E8: wat er nu is

Keen 5 heeft al zijn geluiden en liedjes, op `milestone-e8-geluid` (23-10,
00:38 - 01:15 UTC). De regels staan in `docs/keen5/gameplay.md` ("Sound and
music"), de klassen en afwijkingen in `docs/keen5/architecture.md` ("Keen
5's sound (from E8)", "Deviations in E8"), de metingen in
`docs/keen5/research.md` ("Watched in E8"), de bestanden in
`docs/keen5/file-formats.md` ("Checked in E8").

- [x] **Het gedeelde spel**: `GalaxyAudio` (uit `Keen4Audio`, algemeen:
  namen, aantallen en het lied per map uit de regels, de cache in de map
  van het deel), `GalaxySettings` (uit `Keen4Settings`: stille AdLib en
  scorebox in `user://keen5/settings.cfg`); `GalaxyPlayScreen` speelt nu
  echt (`_play_sound`, `_play_map_song`, `_stop_music`), de muziek stopt
  zodra het spelen van een map ophoudt (Omni CK_PlayLoop: de vakken tussen
  de maps zijn stil), help, verhaal, einde en game over spelen het lied van
  de map die de regels noemen; een `GalaxyScene` vraagt geluid en lied bij
  naam. Vier nieuwe velden in `GalaxyGameRules`.
- [x] **Keen 5**: `Keen5Sounds` met de **64 geluiden** (Omnispeak, CG-namen
  waar Omnispeak UNKNOWN zegt; Keen 5's eigen nummers: de edelsteendeur is
  60, 18 is de beveiligingsdeur) en de **14 liedjes** (elke map zijn eigen,
  verhaal map 17, einde 14, game over 18, help 19 — Keen 5 heeft muziek in
  help); de **melkweg** speelt 54 bij het flitsen, 53 bij de sterren en
  lied 0 bij GAMEOVER; het **zekeringbericht wacht** tot het
  uitgangsgeluid uit is (1,48 s; met geluid uit meteen); Shift+S (AdLib,
  pc-speaker, uit) en Shift+M (muziek) zoals Keen 4, bewaard in de gedeelde
  instellingen. De voorlopige geluidstabellen uit E4-E6 zijn weg.
- [x] **Renderen op de achtergrond** in `user://keen5/cache/` (nooit die
  van Keen 4): eerst het lied van de wereldkaart, dan demo 0 (map 1) en het
  verhaal (`GalaxySoundLibrary.start` kreeg een optionele volgorde; Keen 4
  ongewijzigd). Gemeten (4 kernen, lege cache): AdLib-geluiden 1,2 s, het
  kaartlied 9,7 s, alles 112 s, 85 MB; uit de cache 0,4 s.
- [x] **Naast het origineel (js-dos, v1.4, geluid opgenomen)**: het lied van
  level 1 aan het begin van demo 0 (zelfde deeltonen 62/98/392/990 Hz,
  spectra lopen gelijk op tijdsfactor 1,12 = de bekende js-dos-drift van
  D9), het kaartlied (dezelfde zes deeltonen), de **sleutelkaart** (7
  pulsen, 277/332/550/1002 Hz), de **zekering** (hoge toon 3968-5573 Hz,
  verloop correlatie 0,94), het **uitgangsgeluid** (correlatie 0,90; het
  bericht komt als het is uitgespeeld; E5's "2,3 s" was wandklok-tijd), en
  **stilte tussen de maps** (het kaartlied stopt bij de warp, het laadvak
  is stil, het levellied begint met het level).
- [x] **Tests**: nieuw `test_keen5_sound` (tabel, elk nummer één keer,
  Omnispeak/CG-nummers, **een scan van `src/galaxy` en `src/keen5`: elke
  gespeelde naam heeft een nummer**, lied per map en scherm, cache en
  instellingen in `user://keen5`, 206 brokken, liedjes 192-205, lengtes),
  `test_galaxy_game_audio` (fixtures: tabellen uit de regels, eigen cache,
  resterende tics, Shift+S/M, `GalaxySettings`), `test_keen5_music`
  (boomsuite: lied per map, stilte tussen maps, dood en Try Again,
  **wachten op het uitgangsgeluid** en zonder geluid niet, help, titellus,
  einde, naam intikken, game over, Shift+S/M); `test_keen5_view` zet in
  de zekeringtest het geluid uit. **158 suites groen, 1 overgeslagen (Keen
  4 v1.4), 0 FAIL, 0 SCRIPT ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (gelijk aan E7's: het vijfde icoon), Keen 2 (4) en
  Keen 4 (11 beelden) alles gelijk; Keen 4's demo's, geluid en
  echte-datatests groen. `git diff origin/main` op `src/keen2-4`, hun
  tests, `src/actors`, `src/map`, `src/game`: alleen de twee regels met het
  aantal spellen. Eén naad in de engine: `GalaxySoundLibrary.start(...,
  next_songs)` met standaard geen.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op de
  Mac). Het verhaal-, help-, eind- en game-over-lied niet in js-dos
  opgenomen (hun plaats is Omnispeak's). Het menu voor stille AdLib en de
  scorebox komt in E9. Geluiden delen geen kanaal met de muziek (als Keen
  4, D9). Het origineel wacht vóór elk level ook op het geluid (meestal al
  klaar na het laadvak); niet nagedaan.
- **Om te proberen:** `godot --path . -- --game=5` (titellus: stil intro,
  dan het lied van demo 0; F1 help met eigen muziek), in het spel Shift+S en
  Shift+M; een zekering kapot (level 4): het uitgangsgeluid, dan het
  bericht. De eerste start rendert de liedjes (~2 min op de achtergrond).

## Mijlpaal E7: wat er nu is

Keen 5 is van titel tot highscores uit te spelen (zonder geluid), op
`milestone-e7-einde-titel` (22-10, 23:04 - 23-10, 00:38 UTC). De regels staan
in `docs/keen5/gameplay.md` ("The title loop", "Help", "The end", "Game
over", "The high scores", "The cheats"), de klassen en afwijkingen in
`docs/keen5/architecture.md` ("The Galaxy game", "Keen 5's front (from
E7)", "Deviations in E7"), de metingen in `docs/keen5/research.md`
("Watched in E7").

- [x] **Het gedeelde spel** (`src/galaxy/game/`, uit Keen 4's D8-klassen,
  Keen 4 onaangeraakt): `GalaxyFrontScreen` (nieuwe schakel tussen
  `GalaxyFlowScreen` en `Keen5View`: titellus, demo's met DEMO-bord, help,
  eindpagina's, naam intikken, cheats, scènes), `GalaxyTitleLoop`,
  `GalaxyHelp` (ook de opmaak van help- en eindpagina's met of zonder
  kader), `GalaxyEnding` (tekst als parameter), `GalaxyHighScoreBoard`
  (marges, kleur en de extra kolom uit de regels; Keen 5 zonder kolom),
  `GalaxyCheats`, `GalaxyScene` (een scène over het hele scherm) en
  `GalaxyEgaFade` (de echte EGA-paletten van het in- en uitfaden, als
  shader). Ruim 40 nieuwe velden in `GalaxyGameRules` (plaatjes, teksten,
  liedjes, highscore-marges, kleuren van intro en verhaal).
- [x] **Keen 5**: begint met de **titellus** (intro met rode woorden, demo
  0, verhaal in lichtcyaan, demo 1, highscores op map 15, demo 2, demo 3;
  zelfde volgorde als Keen 4, nagekeken in de opname); een toets start een
  nieuw spel (het controlepaneel komt in E9), Escape het startscherm;
  **help** (F1) met vijf onderwerpen in het rode kader; **einde** na de QED
  of E+N+D: 9 eindpagina's, het **geheime einde** als de zekering van
  Korath III kapot is, knipperende pijl; **game over = de melkweg
  ontploft** (`Keen5GalaxyExplosion`: fade, Melkweg, 18 flitsen, 60
  beelden met 4000 sterren, GAMEOVER 24 s of een toets); daarna de naam
  op de highscores van map 15, bewaard in `user://keen5/high_scores.json`;
  B+A+T geeft ook de sleutelkaart; `--random-seed=N` voor herhaalbare
  beelden.
- [x] **De demo's beeld voor beeld** (js-dos, de titellus van v1.4
  opgenomen, elk beeld op het onze gelegd): vóór E7 stierf Keen in demo 2
  op beeld 193 en in demo 3 op 1064. Vier oorzaken gevonden en opgelost,
  alle vier met een vlag zodat Keen 4 blijft zoals bewezen: het **gedeelde
  stapgeheugen** (ck_nextX/Y) bij landen op een platform en bij opzij
  geduwd worden door een Ampton, **platforms die op de tegelrand stoppen**
  bij keren (Keen 4 v1.0 kaatst terug), een **opgebruikt mijnstuk dat nog
  één beeld getekend wordt**, en de **tekenvolgorde** van sprites met
  dezelfde prioriteit. Nu: demo 0 819/819, demo 1 990/990, demo 2
  1343/1343, demo 3 1247 gelijk + 27 halfgetekende vangsten, demo 4
  (highscores) 677 gelijk + 66 halfgetekende vangsten; **elk beeld van ons
  dat de recorder ving is pixel-gelijk**, alle vijf spelen tot hun eind.
- [x] **Naast het origineel (js-dos, v1.4)**: help-menu, menu met tweede
  onderwerp, pagina 1 en 2 **pixel-gelijk**; alle **9 eindpagina's**
  pixel-gelijk (pijl dof en fel, elke 70 tics); **naam intikken** op map
  15 pixel-gelijk (met cursor); **game over**: de fade-in (twee
  tussenstappen), alle flitsen, alle 47 sterrenbeelden die de recorder
  ving en GAMEOVER pixel-gelijk (58 van 58); intro-scroll 65 van 65
  gelijk, verhaal 147 van 156 (de rest halfgetekend), DEMO-vak gelijk.
  Twee dingen anders dan Omnispeak: ingang 7 flitst met de **tweede** rij
  van de tabel (Omnispeak geeft beide de eerste), en 0x0F is lichtgrijs.
  Het geheime einde zelf niet in js-dos bekeken (tekst en opmaak gelijk
  aan het gewone einde, dat pixel-gelijk is).
- [x] **Tests**: nieuw `test_galaxy_game_front` (titellus, cheats,
  eindpagina's, help, tabel met marges en kolom, scène, naam en bestand,
  met de fixtures), `test_keen5_front` (volgorde, kleuren, DEMO-bord,
  tekenvolgorde, nieuw spel, help-pagina's 13/21/4/15/2, einde en geheim
  einde, naam op map 15, game over, B+A+T), `test_keen5_galaxy_explosion`
  (tics 2148, fades, flitsrijen, sterren en randen, toetsen),
  `test_keen5_demo_sync` (169 sprites op 27 beelden van de vijf demo's,
  gevonden in beelden die pixel-gelijk zijn aan het origineel; faalt
  zonder elk van de vier oorzaken). **155 suites groen, 1 overgeslagen
  (Keen 4 v1.4), 0 FAIL, 0 SCRIPT ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (gelijk aan E6's: het vijfde icoon), Keen 2 (4)
  en Keen 4 (11 beelden) alles gelijk; Keen 4's demo's en
  echte-datatests groen. `git diff origin/main` op `src/keen2-4`, hun
  tests, `src/actors`, `src/map`, `src/game`: alleen de twee regels met
  het aantal spellen. Naden in de engine, alle met de oude werking als
  standaard: `GalaxyWorld.shared_step`/`shared_landing_step`,
  `GalaxyPlatform.bounce`, `GalaxyObjectLayer.original_order`, optionele
  kleuren in intro, verhaal en titellaag; `GalaxyShrapnel` (alleen Keen 5
  gebruikt het) tekent een opgebruikt stuk nog één beeld.
  `tools/keen5_regression.sh` is herhaalbaar (`--random-seed=1`, twee
  runs gelijk) en kreeg intro (breed, 4:3), help-menu, help-pagina,
  eerste eindpagina en de highscores.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op
  de Mac). Geen geluid (E8). De laadtijd van het origineel (1,5 s zwart
  vóór de Melkweg, 2,5 s vóór de eindpagina's in js-dos) doen we niet na.
  De fizzle van de titel volgt een eigen willekeurige volgorde (als Keen
  4). Het uitfaden van het spel vóór de Melkweg gebruikt dezelfde
  EGA-paletten maar is niet beeld voor beeld vergeleken.
- **Om te proberen:** `godot --path . -- --game=5` (titellus; F1 help; een
  toets: nieuw spel), in het spel E+N+D samen (het einde) of B+A+T; voor
  game over vier keer doodgaan (de melkweg ontploft, daarna de
  highscores).

## Mijlpaal E6: wat er nu is

Keen 5 heeft zijn wereldkaart, op `milestone-e6-kaart` (22-10, 22:07-23:05
UTC). Vanaf de kaart is elk level te spelen, ook Korath III. De regels staan
in `docs/keen5/gameplay.md` ("The flow of a game", "The world map", "The
status window"), de klassen en afwijkingen in `docs/keen5/architecture.md`
("The Galaxy game", "Keen 5's world map", "Deviations in E6"), de metingen
in `docs/keen5/research.md` (§8, "Watched in E6").

- [x] **Het gedeelde spel** (`src/galaxy/game/`, uit Keen 4's klassen,
  Keen 4 onaangeraakt): `GalaxyMapSession` (kaart als level, kaart-Keen,
  camera, ingangen 0xC000+n, gedane levels: info weg, hekken 0xD0nn weg,
  vlaggen 0xF0nn wapperend of gegooid volgens de regels), `GalaxyProgress`
  (levels klaar mét waarde, plek op de kaart, haakjes voor extra's in een
  opgeslagen spel), `GalaxyGameBoxes` (laadvak met aftellen voor elke
  tekst, "One moment", PAUSED, het vak na een dood met knipperende keuze,
  "Game Over!" alleen als de episode die tekst heeft),
  `GalaxyStatusWindow` (kader, labels, cijferbalken; eigen middenrij en
  onderrij als haakjes) en een nieuwe schakel `GalaxyFlowScreen` (het
  verloop: kaart → "One moment" → laadvak → level → terug naar de kaart;
  dood → Try Again / Exit; game over; het statusvenster).
  `GalaxyPlayScreen` speelt nu ook de kaart. Nieuwe velden in
  `GalaxyGameRules` (vlaggen, teksten, lettertype, aftelplaatje).
- [x] **Keen 5's kaart** (`Keen5MapSession`, `Keen5MapKeen`,
  `Keen5MapRide`): geen water, geen Foot, alleen wapperende vlaggen op
  (−0x50, −0x1E0); **teleporter** (geluid 41, Keen loopt erop 2 per tic,
  de tegel flitst 0xA7F/0xA80, sprong naar het doel, wakker maken, naar
  het zuiden 3 per tic 90 tics, tegel gewist); **liften** (deur dicht uit
  de sjablonen linksboven, 6 × 8 tics, onzichtbaar 64/12 per tic vliegen,
  deur open, 32 × 8 naar buiten); **schachten** op Keens rij en na de
  zekeringlevels 4, 6, 8 en 10, plekken nagekeken in de echte kaart;
  **Korath III** (deur in level 11 → op info 26, vak "Keen steps out onto
  Korath III", ook terug uit level 13).
- [x] **`Keen5Progress`** (1 of 14 per level, de vier schachtzekeringen,
  de Korath-zekering voor E7, aankomst op Korath III), **statusvenster**
  met KEYCARD (`Keen5StatusWindow`), Enter opent het; op Korath III heet
  de plek "Korath III Base" (gezien in het origineel).
- [x] **Het verloop**: een nieuw spel (`--game=5` zonder `--level`) begint
  op de kaart achter het vak "Keen purposefully wanders about the
  Omegamatic"; `--level=0` de kaart meteen; een level vanaf de kaart gaat
  terug naar de kaart op de plek waar Keen instapte; dood → "You didn't
  make it past …" met Try Again / Exit to Armageddon; game over en de QED
  → voorlopig het startscherm (E7). Sleutelkaart en edelstenen weg na elk
  level en elke dood.
- [x] **Geel blok in breedbeeld (open punt van E3)**: geen dekking maar
  een geel opvultegel (850) rond het sterrenveld van het station, waar het
  originele beeld nooit komt; boven rij 100 nu zwarte ruimte (tegel 0),
  Korath III's gele grond blijft. In 4:3 verandert niets.
- [x] **Naast het origineel (js-dos, v1.4)**, met een kladkopie van
  `GAMEMAPS.CK5` (start op Korath III): het vak "Keen steps out onto
  Korath III" en de vijf aftelbeelden **pixel-gelijk**; het eerste
  kaartbeeld gelijk op één geanimeerde tegel na; het **statusvenster
  pixel-gelijk** (29.184 pixels, op Korath III en bovenin) nadat de
  KEYCARD-rij een pixel omlaag ging (Omnispeak zit er een hoger); de
  **teleporter** vanaf de sprong elk beeld pixel-gelijk; de **lift**
  (boven → midden) instappen en deur dicht pixel-gelijk, na de vlucht staat
  het beeld van het origineel 8 pixels lager (zijn beelden lopen 2-4 tics,
  dus de laatste vluchtstap schiet verder door).
- [x] **Tests**: nieuw `test_galaxy_game_map` (kaartsessie en voortgang
  met de fixtures), `test_galaxy_game_flow` (het verloop, de vakken, het
  statusvenster met de fixtures), `test_keen5_map` (teleporter, beide
  liftkanten, schachten per rij en zekeringen, Korath III, vlaggen en
  hekken met eigen kaartjes), `test_keen5_map_play` (echte kaart: plekken,
  elke liftrit, de teleporter, elke ingang, vlaggen, het opvultegel),
  `test_keen5_status` (KEYCARD, het kaartje, de toetstegels, de vakken);
  `test_keen5_view` herschreven (nieuw spel op de kaart, elk level 1-13
  vanaf de kaart en terug, zekering, Korath III, dood met keuze,
  statusvenster). **151 suites groen, 1 overgeslagen (Keen 4 v1.4), 0
  FAIL, 0 SCRIPT ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (gelijk aan E4's en E5's: het vijfde icoon), Keen
  2 (4) en Keen 4 (11 beelden) alles gelijk; Keen 4's demo's en
  echte-datatests groen. `git diff origin/main` op `src/keen2-4`, hun
  tests, `src/actors`, `src/map`, `src/game`: alleen de twee regels met
  het aantal spellen. Eén additieve naad in de engine:
  `GalaxyMapFlag.wave_at(..., waving_only)`. `tools/keen5_regression.sh`
  kreeg de kaart (4:3, breed, statusvenster); de oude vier beelden zijn
  gelijk aan E5's, de kaartbeelden twee keer gelijk. Let op: de
  levelbeelden hangen af van het willekeurige startpunt (`randi()`): in één
  van drie runs stond in level 1 een wezen anders.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op
  de Mac). Geluiden (deur, teleporter, levelgeluid) worden bij naam
  gevraagd en zijn stil tot E8. Het vak na een dood niet in js-dos bekeken
  (zelfde code en indeling als Keen 4's, D7; de teksten komen uit de
  bestanden van de gebruiker).
- **Om te proberen:** `godot --path . -- --game=5` (nieuw spel op de
  kaart; Enter het statusvenster), `-- --game=5 --level=0` (de kaart
  meteen); met Shift+N naar een level en terug. De lift onderin gaat pas
  open na levels 1 en 2 (hun hekken staan ervoor).

## Mijlpaal E5: wat er nu is

Keen 5 heeft zijn platforms, zekeringen en de QED, op
`milestone-e5-mechaniek` (22-10, 21:18-22:06 UTC). Elk level is nu uit te
spelen, ook 4, 6, 8, 10 en 13 (zekeringen) en 12 (de QED). De regels staan
in `docs/keen5/gameplay.md` ("Platforms", "Fuses and the QED"), de klassen
en afwijkingen in `docs/keen5/architecture.md` ("Keen 5's machinery",
"Deviations in E5"), de metingen in `docs/keen5/research.md` ("Watched in
E5"), wat in de bestanden staat in `docs/keen5/file-formats.md`
("Checked in E5").

- [x] **Platforms** (`Keen5Platforms` plaatst ze): rode asplatforms
  (27-30), paarse (84-87: +0x40, kijken verticaal een kolom verder naar
  het B-blok, **animeren niet**), vallend (32, Keen 4's), staand (33-35,
  **omgekeerde moeilijkheid**: 33 alleen Easy, 34 Easy en Normal, 35
  altijd), het sluipplatform (40: schuift weg als Keen er springend naar
  kijkt) en de rode en paarse GoPlats (36-39, 80-83) op de pijlen met
  `GalaxyPathArrows`. Keen "surft" erop (KEENONPLAT, `ride_platform`).
- [x] **Schakelaars**: een schakelaar draait een pijl om
  ({2,3,0,1,6,7,4,5}) of zet een B-blok aan/uit; de enige nieuwe naad in de
  engine is `GalaxyKeen._switched_info` (standaard Keen 4's XOR). Bruggen
  zoals Keen 4. **Krachtvelden gaan nooit uit**: geen schakelaar wijst
  ernaar (bestanden).
- [x] **Zekeringen** (`Keen5Fuses`): top 57 is een vlakke vloer; landen
  geeft geluid 57, een pogo-landing met snelheid ≥ 48 breekt hem (explosie
  een tegel links, het puin uit de hoek (0,0)/(0,1), Keen valt door); het
  aantal komt uit info 41 (`Keen5Inventory.fuses_remaining`); bij 0 eindigt
  het level 60 tics later (`Keen5LevelEnd`, waarde 14). Daarna **het
  bericht** (`Keen5Messages`): Keen pratend, dan duim omhoog, elk 30 tics
  en een toets; level 13 met de eigen tekst.
- [x] **De QED** (map 12, `Keen5Qed`): geen zekeringtegels in map 12;
  alleen een scherf van een mijn vernietigt hem (vier explosies, de twee
  blokken uit de hoek, 60 tics later het einde, waarde 15; voorlopig het
  volgende level, de eindpagina's in E7).
- [x] **De bliksem bij de deur naar Korath III**: alleen de 0x0000-deur
  van level 11 (de teleporter op (7,33)) heeft info 0 op Keens hoofdrij;
  twee bliksems en geluid 41.
- [x] **Uitslag per level** (`Keen5LevelSession.result()`: 1, 14 of 15),
  bewaard in `Keen5View.levels_done` voor E6's `Keen5Progress`.
- [x] **Naast het origineel (js-dos, v1.4)**: een kladkopie van
  `GAMEMAPS.CK5` met Keens start verplaatst. GoPlats (level 1): alle 280
  beelden op dezelfde plekken als bij ons; paarse platform (level 10): 204
  beelden gelijk, nooit het tweede plaatje; zekering (level 8): breekt na
  ~856 ms (bij ons 886 ms), Keen stuitert verder, **beide berichtschermen
  pixel-gelijk**; bliksem (level 11) op dezelfde pixels; de QED (map 12)
  door een mijn vernietigd, daarna de eindpagina's. Vragen 1-4 van
  research.md §12 beantwoord.
- [x] **Tests**: nieuw `test_keen5_platforms` (elk soort, snelheden,
  keren, omgekeerde moeilijkheid, GoPlats en een omgedraaide pijl,
  sluipplatform, surfen), `test_keen5_fuses` (pogo/sprong/langzame pogo,
  telling, einde met 14, map 12, de QED, de bliksem),
  `test_keen5_mechanics_play` (echte data: levels 4, 6, 8, 10, 13 eindigen
  door hun zekeringen met 14, map 12 door de QED, de deur in level 11, de
  berichten, Keen rijdt op elk soort, elk level met platforms in god
  mode) en `keen5_machine_fixtures.gd`; `test_keen5_view` kreeg het
  zekeringbericht en het puin in xBRZ. **146 suites groen, 1 overgeslagen
  (Keen 4 v1.4), 0 FAIL, 0 SCRIPT ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (gelijk aan E4's: alleen het vijfde icoon), Keen 2
  (4) en Keen 4 (11 beelden) alles gelijk; Keen 4's demo's en
  echte-datatests groen. `git diff origin/main` op `src/keen2-4`, hun
  tests, `src/actors`, `src/map`, `src/game`: alleen de twee regels met
  het aantal spellen. `tools/keen5_regression.sh` twee keer gedraaid: alle
  vier beelden gelijk (andere beelden dan in E4: de wezens en platforms
  lopen).
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op
  de Mac). Het wachten op het einde van het levelgeluid voor het
  zekeringbericht (~2,3 s in het origineel) komt met het geluid (E8).
- **Om te proberen:** `godot --path . -- --game=5 --level=4` (paarse
  GoPlats, twee zekeringen in een schacht), `--level=1` (GoPlats,
  sluipplatform), `--level=13` (Korath III: vallende platforms, één
  zekering); Shift+G voor god mode.

## Mijlpaal E4: wat er nu is

Keen 5 heeft al zijn wezens, op `milestone-e4-wezens` (22-10,
20:31-21:17 UTC). De regels per wezen staan in `docs/keen5/gameplay.md`
("The creatures"), de klassen en afwijkingen in
`docs/keen5/architecture.md` ("Keen 5's creatures", "Deviations in E4"),
de metingen in `docs/keen5/research.md` ("Watched in E4").

- [x] **15 soorten, elk een eigen klasse met eigen actietabel** (getallen
  uit Omnispeak's `ACTION.CK5`, Omni): Sparky (zoeken, aanloop, charge),
  Little Ampton (computers, palen op en af, duwt Keen, dodelijk alleen op
  de paal, stoot Keen van palen), Slicestar (recht met 20 levenspunten en
  keren bij B-blokken; schuin in een 2 × 2-doos met 50, nooit rechts-op),
  Shelley (wacht aan een rand, duikt, ontploft door verdover- en
  vijandschoten, landen en Keens midden; twee scherven), Volteface (volgt
  de pijlen, 300 tics verdoofd), Shikadi-mijn (zoekt Keen, oog als extra
  sprite, twee ontploffingszones, zes scherven), Robo Red (10 schoten,
  schiet terug), Spirogrip, Spindred, Shikadi Master (bal die vonken
  wordt, teleport, de bugs van het origineel), Shikadi (4 levenspunten,
  wit oplichten, zapt palen), Shockshund (2, zit, springt, blaft), Sphereful
  (vier diamanten voor en achter), Korath (onschuldig, duwt) en de
  laserkanonnen. `Keen5Creatures` plaatst ze per moeilijkheid (Normal
  zolang er geen menu is).
- [x] **Naden in de engine** (additief, Keen 4 onveranderd):
  `GalaxyWorld.sleep_margin` (standaard 4, Keen 5 6),
  `GalaxyObject.flash_white` met een witte shader in `GalaxyObjectLayer`,
  nieuw `GalaxyShrapnel` (stuiterende scherven) en `GalaxyPathArrows` (de
  pijlenregel, ook voor E5's GoPlats). Schoten die alleen op het scherm
  leven, extra sprites en de doos-botsing bestonden al
  (`ON_SCREEN_ONLY`, `overlays`, `update_simple_box`).
- [x] **Keen5Keen**: zijwaarts duwen (Omni CK_PhysPushX) en van een paal
  stoten zonder duw (anders dan Keen 4).
- [x] **Naast het origineel (js-dos, v1.4)**: een kladkopie van
  `GAMEMAPS.CK5` met één wezen bij Keens start in levels 3, 4, 5, 7, 12 en
  13. Sparky (16 en 32 per tic, aanloop), Little Ampton (heen en terug in
  258 tics, bij ons 256), Robo Red (64 per 6 tics), Shikadi (heen en weer
  rond Keen, 128 tics), Shelley (ontploft als Keens midden erin komt) en
  Sphereful (diamanten) gedragen zich als bij ons. Alle sprite-namen
  links/rechts op het oog nagekeken: kloppen.
- [x] **Bekeken**: schermafdrukken van levels 1-13 met wezens; de
  Sphereful met diamanten in 4:3.
- [x] **Tests**: nieuw `test_galaxy_creature_seams` (naden),
  `test_keen5_creatures` en `test_keen5_creatures_more` (mini-levels,
  `keen5_creature_fixtures.gd`), `test_keen5_creatures_play` (echte data:
  elke info-waarde bekend, telling per level en moeilijkheid, sprites,
  Voltefaces op hun pad, elk level 600 frames in god mode).
  `test_keen5_level` zet Keen in god mode bij de deuren (er zijn nu
  wezens). **143 suites groen, 1 overgeslagen (Keen 4 v1.4), 0 FAIL, 0
  SCRIPT ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (alleen het vijfde icoon, gelijk aan E3's), Keen 2
  (4) en Keen 4 (11 beelden) alles gelijk; Keen 4's demo's en
  echte-datatests groen. `git diff origin/main` op `src/keen2-4`, hun
  tests, `src/actors`, `src/map`, `src/game`: alleen de twee regels met
  het aantal spellen.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op
  de Mac). Platforms, zekeringen en de QED zijn E5; de GoPlats schrijven
  wel al hun startpijl.
- **Open:** in js-dos niet bekeken (tijd): Volteface, Slicestars, mijn,
  Spirogrip, Spindred, de teleport van de Master, Shockshund, lasers (de
  regels zijn Omnispeak's en getest). `tools/keen5_regression.sh` geeft
  nu andere beelden dan in E3 (er lopen wezens).
- **Om te proberen:** `godot --path . -- --game=5 --level=3` (Sparkies,
  Spindreds, Robo Red), `--level=8` (Shelleys, Shockshunds, Shikadi),
  `--level=11` (Sphereful, Spirogrip, Voltefaces), `--level=12` (mijnen,
  de Shikadi Master), `--level=13` (25 Koraths); Shift+G voor god mode.

## Mijlpaal E3: wat er nu is

Keen 5 is te spelen, nog zonder wezens, op `milestone-e3-level` (22-10,
19:50-20:31 UTC). Het algemene Galaxy-spel staat in `src/galaxy/game/`,
gemaakt uit de Keen 4-klassen; Keen 4 zelf is niet veranderd. De opzet
staat in `docs/keen5/architecture.md` ("The Galaxy game", "Deviations in
E3"), de spelregels in het nieuwe `docs/keen5/gameplay.md`.

- [x] **`src/galaxy/game/`** (weg 3): `GalaxyGameRules` (de getallen van
  een deel: maps, info-waarden, items, sprites, nieuwe-spelwaarden,
  plaatjes, gebruikersmap; Keen 5 vult ze in `Keen5Episode.game_rules()`),
  `GalaxyStart`, `GalaxyLevelSession`, `GalaxyLevelScreen`,
  `GalaxyPlayScreen` (samen 1.223 regels). Keen 4-inhoud (zwemmen, de
  maan, de raad, statusvenster, wereldkaart, geluid) zit er niet in maar
  komt via haken: `_new_keen`, `_set_up_keen`, `_place_info`,
  `_new_inventory`, `_new_session`, `_play_sound`, `_play_map_song`.
- [x] **Naden in de engine** (additief, Keen 4 byte-gelijk):
  `GalaxyKeen.spawn(..., keen)` (een subklasse plaatsen), `_is_door` /
  `_enter_door` (andere deuren), `GalaxyKeenBody._action_rows`,
  `_item_rows`, `item_sounds` (eigen acties, de Vitalin-spat, het 13e
  item) en `_touch_other_tile` (onbekende tile-soorten).
- [x] **Keen 5**: `Keen5View` (het echte spelscherm, de node-indeling van
  Keen 4), `Keen5LevelSession`, `Keen5Keen` (sleutelkaart, de
  beveiligingsdeur die in drie stappen van 15 tics opengaat terwijl Keen 45
  tics naar binnen stapt, uitgang 0xB1B1, deur naar Korath III 0x0000),
  `Keen5SecurityDoor`, `Keen5Inventory` (de sleutelkaart; kaart en
  edelstenen weg na elk level en elke dood), `Keen5Sprites` (eigen tabel:
  Keens sprites zijn vanaf omlaag kijken **niet** die van Keen 4).
  Scrollblokken alleen info 25; info 70 is item 12 (info − 58).
- [x] **Het verloop zoals Keen 4 in D4**: zonder `--level` level 1; uitgang
  → volgend level (13 → 1, 14 overgeslagen); dood → het level opnieuw,
  een leven minder; geen levens meer → startscherm. Shift+N/P, Shift+G,
  Shift+I (ook de sleutelkaart). De wereldkaart (0) wordt alleen bekeken.
- [x] **Naast het origineel (js-dos, v1.4)**: het eerste beeld van level 1
  is pixel voor pixel gelijk (ook Keen en het scorebord); level 11 en de
  wereldkaart hetzelfde beeld en dezelfde tiles (alleen wezens, het
  scorebord op de kaart en animaties verschillen). De beveiligingsdeur is
  in js-dos niet bereikt (te ver, achter wezens); die regels komen uit
  Omnispeak en worden met de echte levels getest.
- [x] **Bekeken** (scratchpad `e3/look`): levels 1, 2, 3, 5, 9, 11, 12,
  13, 15 en de wereldkaart, in 4:3 en breedbeeld, met xBRZ.
- [x] **Tests**: nieuw `test_galaxy_game_session` en
  `test_galaxy_game_screen` (zelfgemaakt deel, `galaxy_game_fixtures.gd`),
  `test_keen5_keen` (mini-levels, `keen5_level_fixtures.gd`),
  `test_keen5_level` (echte data: Keen start in elke map, elk level loopt,
  elke beveiligingsdeur gaat open naar het einde, de uitgang van level 1)
  en `test_keen5_view`. Het coming-soon-scherm en zijn tests zijn weg.
  **139 suites groen, 1 overgeslagen (Keen 4 v1.4), 0 FAIL, 0 SCRIPT
  ERROR.** `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alleen
  `launcher.png` anders (gelijk aan E2's, het vijfde icoon), Keen 2 (4) en
  Keen 4 (11 beelden) alles gelijk; Keen 4's demo's en echte-datatests
  groen. `git diff origin/main` op `src/keen2-4`, hun tests, `src/actors`,
  `src/map`, `src/game`: alleen de twee regels met het aantal spellen.
  `tools/keen5_regression.sh` (level 1 en 11, 4:3 en breedbeeld) is nieuw.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de gebruiker bouwt op de
  Mac). De zekeringlevels (4, 6, 8, 10, 12) hebben geen uitgangsdeur en
  zijn pas uit te spelen met E5; de bliksem bij deuren komt met E6.
- **Open:** in breedbeeld toont de wereldkaart (alleen bekeken) rechts een
  geel blok buiten de kaart: voor E6, als de kaart echt gespeeld wordt.
- **Om te proberen:** `godot --path . -- --game=5` (level 1, uit te lopen
  door de uitgangsdeur), `-- --game=5 --level=3` (de beveiligingsdeur
  helemaal links; Shift+I geeft de sleutelkaart, Shift+G god mode), F2,
  F5, F6.

## Mijlpaal E2: wat er nu is

De bestanden van Keen 5 worden gelezen, op `milestone-e2-bestanden`
(22-10, 19:28-19:47 UTC). Er beweegt nog niets. Wat er geleerd is staat in
`docs/keen5/file-formats.md` ("Texts in KEEN5E.EXE", "Checked in E2"), de
afwijkingen in `docs/keen5/architecture.md`, "Deviations in E2".

- [x] **Twee velden in `GalaxyEpisode`** (additief, standaard zoals
  vroeger): `back_tile_count` (0 = uitrekenen; Keen 5: 1512) en
  `texts_before_misc` (false; Keen 5: true). `GalaxyChunkRanges` gebruikt
  ze; een opgegeven grens voorbij de tiles geeft null. Keen 4 leest
  byte-voor-byte hetzelfde (alle Keen 4-tests en -regressies gelijk).
- [x] **`Keen5Files`** (`game_data/keen5`, `--data-dir-keen5=`, naast de
  app; `KEEN5E.EXE` of `KEEN5.EXE`) en **`Keen5Episode`**: de headers van
  1.4 (alle zes ook zonder bekende plaatsen gevonden, ~85 ms), 3 fonts, 7
  teksten vóór 5 misc-blokken, 5 demo's, de grens 1512, de versie uit de
  grootte (106.417 bytes = 1.4). Gelezen: 93 plaatjes, 3 gemaskeerd, 346
  sprites, 104 + 20 kleine tiles, 1512 + 2952 tiles, 16 mapplaatsen (14
  leeg), 206 geluidsblokken, laden ~75 ms.
- [x] **Teksten op vorm gevonden** (ook zonder bekende plaatsen): de 16
  levelnamen met hun "Keen ..."-teksten (maps 0-15, ook de lege 14), het
  verhaal (37 regels), het statusvenster (12 labels, met KEYCARD), de
  `game`-reeks (met "Keen steps out onto Korath III" en "Exit to
  Armageddon"; Keen 5 heeft geen "Game Over!"-tekst), de cheat-reeks, de
  twee zekeringberichten (op lengte; op regels vond hij een verkeerde
  plek) en de highscoretabel (0x33D56).
- [x] **Vijf iconen op het startscherm**: "Keen 5" met Keen lopend (sprite
  7, op het oog nagekeken: 6/7/14 zijn dezelfde als bij Keen 4) en de naam
  in Keen 5's eigen lettertype; zonder bestanden grijs met uitleg
  (screenshot gezien). Met bestanden opent het "Keen 5 - coming soon"
  (`Keen5View`, Escape of Enter terug); `--game=5 --level=N` zet de
  levelnaam eronder ("Keen 5 has no map N" als die er niet is).
- [x] **`--game=5`** (de laagste `--game=` wint), de data viewer
  (`-- --game=5`; de Galaxy-pagina kreeg een naamparameter, standaard
  "Keen 4", en het tabblad Program toont nu ook de tekstreeksen) en
  `tools/export_graphics.gd -- --game=5` (naar `exported/keen5/`, ~4 s;
  `_export_galaxy` kreeg parameters met Keen 4 als standaard).
  Bouwscripts nemen `game_data/keen5` mee; beide READMEs noemen Keen 5.
- [x] Online-id `Keen5Files.GAME_ID` = "commanderperfect-keen5", **niet** in
  `OnlineProtocol.GAME_IDS` (E11; een test bewaakt dat).
- [x] **Tests**: nieuwe suites `test_keen5_files` (zelfgemaakte data uit
  `tests/keen5_fixtures.gd`: grens opgegeven en teksten vóór misc, zonder
  de velden de oude werking, Keen 4's volgorde onveranderd, bestanden,
  `--game=5`, vijfde icoon, online-id, het coming-soon-scherm) en
  `test_keen5_data` (echte data: versie, plekken, aantallen, alle maps,
  wereldkaart en map 1, namen, tekstreeksen ook zonder bekende plekken,
  highscores, plaatjes, tileinfo, demo's, misc, geluid, icoon). Aantal
  spellen 4 → 5 in `test_launcher`, `test_keen2_files`,
  `test_keen3_files`. **134 suites groen, 1 overgeslagen (Keen 4 v1.4),
  0 FAIL, 0 SCRIPT ERROR**; zonder `game_data/keen5` slaat
  `test_keen5_data` netjes over. `gdformat` en `gdlint` schoon.
- [x] **Controle Keen 1-4**: regressies tegen de nulmeting: Keen 1 alles
  gelijk behalve `launcher.png`, en dat verschilt alleen binnen het
  vijfde icoon (op het oog gezien); Keen 2 en Keen 4 (11 beelden) alles
  gelijk. `git diff origin/main` op `src/keen2-4`, hun tests, `src/actors`,
  `src/map`, `src/game`: alleen de twee regels met het aantal spellen.
  `src/galaxy/` alleen de twee velden.
- **Niet gedaan:** geen vergelijking in js-dos (er is nog niets te spelen);
  de apps zijn hier niet gebouwd (de gebruiker bouwt op de Mac).
- **Open:** een uitgepakte 1.4 (266.096 bytes) werkt, maar heet "unknown"
  (één grootte per versie in de tabel; zie Deviations in E2). Menu- en
  Paddle War-teksten zoekt E9.
- **Om te proberen:** het startscherm (vijfde icoon); `godot --path . --
  --game=5 --level=13`; de data viewer met
  `godot --path . res://src/viewer/data_viewer.tscn -- --game=5`.

## Mijlpaal E1: wat er nu is

Onderzoek voor Keen 5, op `milestone-e1-onderzoek` (vanaf `main`, 22-10).
Alleen documenten, geen code.

- [x] Keen 5 van de gebruiker (zip) uitgelezen in de scratchpad met de
  bestaande Galaxy-lezers: **versie 1.4** (uitgepakt 254.832 bytes, de
  1.4 van Commander Genius; geen versietekst in de EXE), alle zes headers
  op inhoud gevonden zonder bekende plaatsen, 93 plaatjes, 346 sprites,
  16 maps (14 ontbreekt), 206 geluidsblokken (64 + 64 geluiden, 14
  liedjes). Twee dingen moeten de lezers anders doen: de grens tussen
  achter- en voorgrondtiles (1512, de code rekent 1440) en de teksten die
  vóór de misc-blokken staan (`docs/keen5/file-formats.md`).
- [x] Code in kaart (developer-agent): `src/galaxy/` noemt Keen 4 alleen in
  commentaar en twee standaardmappen; het spel rond de engine (~4.500
  regels) zit in `src/keen4/`, 85-95 % niet Keen 4-specifiek.
- [x] Omnispeak en Commander Genius (onderzoeksagent): alles wat Keen 5
  anders doet (`docs/keen5/research.md`): de sleutelkaart (item 12),
  beveiligingsdeuren, zekeringen en de QED, 15 soorten wezens, platforms
  op pijlen, teleporters en liften op de kaart, Korath III, het geheime
  einde, game over als ontploffende melkweg.
- [x] Architectuur (weg 3: algemeen maken in `src/galaxy/game/`, Keen 4
  bevroren), roadmap E2-E13 (~10-11 u), de antwoorden van de gebruiker.
- [x] Tests: zonder Keen 2-4 102 suites groen, 31 overgeslagen; een paar
  Keen 4-suites geven dan `SCRIPT ERROR` (ze slaan niet netjes over, ook
  op `main`; niet aangeraakt, Keen 4 is bevroren). Daarna uploadde de
  gebruiker Keen 2 (1.31), 3 en 4 (v1.0) en haalde de sessie Keen 1:
  **132 suites groen, 1 overgeslagen (Keen 4 v1.4), 0 FAIL, 0 SCRIPT
  ERROR**, `gdlint` schoon. Dat is de nulmeting voor E2.
- Besluiten van de gebruiker (22-10-2026): weg 3; alle keuzes van Keen 4
  gelden ook voor Keen 5; **met alle opties uit speelt en ziet Keen 4 en 5
  eruit als het origineel**; Keen 2-4 worden per sessie mee geüpload;
  de uitzondering in `test_keen4_online.gd` en additieve wijzigingen in
  `src/galaxy/` zijn goedgekeurd.

## D13.2: fixes (21-10)

Zes bugs uit de test van de gebruiker, op `milestone-d13.2-fixes` (vanaf
`milestone-d13.1-versies`). Alleen Galaxy- en Keen 4-code; Keen 1-3 en
de gedeelde code zijn niet veranderd (regressies Keen 1, 2 en 4: 0
verschillen, byte voor byte).

1. **Kijken in split-screen.** Elke Keen had al zijn eigen camera die
   omhoog/omlaag kijkt, maar de split-screen keek naar het midden van
   de Keens en negeerde dat. Nu schuift elke helft mee met de blik van
   zijn eigen Keen (`GalaxyCamera.look_pixels`, `GalaxySplitView`),
   glijdend, maar zo dat zijn Keen 16 px binnen zijn helft blijft en
   nooit voorbij de scroll-blokken. Eén gedeeld beeld schuift niet mee
   (anders kan de ander uit beeld raken).
2. **Trillen in pauzes.** Oorzaak: met vloeiende beweging tekende het
   spel tussen de laatste twee logische frames op het punt van de klok;
   de klok liep in een pauze (vensters, statusvenster, menu, "You didn't
   make it past", na het uitlopen, "One moment") door, dus Keen en
   platforms wiebelden tussen twee plekken. Nu blijft dat punt staan
   zolang het spel niet stapt (`Keen4PlayScreen._blend_to_draw`); ook de
   split-screen glijdt dan niet en wie online meedoet tekent stil zonder
   nieuw beeld van de host. Keen 1-3 hadden dit niet: zij tekenen hun
   sprites niet terwijl een venster of menu het spel stilzet (in de code
   nagekeken); daar is niets aan veranderd.
3. **Cheats.** Keen 4 had Shift+G zonder melding en geen Shift+I. Nu als
   Keen 1-3, in een level en op de kaart, met dezelfde meldingen op
   dezelfde plek: "Cheat: god mode on/off" (ook voor speler 2) en
   Shift+I "Cheat: all four gems and 99 stunner charges" (alle vier de
   edelstenen, minstens 99 ladingen, geen extra leven en geen venster;
   B+A+T en E+N+D blijven). Shift+I in een level gaat mee in een
   opgeslagen level.
4. **Online Game zwart.** De online-pagina's werden op een zwart scherm
   getekend; nu over de pols-computer heen, zoals de andere vensters van
   het menu (`GalaxyOnlinePageView`).
5. **God mode zonder melding**: zie 3.
6. **Door de glazen vloer van Miragia kijken.** Het glas is
   voorgrond-tiles met doorzichtige binnenkant over de effen lucht; met
   een plaatje achter het level zag je het plaatje door het glas, en ook
   door de vloer waar een glazen zuil in de loopband staat. Eerste versie
   (alle ingesloten lucht lichtblauw) nam het plaatje ook uit het glas;
   op verzoek van de gebruiker vervangen door een vloer-regel (zie 8).
7. **Split-screen in kleine ruimtes** (tweede ronde, 21-10). Ging één
   speler een huisje in (een ruimte tussen scroll-blokken die nauwelijks
   groter is dan het beeld, zoals het huisje in Border Village: 8 px
   hoger dan het beeld), dan stond dat huisje midden in het hele scherm,
   bij een schuine lijn deels in de helft van de ander, en zijn eigen
   helft was zwart. Nu: is het scherm gesplitst en is de ruimte van een
   van beiden kleiner dan 1,2 beeld breed of hoog, dan draait de lijn
   (glijdend) naar een rechte lijn door het midden. Wie op dat moment
   het meest links staat krijgt de linkerhelft; de kanten blijven tot de
   lijn weer terug is gedraaid (geen wissel terwijl hij recht staat). Elke
   Keen staat dan midden in zijn eigen helft en zijn helft blijft in zijn
   ruimte: een ruimte kleiner dan de helft staat in het midden van zijn
   helft. Zijn beiden weer buiten, dan draait de lijn terug naar de
   schuine. Eén gedeeld beeld blijft zoals het was (`GalaxySplitView`).
8. **Vloer dicht, glas doorzichtig** (tweede ronde, 21-10). Nu toont al
   het glas het plaatje (gebouwen, zuilen, koepels, ramen) en worden
   alleen gaten in een vloer lichtblauw geschilderd: een rij
   vloercellen (op een tile waar Keen op loopt) met lucht erachter, met
   aan minstens één kant de loopband (voorgrond, dicht, zelf niet om op
   te lopen) en aan de andere kant de band of een muur
   (`GalaxySkyPockets`). Nagekeken op alle Keen 4-levels met een
   plaatje: alleen level 9 (de voeten van de zuilen en koepels in de
   loopband en op de platforms, hoekjes bij muren, de gaten van de
   palen) en 3 pixels in level 5.
9. **Lucht boven de looprand van Miragia** (derde ronde, 21-10). Naast de
   gele slak (level 9, cellen 60-63 in rij 61) schilderde de vloer-regel
   de lucht boven een lage richel lichtblauw: de bovenkant van die richel
   vult alleen de onderste helft van zijn cellen, tussen de band van een
   hogere richel en een hoge muur. Nu moet een gat ook bovenaan dicht zijn
   (geen doorzichtige pixel in de bovenste rij van de cellen: de bovenlijn
   van de band loopt erover); lucht die van boven binnenkomt toont het
   plaatje. In het origineel (js-dos) is dat stuk dezelfde lucht als
   tussen de richels. Alleen die vier cellen en de 3 pixels van level 5
   (een inkeping aan de lucht, aan de rand van de kaart) zijn veranderd;
   alle gaten van ronde 8 blijven dicht.
10. **Vijanden en items die opduiken in breedbeeld** (derde ronde, 21-10).
   Het spel besliste wie wakker is met het beeld van het origineel (320
   pixels); in breedbeeld stond er links en rechts al iets in beeld dat
   nog sliep en pas verscheen als het beeld van het origineel dichtbij
   kwam. Nu telt het brede beeld mee (`GalaxyCamera.view_tiles`): wakker
   worden binnen 1 tile, slapen voorbij 4, schoten weg op 10 tiles,
   "in beeld" (Bounder-geluid, schot dat slapers raakt, Keen die sterft):
   de marges van het origineel rond wat je ziet. In split screen telt
   wat elke helft laat zien; online telt de host voor de meespeler het
   breedste beeld (426 pixels). In 4:3 en in de demo's blijft alles als
   het origineel (een demo zou anders lopen). Een opgeslagen level speelt
   zijn frames weer met dezelfde breedte (die staat tussen de frames, ook
   na F2). Tegels animeren al op de hele kaart; items zijn sprites, dus
   er dook verder niets op.

- [x] Nieuwe suites `test_keen4_d13_2_fixes` (boom), `test_galaxy_split_look`, `test_galaxy_sky_pockets`; ze falen met de fixes uitgezet. 124 suites: 123 groen, `test_keen4_v14` overgeslagen (geen 1.4-bestanden op deze Mac), 0 fouten, geen SCRIPT ERROR, gdlint schoon.
- [x] Regressies Keen 1, 2 en 4 tegen 314286d: alles gelijk. Apps gebouwd (Mac en Windows).
- [x] Tweede ronde (7 en 8): nieuwe suite `test_galaxy_split_small_areas`, `test_galaxy_sky_pockets` herschreven, de glastest in `test_keen4_d13_2_fixes` aangepast en de split-wandeling daar met een vaste seed (het level begint op een willekeurige plek; soms hield een wezen speler 2 tegen, ook al op e3c8482). 125 suites: 124 groen, `test_keen4_v14` overgeslagen, 0 fouten, geen SCRIPT ERROR, gdlint schoon. Regressies Keen 1, 2 en 4 tegen e3c8482: alles gelijk. Apps opnieuw gebouwd.
- [x] Derde ronde (9): `test_galaxy_sky_pockets` met de lage richel tegen een muur (faalt op de oude regel), de level 9-test kijkt ook naar die plek. 125 suites: 124 groen, `test_keen4_v14` overgeslagen, 0 fouten, geen SCRIPT ERROR, gdlint schoon. Regressies Keen 1, 2 en 4 tegen 50138bc: alles gelijk. Apps opnieuw gebouwd.
- [x] Derde ronde (10): nieuwe suites `test_galaxy_wide_waking` (een ding naast het 4:3-beeld slaapt in 4:3 en is wakker en getekend in breedbeeld, marges, split-helft, een breed gespeeld level met F2 halverwege komt terug uit zijn frames; faalt zonder de brede telling) en `test_keen4_wide_waking_screen` (scherm: breedte in een level en in de opslag, 4:3 en demo het origineel). 127 suites: 126 groen, `test_keen4_v14` overgeslagen, 0 fouten, geen SCRIPT ERROR, gdlint schoon. Regressies Keen 1, 2 en 4 tegen 50138bc: alles gelijk (op de regressiebeelden van Keen 4 staat niets aan de rand van het brede beeld). Apps opnieuw gebouwd.
- [x] **Plaatjes: piramides en Miragia** (21-10, verzoek van de gebruiker). Level 11 en 12: de piramides zweefden (lucht tussen hun voet en de duinen, in 12 schaduwen recht eronder als spiegelbeelden). Nu loopt het zand als vlakte door tot hun voet, staat elke piramide er 2-3 rijen in en valt de schaduw over het zand van het licht af: in 12 lang en opzij van de lage zon (nu links), in 11 kort van de maan. Level 9: de paarse heuvels met koepels en masten zijn weg; nu meer zand: duinen met ribbels (zoals het zand van het level zelf), een luchtspiegeling met rotsnaalden en palmen aan de horizon, en een karavaan kamelen op een duinkam. Nagekeken: 5, 7, 8, 10, 13, 14 en 16 staan al op de grond en zijn pixel voor pixel gelijk gebleven. Bekeken als plaatje en in het spel (breedbeeld, levels 9, 11 en 12). 127 suites: 126 groen, `test_keen4_v14` overgeslagen, 0 fouten, geen SCRIPT ERROR (geen GDScript veranderd). Apps opnieuw gebouwd.
- Open: alleen of met twee spelers blijft de blik staan na het loslaten tot Keen van de grond gaat (onze engine; niet naast het origineel gelegd).
- Open: gaat een Keen door een deur terwijl het scherm gesplitst is, dan glijdt zijn helft over het level naar de nieuwe plek (zo was het al); zeg het als dat moet springen.
- Open: schermafbeeldingen met `scripted_play.gd` op de Mac lopen qua frames niet vast (laden duurt wisselend); pauzes zijn daarom vooral in de tests vergeleken.

## Mijlpaal D13: wat er nu is

Gebouwd door vier agents (A: de demo's, B en B2: de metingen, C: versie
1.4 en de laatste controle), gecontroleerd en samengevoegd door de
architect in `milestone-d13-origineel`. Keen 4 is hiermee af.

**A, de demo's.** Alle vijf demo's van v1.0 zijn nu in hele 4:3-beelden
100 % gelijk aan het origineel. Drie oorzaken gevonden: alle wezens slapen
bij de start van een level (en worden wakker binnen een tile van het
beeld), de gedeelde stap van het origineel (een wezen dat een ander
object maakt, zet de stap van het lopende object terug) en een deur zet
het beeld al in Keens eigen beurt op hem. Een nieuwe suite speelt de vijf
demo's en controleert 67 sprites op 24 frames.

**B en B2, de schattingen.** Naast het origineel gelegd (js-dos, v1.0):
wachtanimaties en het boek, de edelsteendeur, het vallende platform, het
statusvenster en "Game Over!" (0 pixels verschil), de Dopefish, de sprite
onder water, de mijn, de slak, de Wormmouth, de wolk, de inchworms, de
dartguns, de Berkeloid en omhoog kijken. Aangepast: "Game Over!" blijft
333 tics staan (gemeten 4,758 s), Keen eindigt na het optrekken aan een
richel naar rechts een stap eerder (zoals het origineel), platforms en
mijnen stuiteren terug bij een keerpunt, en het wetsuitvenster wacht tot
het geluid van het wetsuit klaar is (1,9 s).

**C, versie 1.4.** De shareware 1.4 van de gebruiker werkt: de headers
worden op inhoud gevonden, de help- en eindpagina's zijn rood met een
lijst (0 pixels verschil met het origineel), de rest (levels, wezens,
geluid, menu's) is gelijk aan 1.0. Bij de controle nog twee fouten
opgelost: Keen houdt de stap van zijn loop als hij in hetzelfde frame
stopt en springt (demo 0 van 1.4: 63 % → 75 % gelijk), en F1 opende de
help onder het "PAUSED"-venster na het laden van een spel.

- [x] Alle vijf demo's van v1.0 100 % gelijk in hele beelden.
- [x] De schattingen nagemeten; vier dingen aangepast, de rest vastgelegd in `test_keen4_d13_seen`.
- [x] Versie 1.4 ondersteund en getest (`test_keen4_v14`, slaat over zonder 1.4).
- [x] 121 suites groen, gdlint schoon, regressies Keen 1, 2 en 4: 0 verschillen.
- Let op: een opgeslagen spel midden in een level van vóór D13 begint dat level opnieuw (de terugvaloptie van D10); opslag op de kaart blijft werken.
- Open (gezien, niet aangepast): de plaatjes tijdens het optrekken aan een richel (geen regel past), de beet van de Dopefish (2 px / 2 tics), het schot van de sprite een frame later, de Wormmouth-beet, de Foot, een schakelaar met een platform en het teleporteren van Smirky niet gevangen; de demo's van 1.4 (75/99/79/42 %) en demo 2 en 3 van 1.0 in de oude meting verschillen alleen in wezens met toevalskeuzes.
- Open: twee tests zijn onder zware CPU-belasting soms traag (`test_keen4_coop_screen`, `test_keen4_online_play` met de echte poort 24800).
- Na D13 (`milestone-d13.1-versies`): de README en `game_data/README.md` noemen nu alle vier de episodes, hun mappen en bestanden, en een tabel met de geteste versies (Keen 1: 1.1; Keen 2: 1.31; Keen 3: 1.00; Keen 4: 1.0 en 1.4) en de versies die zouden moeten werken.

## Mijlpaal D12: wat er nu is

Gebouwd door een developer en een tester tegelijk, gecontroleerd door de
architect.

Keen 4 kan nu met twee spelers. Op één toetsenbord voegt F7 (of Configure >
Two Players) speler 2 toe. Hij speelt met de toetsen voor twee spelers, die
nu ook omhoog en omlaag hebben (W/S en de pijltjes, goedgekeurd door de
gebruiker; dat zie je ook in het Controls-menu van Keen 1-3, die verder
precies hetzelfde spelen). Het beeld splitst zoals in Keen 1-3, maar nooit
voorbij een scroll-blok. De inventaris en de levens zijn gedeeld, er is één
scorebord en op de kaart loopt één Keen die door allebei bestuurd wordt.
Onder water zwemmen er twee. Gaat één Keen dood, dan is de poging voor
beiden voorbij; uitlopen terwijl de ander sterft kan niet. Speler 2 wordt
niet opgeslagen. Online gaat via Configure > Online Game, via IP of Steam,
met eigen Galaxy-berichten (de kaart met gewijzigde tiles van drie lagen,
per frame de sprites, geluid, muziek en vakjes, die de meespeler uit zijn
eigen bestanden tekent). Wie bij een host van een andere episode aanklopt,
schakelt over (getest: Keen 1 naar een Keen 4-host en andersom). De
berichten van Keen 1-3 zijn byte voor byte gelijk gebleven (getest tegen
29 opgenomen berichten).

- [x] Twee spelers op één toetsenbord met split-screen; gedeelde toetsen omhoog/omlaag erbij.
- [x] Online (IP en Steam), overschakelen tussen de delen; getest met twee vensters via IP.
- [x] Tests van de tester: 10 suites, 98 tests; twee fouten gevonden en opgelost.
- Open: Steam met twee echte accounts (niet te testen in de cloud); online pauzeren het menu, het statusvenster en de vakjes van de host het spel voor beiden; `test_keen4_online_play` gebruikt de echte poort 24800 (botst met een draaiend spel op dezelfde Mac).

## Mijlpaal D11: wat er nu is

Gebouwd door drie agents tegelijk (een developer en een tester voor het
menu, een tekenaar voor de plaatjes), gecontroleerd en samengevoegd door de
architect in `milestone-d11-extras`.

**Het menu.** Het hoofdmenu van het horloge is nu precies dat van het
origineel: PADDLE WAR staat weer op zijn eigen rij. Het spelletje is
nagebouwd zoals versie 1.0 het speelt en tekent (70 tics per seconde, Keens
batje 2 pixels per tic, de computer 2 van de 3 tics, opslag na 70 tics,
sneller na elke 10 slagen, tot 21, met de vijf eigen geluiden); 0 pixels
verschil met het origineel. "Choose Game" zit onder QUIT (besluit van de
gebruiker): de vraag "REALLY QUIT?" heeft een regel "PRESS C TO CHOOSE
GAME" (C naar het startscherm, Y stopt, elke andere toets terug). Configure
heeft de kaarten SOUND (geen, PC-speaker, AdLib, stille AdLib) en MUSIC
(geen, AdLib) zoals het origineel (0 pixels verschil); kiezen werkt meteen
en blijft bewaard, Shift+S/M werken nog. F1 in het menu opent de help,
Escape brengt je terug op dezelfde kaart. De muziek stopt als het menu
opengaat; "Terug naar spel" start het lied van de kaart opnieuw. De melding
over het scorebord laat eerst nog "(ON)" staan, zoals het origineel. Met
xBRZ blijven het menu, de vensters en de titelplaatjes scherp, en flitst een
level niet meer terug naar de originele graphics bij een schakelaar of
edelsteen. Vloeiende beweging werkt overal. Beide staan standaard uit.

**De plaatjes.** Tien eigen achtergronden voor de levels met lucht (5, 7-14,
16), getekend vanuit code (`tools/make_keen4_backgrounds.py`, met de
gedeelde `tools/background_painter.py`): besneeuwde bergen, een heuveldorp,
buttes bij zonsondergang, duinen met een luchtspiegeling en een karavaan,
een oase, drie manen boven piramides, piramides met lange schaduwen bij rode zon, ruïnes, een storm, een vulkaan.
Samen ~57 KB, alleen in breedbeeld.

- [x] Paddle War, Choose Game onder Quit, SOUND- en MUSIC-kaarten, F1 in het menu, muziek in het menu.
- [x] xBRZ- en vloeiende-beweging-fixes; tests die een draaiend scherm nodig hebben lopen nu mee (`TREE_SUITES` in de testrunner).
- [x] Tien achtergronden en `test_keen4_backgrounds`.
- Besluit van de gebruiker (20-10-2026): de vensters, het menu en de volle schermen van Keen 4 blijven in originele pixels, ook met xBRZ aan.

## Mijlpaal D10: wat er nu is

Gebouwd door een developer en een tester tegelijk (in een eigen worktree,
naast D9), gecontroleerd door de architect en daarna samengevoegd met D8.1
en D9 in `milestone-d11-extras`.

Keen 4 heeft nu het menu van het origineel: het polshorloge met de kaarten,
pixel voor pixel gelijk aan v1.0 (hoofdmenu, nieuw spel, laden, opslaan, de
vragen, het PAUSED-vak). Een toets in de titellus of Escape in een spel
opent het. Je kiest Easy, Normal of Hard, laadt of bewaart in zes slots met
een eigen naam, stelt het scorebord, het beeld en de toetsen in, beëindigt
het spel (highscores, dan de titellus), gaat terug naar het startscherm
(Choose Game, op de plek van Paddle War) of stopt. Op Easy geeft de
verdover 8 schoten en valt Keen na een sprong langzamer (75 in plaats van
67 pixels, nagemeten in het origineel). Opslaan kan overal, net als in het
origineel: op de kaart en midden in een level. Een level wordt bewaard als
zijn begin plus alle frames sinds dat begin; bij laden worden die frames
achter een zwart scherm opnieuw afgespeeld, dus alles staat precies waar
het was. De regels staan in `docs/keen4/gameplay.md`, de afwijkingen in
`docs/keen4/architecture.md` ("Deviations in D10").

- [x] Menu (`GalaxyMenuController`, `GalaxyMenuView`): kaarten, knipperende cursor, vragen; 0 pixels verschil met v1.0.
- [x] Moeilijkheidsgraad overal: info-laag, verdover +8 op Easy, zwaartekracht midden op Easy.
- [x] Opslaan en laden (`GalaxySaveSlots`, `Keen4SavedGame`) in `user://keen4/saves`, los van Keen 1-3; scorebord aan/uit (`Keen4Settings`).
- [x] Tests van de tester: `test_galaxy_menus`, `test_keen4_save`, `test_keen4_save_play`.
- Open: een lang level laden duurt seconden (0,5-2 s per minuut in het level); F1 in het menu (help) en de "(ON)"-tekst onder de scorebord-melding wijken nog af; geluid en muziek in het menu en Paddle War volgen in D11.

## Mijlpaal D9: wat er nu is

Gebouwd door een developer en een tester tegelijk (in een eigen worktree,
naast D10), gecontroleerd door de architect.

Keen 4 heeft geluid en muziek. Een eigen OPL2-synthesizer (`GalaxyOpl`,
geschreven vanuit de handleiding van de YM3812: negen kanalen met twee
operatoren, vier golfvormen, envelopes met key-scale rate, feedback, FM en
additief, tremolo en vibrato) rendert de 52 AdLib-geluiden en de zes liedjes
één keer op de achtergrond en bewaart ze in `user://keen4/cache/`. Bij de
eerste start zijn alle geluiden na 3 s klaar, het lied van de kaart na 9 s
en alles na 42 s; de tweede start leest alles in 0,5 s. De
PC-speakergeluiden gaan door de gedeelde `SpeakerSynth`, die alleen een
optionele snelheid kreeg (Keen 1 klinkt byte voor byte hetzelfde). Elke
kaart speelt haar eigen lied (de tabel van Omnispeak), de raad en de
conciërge hun eigen lied, het einde het lied van map 7 en het verhaal dat
van map 12; de help en Lindsey zetten de muziek stil. Elk geluid uit het
origineel klinkt op zijn plek, met de prioriteiten van het origineel.
Standaard staan AdLib en muziek aan (nieuwe instellingen); Shift+S kiest
AdLib, PC-speaker of uit en Shift+M zet de muziek aan of uit (in het menu
in D11). In js-dos opgenomen: dezelfde noten en klank, dezelfde volgorde
van de geluiden in demo 0.

- [x] `GalaxyOpl` en de geluids- en muziekformaten, cache, achtergrondtaken.
- [x] Alle geluiden en liedjes op hun plek; prioriteiten.
- [x] Tests van de tester (84): de chip tegen het datasheet, envelopes, formaten, muziek, cache, speler, de wereld; vijf fouten gevonden en opgelost.
- Open: muziek zelf is niet in de testrunner af te spelen (alleen de boekhouding); de absolute snelheid is alleen tegen Omnispeak nagekeken.

## Fix D8.1: wat er nu is

Besloten door de gebruiker op 20-10-2026: Keen 4 tekent nu precies zoals
het origineel. Het origineel heeft van elke sprite maar 1, 2 of 4
verschoven kopieën (staat in de spritetabel) en zet een sprite dus op x
afgerond naar beneden op 8 / shifts pixels; het beeld schuift opzij in
stappen van 2 pixels (de EGA-kaart). Bij ons stond iets tot 7 pixels
opzij en sprong Keen niet bij een deur; nu wel (6 pixels naar links, zoals
het origineel). De regels staan in `docs/keen4/gameplay.md` ("Drawing", "The
camera"), de keuzes in `docs/keen4/architecture.md` ("Deviations in
D8.1"), de vergelijking in `docs/keen4/research.md` ("Watched in D8.1").

- [x] **Sprites op hun stap** (`GalaxyObjectLayer.pixel_of`, `x_step`): 2
  pixels bij 4 shifts (155 sprites), 4 bij 2 (53), 8 bij 1 (189, onder
  andere Keen in een deur). De y blijft de hele pixel.
- [x] **Het beeld in stappen van 2 pixels** (`GalaxyCamera.view_pixels`,
  `PAN_STEP`), in 4:3 en breedbeeld; het scorebord, het DEMO-bord en de
  voorgrondtegels gaan mee zoals bij het origineel.
- [x] **Vloeiende beweging** (F6, standaard uit) blijft zoals hij was:
  sprites tussen de frames op hun precieze plek en het beeld op hele
  pixels (`scroll_pixels`); afronden zou de optie weer schokkerig maken.
- [x] **Het DEMO-bord** stond 3 pixels te hoog (de oorsprong van de sprite
  ontbrak); gevonden met de vergelijking van hele frames, gerepareerd.
- [x] **Naast het origineel** (de opnames van D8, nu hele frames van het
  4:3-beeld pixel voor pixel): demo 1 **100 % gelijk** (662 frames, was
  26 %), demo 0 **91 %** (583 van 639, was 41 %), demo 2 85 %, demo 3 42 %.
  Wat nog verschilt zijn wezens: sterren boven een verdoofd wezen in een
  andere fase, druppels en rupsen, een Bounder en slakken die door hun
  toeval ergens anders lopen. Keen en het beeld zelf zijn in elk frame
  gelijk.
- [x] **De antwoorden van de gebruiker vastgelegd:** in de titellus start
  elke toets een nieuw spel tot de menu's van D10 (Escape = startscherm,
  F1 = help); in Keen 4 staat de hulpregel van Keen 1-3 op Shift+F1 (F1 is
  de help van het origineel).
- [x] **Tests**: `test_galaxy_level` (zelfgemaakte data: x per aantal
  shifts, de sprong bij de deur, het beeld in stappen van 2, breedbeeld en
  vloeiend) en `test_keen4_front_play` (de deur-sprite op de laag, met en
  zonder vloeiende beweging). 91 suites, 995 tests (was 991), alle slagen,
  geen SCRIPT ERROR, gdlint schoon.
- [x] **Regressie** (lege gebruikersmap): Keen 1 en 2 gelijk aan D8; Keen 4
  ook helemaal gelijk aan D8 (de beginbeelden van level 1, 11 en de kaart
  staan al op even pixels, en de intro en help zijn geen levelbeeld).
  Alleen `src/galaxy` en `src/keen4` veranderd, geen gedeelde bestanden.
- **Gezien, niet veranderd:** de wezens lopen in demo 2 en 3 na een tijd
  anders dan in het origineel (hun toeval); een kandidaat om later naar te
  kijken (Omnispeak trekt een toevalsgetal als een wezen buiten beeld gaat).
- **Om te proberen:** `godot --path . -- --game=4`: kijk naar de demo's en
  ga in een spel door een deur (Keen schuift 6 pixels naar links, zoals het
  origineel).
- **Volgende stap: D9**, geluid en muziek (`milestone-d9-geluid`).

## Mijlpaal D8: wat er nu is

Keen 4 is nu van de titel tot de highscores te spelen. Het spel begint met
de titellus van het origineel: de intro-aftiteling (de twee grote woorden
die over elkaar schuiven, de vier namen die omhoog vliegen, het inzoomen en
het titelplaatje dat erin "fizzlet"), demo 0, het verhaal dat in de verte
wegschuift, demo 1, de highscores (demo 4 op map 19 achter de tabel), demo
2 en demo 3, en weer opnieuw. Een toets start een nieuw spel (de menu's
komen in D10), Escape gaat terug naar het startscherm, F1 opent de help.
Na de achtste redding (of de cheat E+N+D) komen de eindpagina's met de
knipperende pijl, daarna typ je je naam op map 19 als je score in de tabel
komt, dan de highscores en weer de titellus. De regels staan in
`docs/keen4/gameplay.md` ("The title loop", "Help", "The end and the high
scores"), de afwijkingen van het plan in `docs/keen4/architecture.md`
("Deviations in D8"), wat het origineel liet zien in
`docs/keen4/research.md` ("Watched in D8").

- [x] **Teksten met opmaak** (`GalaxyTextPages`, `GalaxyPageLayout`): ^P,
  ^E, ^G (y eerst!), ^T met pauze, ^L, ^C, ^B; 18 regels van 10 pixels,
  woorden die passen, ruimte naast plaatjes. Alle help- en eindpagina's die
  we naast het origineel legden: **pixel voor pixel gelijk**.
- [x] **Help (F1)** (`Keen4Help`): het menu met de wijzende hand, vijf
  onderwerpen (ComputerWrist, The Game, The Story, Order Info, About Id),
  bladeren zoals het origineel, "pg 1 of 13" rechtsonder. Gelijk aan het
  origineel (menu en pagina's: 0 pixels verschil). In een spel wacht het
  spel erachter; Shift+F1 is nu de hulpregel van Keen 1-3.
- [x] **Het einde** (`Keen4Ending`): 16 pagina's, de getimede plaatjes met
  de pauzes van het origineel (gemeten: dezelfde), de pijl rechtsonder die
  elke 70 tics knippert; een toets tijdens de plaatjes doet niets. Pagina's
  1, 3 en 16 en de naam typen (met en zonder cursor): 0 pixels verschil.
- [x] **Highscores** (`GalaxyHighScores`, `Keen4HighScoreBoard`): acht
  plaatsen, de standaardtabel uit de EXE (gevonden op vorm: 8 records van
  64 bytes), bij gelijke score wint wie meer raadsleden redde; de tabel op
  map 19 met XOR in het plaatje van de map (0 pixels verschil met het
  origineel), de raadsleden als icoontjes, de naam typen met de knipperende
  cursor; bewaard in `user://keen4/high_scores.json`.
- [x] **Cheats** (`Keen4Cheats`): E+N+D (de achtste redding op de plek
  waar Keen is, dan het einde) en B+A+T (het vak "Cheat Option!", dan de
  vier edelstenen, 99 schoten en een leven).
- [x] **De titellus** (`Keen4TitleLoop`, `Keen4FrontScreen`,
  `GalaxyTitleLayer`): de intro (`GalaxyIntroCredits`,
  `GalaxyIntroBitmap`: de twee woorden uit de misc-chunks), het verhaal
  (`GalaxyStoryScroller`, met een shader; **pixel voor pixel gelijk** aan
  het origineel), het schuiven en inzoomen ook (de eerste naam staat bij het
  origineel 4 pixels verder naar rechts: gecentreerd op hele bytes,
  gerepareerd), de demo's met het vak "DEMO" en het DEMO-bord, de
  highscores. Tijden gemeten: fizzle 1 tic per stap, titel 6,0 s.
- [x] **De vijf demo's** (`GalaxyDemo`, `GalaxyTwoButtonFiring`): kaart en
  invoer uit EGAGRAPH, 3 tics per frame, de vaste toevalstabel vanaf 0,
  "two-button firing", geen extra leven voor punten. **Alle vijf demo's lopen
  frame voor frame gelijk aan het origineel** (Keen gezocht in elk opgenomen
  frame van het origineel en naast onze frames gelegd: sprite en plek gelijk
  tot het eind van elke demo). Er hoefde niets in Keen, de natuurkunde of de
  wezens gerepareerd te worden.
- [x] **Tests**: nieuwe suites `test_galaxy_front` (zelfgemaakte data:
  opmaak, demo-invoer, two-button firing, highscores met gelijke scores,
  opslaan en laden, de standaardtabel op vorm, de intro, het verhaal, de
  volgorde van de titellus, cheats) en `test_keen4_front_play` (echte
  data: de pagina's van de help en het einde, bladeren, de pauzes van het
  einde, de tabel, de vijf demo's, de eerste seconden van demo 0 tegen het
  origineel, het einde tot de naam in de tabel). 91 suites, 991 tests
  (was 89 en 964), alle slagen, geen SCRIPT ERROR, gdlint schoon.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen D7 (lege gebruikersmap): alles gelijk. `git diff
  milestone-d7-kaart` op `src/keen2`, `src/keen3`, hun tests en fixtures,
  `src/actors`, `src/map` en `src/game/level_view.gd` is leeg. Gedeeld
  bestand veranderd: alleen de testlijst (`tests/run_tests.gd`). De Keen
  4-regressie: levels 1 en 11, de kaart en het statusvenster gelijk aan D7;
  nieuw erbij: de intro (breedbeeld en 4:3), het helpmenu en een helppagina.
- [x] **Gerepareerd na de screenshots:** de highscore-stap van de titellus
  bleef hangen (een getypte array uit `[] if … else …`); geen suite speelt
  de flow van de view (die heeft een draaiende scene tree nodig), de
  screenshots van de hele lus vonden het. De tabel blijft nu onder het vak
  van de volgende demo staan, zoals bij het origineel.
- [x] **Bekeken** (scratchpad `d8shots/`): intro, zoom, fizzle, titel,
  het verhaal, elke demo, de highscores, de help, de eindpagina's, de naam
  typen, in 4:3 en breedbeeld.
- **Niet gedaan:** het tekstscherm vooraf (DOS), de menu's (D10), muziek
  (D9). Gezien maar niet veranderd (voor D13): het origineel tekent sprites
  op stappen van 8 / (shifts) pixels (2 pixels voor de meeste, 8 voor Keen
  die een deur in gaat) en scrollt het beeld in stappen van 2 pixels; bij
  ons kan iets 1 tot 7 pixels opzij staan. (Toch gedaan in D8.1.)
- **Om te proberen:** `godot --path . -- --game=4`: kijk naar de intro, het
  verhaal en de demo's; F1 voor de help; een toets voor een nieuw spel; in
  het spel E+N+D tegelijk ingedrukt voor het einde (daarna je naam typen;
  met 0 punten kom je niet in de tabel, speel eerst wat), B+A+T voor de
  edelstenen. Het hele spel van titel tot highscores kan nu, zonder geluid.
- **Volgende stap: D9**, geluid en muziek (`milestone-d9-geluid`): de
  PC-speaker-geluiden en een eigen OPL2-synthesizer voor AdLib en de liedjes.

## Mijlpaal D7: wat er nu is

Keen 4 begint nu op de wereldkaart: Keen loopt in acht richtingen, zwaait
als hij stilstaat, gaat met springen, pogo of schieten een level in (eerst
"One moment", dan het vak "Keen enters …" met Keen die op zijn vingers
aftelt) en komt na het level terug op de plek waar hij erin ging. Gedane
levels krijgen hun vlag (de laatste wordt gegooid), de hekken verdwijnen,
water houdt hem tegen tot hij het wetsuit heeft, Miragia komt en gaat, de
Foot vliegt hem over de kaart. Na een dood komt het vak "Try Again / Exit
to Shadowlands", zonder levens "Game Over!". Enter laat het statusvenster
zakken, in een level en op de kaart. De regels staan in
`docs/keen4/gameplay.md` ("The course of the game (D7)", "The world map",
"Between the levels", "The status window"), de afwijkingen van het plan in
`docs/keen4/architecture.md` ("Deviations in D7"), wat het origineel liet
zien in `docs/keen4/research.md` ("Watched in D7").

- [x] **De kaart-Keen** (`GalaxyMapKeen`, Galaxy; `Keen4MapKeen`): 24 per
  tic op elke as (gemeten: 3 px per frame), de loopbeelden lopen 2, staan,
  lopen 1, staan (gelijk aan het origineel), zwaaien na 360 tics, de
  ingangen 0xC001-0xC012 (alleen met een knop, niet bij gedane levels).
- [x] **Gedane levels** (`Keen4MapSession`, `GalaxyMapFlag`): elk
  info-woord met dat level in de lage byte wordt gewist, 0xD0 haalt het
  hek weg (levels 1 en 2), 0xF0 krijgt een wapperende vlag; de vlag van het
  net gedane level wordt gegooid in een boog (30 punten, 50 tics) en landt
  in de houder (pad gelijk aan het origineel). Map 18 (de Megarocket) is
  een gewoon level zonder vlag: uitlopen = terug, opnieuw in te gaan (zo
  gezien in het origineel).
- [x] **Water**: zonder wetsuit "I can't swim!" en terug; met wetsuit
  zwemt hij (16 per tic, eigen beelden), frame voor frame gelijk aan het
  origineel (twee kleine afwijkingen van Omnispeak overgenomen van het
  origineel).
- [x] **Miragia** (`Keen4Miragia`): 300 tics weg, drie stappen van 30, 300
  tics helemaal, drie stappen terug, gekopieerd uit rij 60 van de kaart;
  blijft weg als Keen op die plek staat. Tijden gelijk aan het origineel.
- [x] **De Foot-vlucht**: na de Foot vliegt Keen naar de Pyramid of the
  Forbidden (vanuit het westen, 280 tics) of terug (140 tics).
- [x] **De vakken tussen de levels** (`Keen4GameBoxes`, `GalaxyScreenQueue`):
  "One moment", "Keen enters …" met de aftellende vingers en de fade, "I
  can't swim!", "Try Again / Exit to Shadowlands" (knipperend kader,
  omhoog/omlaag kiezen), "Game Over!". Alle **pixel voor pixel gelijk** aan
  het origineel ("One moment" staat in het midden en "I can't swim!" 12 px
  omlaag: zo doet het origineel, Omnispeak anders). De laadtijd is vast
  (gemeten: 0,13-0,63 s per vinger in het origineel, hangt af van de schijf).
- [x] **Het statusvenster** (`Keen4StatusWindow`, `GalaxyStatusDrop`):
  locatie, score, extra leven bij, geredde raadsleden, moeilijkheid,
  edelstenen, lading, levens, druppels, wetsuit; zakt in ~0,3 s en gaat
  weer omhoog; met de arm en de band van het origineel. **Pixel voor pixel
  gelijk** aan het origineel.
- [x] **Voortgang** (`Keen4Progress`): gedane levels, plek op de kaart,
  laatste level (voor de gegooide vlag), de Foot, geredde leden, wetsuit;
  ook als dictionary voor het opslaan in D10.
- [x] **Teksten** van het statusvenster en de vakken uit de EXE, gezocht op
  de lengtes van de records (nooit op de woorden).
- [x] **Tests**: nieuwe suites `test_keen4_map`, `test_keen4_map_more`
  (zelfgemaakte kaarten, `keen4_map_fixtures.gd`) en `test_keen4_map_play`
  (echte data: alle 18 ingangen, vlaggen en hekken, Miragia, teksten,
  vakken, statusvenster). 89 suites, 964 tests (was 86 en 942), alle
  slagen, geen SCRIPT ERROR, gdlint schoon. De flow van de view (kaart →
  level → dood → kaart) is met scripted screenshots bekeken; een test
  daarvoor heeft een draaiende scene tree nodig.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen D6 (lege gebruikersmap): alles gelijk. `git diff
  milestone-d6-mechaniek` op `src/keen2`, `src/keen3`, hun tests en
  fixtures, `src/actors`, `src/map` en `src/game/level_view.gd` is leeg.
  Gedeeld bestand veranderd: alleen de testlijst (`tests/run_tests.gd`).
  De Keen 4-regressie: level 1 en 11 gelijk aan D6; nieuw erbij: de
  wereldkaart (breedbeeld en 4:3) en het statusvenster.
- [x] **Bekeken** (scratchpad `d7shots/`): de kaart, "One moment", het
  intrevak met de vingers, de Megarocket, het statusvenster op de kaart en
  in een level, de Foot en de vlucht, de gegooide en wapperende vlag, het
  hek voor en na, "I can't swim!", zwemmen, Miragia, Try Again en Exit, in
  4:3 en breedbeeld.
- **Niet gedaan:** de apps zijn hier niet gebouwd (Mac-build alleen op de
  Mac; voor Windows ontbreken hier de export templates). Geluid (D9), de
  cheat E+N+D (D8). Gezien maar niet veranderd: het origineel tekent
  sprites op even pixels (vier verschuivingen); bij ons kan een sprite een
  pixel opzij staan, ook in de levels (voor D13).
- **Om te proberen:** `godot --path . -- --game=4` (een nieuw spel op de
  kaart: loop met de pijlen, Ctrl op een ingang; de Megarocket ligt vlak
  onder Keen, de Border Village erboven), Enter voor het statusvenster,
  `-- --game=4 --level=14` (snel dood: Try Again / Exit to Shadowlands),
  `--level=9` (het wetsuit; daarna kun je op de kaart zwemmen), `--level=0`
  (meteen de kaart).
- **Volgende stap: D8**, het einde, de titel en de demo's
  (`milestone-d8-einde-titel`).

## Mijlpaal D6: wat er nu is

Platforms varen heen en weer en Keen rijdt mee, schakelaars zetten
keerpunten aan en uit, bruggen schuiven uit, de raadsleden worden gered
met de berichtvakken van het origineel, Lindsey geeft haar hint, het
wetsuit maakt het level af, en in level 17 (de Well of Wishes) zwemt Keen
tussen de Dopefish, scholen vissen, sprites en mijnen. De regels staan in
`docs/keen4/gameplay.md` ("Platforms and switches", "The council,
Lindsey and the wetsuit", "Message windows", "The Well of Wishes"), de
afwijkingen van het plan in `docs/keen4/architecture.md` ("Deviations in
D6"), wat het origineel liet zien in `docs/keen4/research.md` ("Watched
in D6").

- [x] **Platforms** (`GalaxyPlatform`, Galaxy): vier richtingen, 12 per
  tic (gemeten: 52 px per seconde), keren bij een keerpunt (info 31); een
  verticaal platform tussen twee keerpunten die twee tiles uit elkaar
  liggen blijft staan. In Keen 4 met de straalmotortjes eronder of
  erachter (`Keen4Platform`). Keen rijdt mee (de basis van D5); een
  platform dat hem van een paal haalt, zet hem erop.
- [x] **Het vallende platform** (`GalaxyFallingPlatform`): zakt onder
  Keen, valt na een halve tile, stopt boven een keerpunt, stijgt zonder
  Keen terug naar zijn plek.
- [x] **Schakelaars en bruggen**: de schakelaar van D4 zet nu echt een
  keerpunt aan of uit (de platforms reageren meteen); de brug schuift uit
  en in.
- [x] **De raad** (`Keen4Council`): schuifelen en nadenken; staand
  aanraken = gered, level klaar; het bedankje van de oudere, Keens
  antwoord (acht verschillende, op volgorde van het aantal geredde) en
  zijn duim omhoog; in level 17 de "bubbelende" tekst. **De conciërge** in
  level 14: vijf vakken (vier teksten en een vak met alleen Keens boze
  gezicht, zo gezien in het origineel), daarna is hij weg en gaat het
  level door; hij telt niet mee. **Lindsey** (`Keen4Lindsey`): drijft,
  geeft haar hint (level 7: het wetsuit, level 5: de piramide) en
  verdwijnt. **Het wetsuit** (`Keen4Wetsuit`): bericht, level klaar, Keen
  heeft het wetsuit.
- [x] **Berichtvakken in de stijl van het origineel** (`GalaxyWindow`,
  `Keen4Messages`): het venster van 26 × 8 vakjes met de randtiles, het
  menulettertype en de plaatjes (de laatste van het plaatjesbereik, in
  1.0 en 1.4 gelijk). Alle vakken (raad, conciërge, Lindsey, wetsuit)
  zijn **pixel voor pixel gelijk** aan het origineel. Het spel staat stil
  tot een toets; F1-F6 blijven werken; in breedbeeld midden in beeld.
- [x] **Voortgang** (`Keen4Progress`): het aantal geredde raadsleden, het
  wetsuit en de gedane levels, klaar voor de kaart (D7) en het einde
  (D8). Gekozen voor nu: na de achtste redding een melding "All eight
  council members are rescued" en gewoon het volgende level.
- [x] **Level 17 onder water** (`Keen4SwimmingKeen`): eigen acties,
  eenvoudige botsing, elke 8e tic remmen naar langzaam zinken (gemeten:
  20 px per seconde, zoals Omnispeak), de stick, de trap (18), belletjes,
  geen verdover; de kaartcamera. De **Dopefish** eet Keen (en scholen
  vissen) en boert; **scholen vissen** volgen Keen; **sprites** dobberen,
  mikken en schieten; **mijnen** varen als platforms en ontploffen.
- [x] **Volgorde zonder kaart**: na level 16 komt 17, na 17 weer 1; een
  redding of het wetsuit opent het volgende level.
- [x] **Tests**: nieuwe suites `test_keen4_platforms`, `test_keen4_people`,
  `test_keen4_water` (mini-levels) en `test_keen4_d6_play` (echte data:
  elke info-waarde in level 1-17 maakt iets, alleen de kaartwaarden 3 en
  33 blijven voor D7; level 17 wordt gezwommen; de teksten per
  reddingsnummer en per level; de vensterplaats; de view compileert).
  86 suites, 942 tests (was 82 en 901), alle slagen, geen SCRIPT ERROR,
  gdlint schoon.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen D5 (lege gebruikersmap): alles gelijk. `git diff
  milestone-d5-vijanden` op `src/keen2`, `src/keen3`, hun tests en
  fixtures, `src/actors`, `src/map` en `src/game/level_view.gd` is leeg.
  Gedeeld bestand veranderd: alleen de testlijst (`tests/run_tests.gd`).
  De Keen 4-regressie is gelijk aan D5 (in het eerste beeld van level 1
  en 11 staat niets van D6).
- [x] **Bekeken** (scratchpad `d6shots/`): Keen op een platform, het
  vallende platform, schakelaar en brug voor en na, de vakken van de raad,
  de conciërge, Lindsey en het wetsuit, level 17 met de Dopefish, vissen
  en mijnen, in 4:3 en breedbeeld.
- **Niet gedaan:** de apps zijn hier niet gebouwd (Mac-build alleen op de
  Mac; voor Windows ontbreken hier de export templates). In het origineel
  niet gemeten (blijft Omnispeak): het vallende platform, het effect van
  een schakelaar op een platform, het keren van een horizontaal platform,
  de Dopefish, de sprites en mijnen onder water.
- **Om te proberen:** `godot --path . -- --game=4 --level=3` (een
  raadslid), `--level=14` (de conciërge), `--level=7` (Lindsey),
  `--level=9` (het wetsuit, en platforms vlak bij de start), `--level=8`
  (platforms, schakelaars en de brug), `--level=17` (zwemmen: pijlen om te
  sturen, springen om te trappen; de Dopefish zit rechts). Shift+G zet
  god mode aan of uit.
- **Volgende stap: D7**, de wereldkaart (`milestone-d7-kaart`).

## Mijlpaal D5: wat er nu is

Alle wezens die op het land leven lopen, springen, vliegen en schieten in
de levels van Keen 4; de verdover verdooft ze (met sterretjes) of doet
niets, zoals in het origineel. De regels staan in `docs/keen4/gameplay.md`
("The creatures", "The stun", "Difficulty"), de afwijkingen van het plan in
`docs/keen4/architecture.md` ("Deviations in D5"), wat het origineel liet
zien in `docs/keen4/research.md` ("Watched in D5").

- [x] **Een basis voor wezens** (`GalaxyCreature`, Galaxy): eigen
  actietabel per wezen, de verdoving (sprongetje −24, hoogstens −48), de
  sterretjes (drie beelden van 10 tics, per soort op een eigen plek), lopen
  en omkeren bij muren en randen, vallen; `GalaxyEnemyShot` (dodelijk
  schot, weg bij een muur), `GalaxyDifficulty` (Easy/Normal/Hard).
- [x] **Vijftien soorten** (`src/keen4/actors/`, elk een eigen klasse met
  de getallen van Omnispeak): slak met slijm, Mad Mushroom, ei en vogel
  (uitkomen, lopen, vliegen als Keen hoog staat, landen), Arachnut,
  Skypest (alleen dood door de pogo als hij op de grond zit), Wormmouth,
  wolk met bliksem, Berkeloid met vuurbal die brandt, Lick, Mimrock,
  Bounder, Smirky (eet items en item-tiles, teleporteert), inchworms en de
  Foot (11 wormen tegen elkaar → de Foot; de Foot aanraken = level klaar,
  de vlucht komt in D7), dart guns in vier richtingen.
- [x] **Meerijden**: Keen landt op een Bounder (of een verdoofde) en rijdt
  mee; op een levende Bounder stuurt hij (links, rechts of recht omhoog).
  Een Bounder duwt Keen opzij en stoot hem van een paal. Dit is meteen de
  basis voor de platforms van D6.
- [x] **Moeilijkheidsgraad**: de info-waarden per graad
  (`Keen4Creatures`), als parameter van de sessie; voorlopig Normal (het
  menu komt in D10).
- [x] **Naast het origineel (js-dos)**, met een kopie van `GAMEMAPS` in de
  scratchpad waarin een wezen bij de start staat: Bounder (39 px, 24
  opzij), paddenstoel (twee hopjes van 31 px, dan een grote sprong),
  ei op Normal (dus geen vogel; research §12 punt 5 opgelost), vogel (8 px
  per 7 tics), Arachnut (128 per 6 tics), Skypest (poetsen 10 tics per
  beeld, rust 100), Lick (vlam 4 tics per beeld), Berkeloid (vuurbal 48
  opzij), Mimrock (sluipt als Keen wegkijkt): allemaal zoals Omnispeak.
  Het teleporteren van Smirky is niet gezien (punt 4 blijft open).
- [x] **Tests**: nieuwe suites `test_galaxy_creatures`,
  `test_keen4_creatures`, `test_keen4_creatures_more` (mini-levels,
  `keen4_creature_fixtures.gd`) en `test_keen4_creatures_play` (echte
  data: elke info-waarde in level 1-16 is bekend, level 1 per graad, elk
  level loopt met zijn wezens). 82 suites, 901 tests (was 78 en 870), alle
  slagen, gdlint schoon.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen D4 (lege gebruikersmap): alles gelijk. `git diff
  milestone-d4-keen` op `src/keen2`, `src/keen3`, hun tests en fixtures,
  `src/actors`, `src/map` en `src/game/level_view.gd` is leeg. Gedeeld
  bestand veranderd: alleen de testlijst (`tests/run_tests.gd`). De Keen
  4-regressie verschilt alleen in level 1: de Bounder links in beeld
  (level 11 heeft geen wezen in het eerste beeld).
- [x] **Bekeken** (scratchpad `d5shots/`): elk wezen in zijn level, actief
  en na een schot (verdoofd met sterretjes, of niets), in 4:3 en
  breedbeeld.
- **Niet gedaan:** de apps zijn hier niet gebouwd (Mac-build alleen op de
  Mac; voor Windows ontbreken hier de export templates). In het origineel
  nog niet gezien: het slijm van de slak, Wormmouth, wolk, inchworms en de
  Foot, dart guns, het teleporteren van Smirky (open voor D13).
- **Om te proberen:** `godot --path . -- --game=4` (level 1: de Bounders
  links; spring erop en laat je meevoeren, ga links of rechts staan om te
  sturen; schiet er een met Spatie: dan staat hij stil en kun je erop
  staan), `--level=2` (paddenstoel en slakken), `--level=14` (Licks bij de
  start), `--level=11` (dart guns, inchworms). Shift+G zet god mode aan of
  uit om rustig te kijken.
- **Volgende stap: D6**, platforms, schakelaars, de raad en onder water
  (`milestone-d6-mechaniek`).

## Mijlpaal D4: wat er nu is

Keen loopt, springt, pogot, klimt, hangt aan randen, schiet, gaat door
deuren en pakt items in elk level van Keen 4 (nog zonder vijanden). Het
scorebord staat linksboven. De regels staan in `docs/keen4/gameplay.md`
("Keen's moves", "Items and tiles", "The score box"), de afwijkingen van
het plan in `docs/keen4/architecture.md` ("Deviations in D4"), wat het
origineel liet zien in `docs/keen4/research.md` ("Watched in D4").

- [x] **Het actiesysteem** (`GalaxyAction`, `GalaxyObject`, `GalaxyWorld`):
  elke toestand een regel tekst (sprites, soort, protect, aan de grond
  plakken, timer, snelheid, think/contact/react als methodenaam, volgende),
  wakker worden en slapen, beide contact-functies, de volgorde van een
  frame zoals het origineel.
- [x] **Botsen met tiles** (`GalaxyClip`): vloeren en hellingen onder de
  middenkolom (Omnispeaks hoogtetabel), muren links en rechts, plafonds,
  paalgaten, de grens per frame (239/255), het "eenvoudige" vak voor later;
  zwaartekracht en versnellen op oneven tics (`GalaxyPhysics`).
- [x] **Keen** (`GalaxyKeen`, in drie bestanden): staan met de
  wachtanimaties (omhoog kijken, verveeld, de maan, het boek), lopen (ook
  op hellingen), omhoog/omlaag kijken, door een dunne vloer zakken,
  springen, vallen, pogo, schieten in alle richtingen (ook aan een paal en
  omlaag in de lucht), palen (pakken, klimmen 8, glijden 24, afspringen),
  randen (hangen, optrekken, loslaten), deuren (naar het doel in de
  info-laag), schakelaars en bruggen, dood (dodelijke tiles en uit het
  level vallen) met de doodsanimatie.
- [x] **Items en tiles**: punten (sprites en tiles, met de "schaduw" die
  opstijgt), edelstenen, extra leven, lading (+5), druppels (100 = een
  leven), extra leven bij 20.000 en dan steeds het dubbele, edelsteenhouders
  en de deur die in drie stappen opengaat. De verdover: 64 per tic, 4
  beelden, stopt tegen muren, gaat door paalgaten, kost een lading.
- [x] **Het scorebord** (`GalaxyScoreBox`): de eigen sprite van het spel
  met de cijfers erin zoals het origineel, linksboven in het zichtbare
  beeld, in 4:3 en breedbeeld.
- [x] **Het verloop** (`Keen4LevelSession`, `Keen4Inventory`, `Keen4View`):
  de camera volgt Keen met de regels uit D3; uit het level lopen → het
  volgende level (1-16, daarna weer 1); dood → het level opnieuw (een leven
  minder); geen levens meer → startscherm. De kaart (0) en level 17
  (zwemmen) blijven nog "rondkijken".
- [x] **Naast het origineel (js-dos)**: de sprong is 67 px (niet 70: het
  eerste frame van een level duurt 3 tics, daarna begint elk frame op een
  oneven tic), de pogo vastgehouden 105 px en los 41 px, lopen 24 per tic,
  heuvelop 20, paal klimmen 8 en glijden 24, de deur naar de juiste kamer,
  het scorebord gelijk. Onze getallen zijn daarop gezet.
- [x] **Tests**: nieuwe suites `test_galaxy_actions`, `test_galaxy_keen`,
  `test_galaxy_items` (zelfgemaakte mini-levels, `galaxy_keen_fixtures.gd`)
  en `test_keen4_play` (echte data: alle levels, de sprong, de deur in
  level 1, items, scorebord). 78 suites, 870 tests (was 74 en 836), alle
  slagen, gdlint schoon.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen D3 (lege gebruikersmap): alles gelijk. `git diff
  milestone-d3-level` op `src/keen2`, `src/keen3`, hun tests en fixtures,
  `src/actors`, `src/map` en `src/game/level_view.gd` is leeg. Gedeeld
  bestand veranderd: alleen de testlijst (`tests/run_tests.gd`). De Keen
  4-regressie verschilt alleen in het scorebord (bekeken).
- [x] **Bekeken** (scratchpad `d4shots/`): lopen, helling, sprong, pogo,
  deur, paal, rand (level 4), edelsteendeur (level 4), items, scorebord, in
  4:3 en breedbeeld, met xBRZ en vloeiende beweging.
- **Niet gedaan:** de apps zijn hier niet gebouwd (Mac-build alleen op de
  Mac; voor Windows ontbreken hier de export templates). In het origineel
  nog niet nagemeten: het hangen aan een rand, de edelsteendeur, de
  wachtanimaties (open voor D13).
- **Om te proberen:** `godot --path . -- --game=4` (level 1: naar links
  lopen, de heuvel op, springen met Ctrl, pogo met Alt, schieten met
  Spatie; de deur van het linker huis met pijl omhoog leidt naar de kamer
  met de paal), `-- --game=4 --level=4` (randen, edelstenen en de deur),
  F5 (xBRZ), F6 (vloeiende beweging), F2 (breedbeeld).
- **Volgende stap: D5**, vijanden (`milestone-d5-vijanden`).

## Mijlpaal D3: wat er nu is

Elke map van Keen 4 staat op het scherm zoals in het origineel, met Keen
die stilstaat op zijn startplek; je kunt rondkijken. Bewegen komt in D4.
De regels staan in het nieuwe `docs/keen4/gameplay.md`, de afwijkingen
van het plan in `docs/keen4/architecture.md` ("Deviations in D3"), wat het
origineel liet zien in `docs/keen4/research.md` ("Watched in D3").

- [x] **Drie tile-lagen** (`GalaxyLevelMap`): achtergrond, voorgrond
  achter de sprites, en voorgrond vóór de sprites, alleen waar
  `TILEINFO` bit 0x80 dat zegt. Eén `set_tile` voor tiles die veranderen
  (kaart, scherm en animatie samen). Een atlas per tileset en per level
  met alleen de tiles die het level kan tonen (`GalaxyTileAtlas`).
- [x] **Bewegende tiles** (`GalaxyTileAnimator`) met de tijden uit
  `TILEINFO` in tics van 1/70 s, achter en voor, op de klok van het
  origineel (`GalaxyClock`: 2 tics per logisch frame, 35 per seconde).
- [x] **Sprites** (`GalaxyObjectLayer`) op positie + oorsprong, op hele
  pixels of met vloeiende beweging (`Interpolation`), in de volgorde van
  de prioriteiten (0-2 onder de tiles vóór, 3 erboven).
- [x] **Keen op zijn start** (`Keen4Start`): info 1/2 staand naar
  rechts/links (y = tile × 256 − 241), op de kaart de kaart-Keen, in level
  17 de zwemmende Keen.
- [x] **De camera van het origineel** (`GalaxyCamera`): de rand van 2
  tiles, de scroll-blokken (info 26 een kolom, info 25 een rij), het eerste
  beeld (Keen 152 px van links, voeten 140 px van boven) en het volgen
  (Keen tussen 144-192 px, voeten tussen 33 en 167 px) voor D4.
- [x] **Breedbeeld**: het brede beeld blijft tussen de scroll-blokken; wat
  daarbuiten zou komen wordt afgedekt (zwart, of het plaatje achter het
  level) met `GalaxyViewCover`. In 4:3 is het beeld precies het origineel.
- [x] **xBRZ** (F5) via `GalaxyScaledGraphics` met de gedeelde
  `XbrzScaler`, op de achtergrond per level (~0,6 s), daarna bewaard.
- [x] **Plaatjes achter de levels** (breedbeeld, `GalaxyBackdropPictures`):
  alleen waar de bovenste rij van het level lucht is (de effen lichtblauwe
  tiles): levels 5, 7-14 en 16. Map `assets/backgrounds/keen4` (nog leeg)
  en `game_data/keen4/backgrounds` van de speler.
- [x] **Rondkijken**: pijltjes/WASD verplaatsen het punt waar Keen zou
  staan; het beeld volgt met de regels van het origineel (dus nooit voorbij
  een scroll-blok). Shift+N/P: volgende/vorige map. Escape: terug naar het
  startscherm. Zonder `--level` opent level 1 (het "coming soon"-scherm is
  weg).
- [x] **Naast het origineel (js-dos, headless)**: het eerste beeld van
  levels 1, 4, 11, 14, 17 en van de wereldkaart is pixel voor pixel gelijk
  (tiles van alle drie lagen, camera, Keen); alleen het scorebord (D4), de
  vijanden (D5) en de stand van de animaties verschillen. De animatietijden
  gemeten: druppels 114 ms (8 tics), ogen 571/2855 ms, boom 286 ms: precies
  `TILEINFO`.
- [x] **Tests**: nieuwe suites `test_galaxy_level` (zelfgemaakte data:
  klok, animatie, lagen, atlas, camera met blokken, breedbeeld, volgorde,
  lucht) en `test_keen4_level` (echte data: start in alle 20 maps, het
  eerste beeld van level 1, blokken, tiles, lucht-levels). 74 suites, 836
  tests (was 72 en 816), alle slagen, gdlint schoon.
  `tools/keen4_regression.sh`: level 1 en 11 in 4:3 en breedbeeld.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen D2 (lege gebruikersmap): alles gelijk, ook `launcher.png`.
  `git diff milestone-d2-bestanden` op `src/keen2`, `src/keen3`, hun tests
  en fixtures, `src/actors`, `src/map` en `src/game/level_view.gd` is leeg.
  Gedeeld bestand veranderd: alleen de testlijst (`tests/run_tests.gd`).
- [x] **Bekeken** (scratchpad `d3shots/`): alle 20 maps in 4:3 en
  breedbeeld, met en zonder xBRZ; tiles vóór Keen, bewegende tiles,
  scroll-blokken, afdekken in breedbeeld, en een testplaatje achter de
  lucht-levels (niet gecommit).
- **Niet gedaan:** de apps zijn hier niet gebouwd (Mac-build alleen op de
  Mac; voor Windows ontbreken hier de export templates).
- **Om te proberen:** `godot --path . -- --game=4` (level 1),
  `-- --game=4 --level=18` (smal: breedbeeld afgedekt), `--level=4` en
  `--level=14` (scroll-blokken; rondkijken met de pijltjes), Shift+N door
  alle maps, F2 (breedbeeld), F5 (xBRZ), en een eigen plaatje als
  `game_data/keen4/backgrounds/level07.png`.
- **Volgende stap: D4**, Keen beweegt (acties, hellingen, palen, randen,
  de camera die hem volgt, het scorebord).

## Mijlpaal D2: wat er nu is

Alle bestanden van Keen 4 worden gelezen, met de eigen Keen 4 v1.0 van de
gebruiker nagekeken. Er beweegt nog niets. De bestanden staan in
`docs/keen4/file-formats.md` (met "D2" waar de code iets leerde), de
afwijkingen van het plan in `docs/keen4/architecture.md`, "Deviations in D2".

- [x] **De Galaxy-lezers** (`src/galaxy/data/`, ook voor Keen 5 en 6; de
  getallen van een deel komen uit een `GalaxyEpisode`): Huffman, Carmack,
  RLEW met eigen tag, de chunks van EGAGRAPH, plaatjes, gemaskeerde
  plaatjes, sprites met oorsprong en hitbox (`GalaxySpriteInfo`), 8×8- en
  16×16-tiles (achter en voor, met masker), de drie lettertypen, de
  teksten, de demo's, de maps met drie lagen (`GalaxyMapFile`,
  `GalaxyMap`), `GalaxyTileInfo` en de geluids-chunks als bytes
  (`GalaxyAudioFile`). Keen 4 zelf: `Keen4Files` en `Keen4Episode`.
- [x] **Alles op inhoud gezocht** in `KEEN4E.EXE` (`GalaxyHeaderSearch`,
  `GalaxyHeaders`): de zes headers, eerst op de plekken van 1.0 en 1.4,
  daarna in het hele programma (dan ~0,2 s); losse header-bestanden naast
  het spel gaan voor. In 1.0 gevonden waar de architect ze zag
  (AUDIOHED 0x1FB80 met het blok onzin-offsets 104-155, EGAHEAD 0x1FE10,
  MAPHEAD 0x235B0, TILEINFO 0x23742, AUDIODCT 0x33FF6, EGADICT 0x343F6).
  De versie uit het opstartscherm ("(v1.0)": letter en kleur om en om),
  anders uit de grootte.
- [x] **Nooit vaste chunknummers**: het aantal plaatjes, sprites enz. komt
  uit de tabellen; de grens tussen achter- en voorgrond-tiles uit de data
  zelf (een achtergrond-tile past niet in 160 bytes). 1.0: 107 plaatjes,
  3 gemaskeerd, 397 sprites, 104 + 20 kleine tiles, 1296 + 2916 tiles, 20
  maps die allemaal uitpakken.
- [x] **Teksten op vorm gevonden** (nooit op woorden): de 19 levelnamen,
  de 19 "Keen enters …"-teksten, de conciërge, en de berichten van de
  raad, Lindsey en het wetsuit (17 stuks); ook de tabel met willekeurige
  getallen. Nog niet: statusvenster, menu's, "Try Again", highscores (die
  zoeken de mijlpalen die ze nodig hebben op dezelfde manier).
- [x] **Kleuren en masker nagekeken** met screenshots: de vlakken staan in
  de volgorde blauw, groen, rood, intensiteit; bij sprites, gemaskeerde
  plaatjes en voorgrond-tiles komt het masker eerst. De hitbox geldt
  vanaf de plek van het object, het plaatje staat op plek + oorsprong.
- [x] **Snelheid**: laden (EXE uitpakken, headers, bereiken) ~70 ms, één
  sprite voor het icoon < 1 ms, heel EGAGRAPH ~1 s, alle maps ~45 ms.
  Alles wordt pas uitgepakt als het nodig is; geen thread nodig.
- [x] **Het startscherm heeft vier iconen**: "Keen 4" met Keen uit de eigen
  sprites en de naam in het eigen lettertype van Keen 4 (via
  `icon_picture` en `icon_title`); zonder bestanden grijs met uitleg. Met
  bestanden opent het "Keen 4 - coming soon" (Enter of Escape terug).
  Vier iconen passen (tot 800 van 1280 px).
- [x] **`--game=4`** (ook met `--level=N`, dan staat de levelnaam erbij),
  de data viewer (`-- --game=4`: maps met de drie lagen aan/uit en de
  waarden onder de muis, beide tilesets, sprites met hitbox en oorsprong,
  plaatjes, lettertypen en kleine tiles, wat er in het programma
  gevonden is) en `tools/export_graphics.gd -- --game=4` (naar
  `exported/keen4/`). Bouwscripts nemen `game_data/keen4` mee;
  `game_data/README.md` heeft een stukje over Keen 4.
- [x] **Tests**: nieuwe suites `test_galaxy_data` (decoders, de zoektochten
  met de headers op andere plekken, het AUDIOHED-gat, de versie, teksten),
  `test_galaxy_files` (wat de lezers van zelfgemaakte bestanden maken) en
  `test_keen4_data` (echte data: versie, plekken, aantallen, alle maps,
  map 0, tileinfo, demo's, geluid); zelfgemaakte data in
  `tests/galaxy_fixtures.gd` en `tests/galaxy_file_fixtures.gd`. 72
  suites, 816 tests (was 69 en 778), alle slagen, gdlint schoon.
- [x] **Keen 1-3-controle:** `keen1_regression.sh` en `keen2_regression.sh`
  tegen de referentie van `main` (lege gebruikersmap): alles gelijk
  behalve `launcher.png`, en dat verschilt alleen binnen het vierde icoon.
  `git diff milestone-d1-onderzoek` op `src/keen2`, `src/keen3`, hun tests
  en fixtures, `src/actors`, `src/map` en `src/game/level_view.gd`: alleen
  de regels met het aantal spellen (3 → 4). Gedeelde code alleen
  aangevuld: `GameCatalog` (vierde spel, `icon_picture`, `icon_title`),
  `GameIcon.title_picture`, `Launcher._make_icon`, `GameLaunch` (`--game=4`),
  de data viewer, `export_graphics.gd`, de bouwscripts, de testlijst.
- **Niet gedaan:** de apps zijn hier niet gebouwd (de Mac-build kan alleen
  op de Mac; voor Windows ontbreken hier de export templates).
- **Om te proberen:** het startscherm (vierde icoon, klikken, Escape
  terug); de data viewer met `godot --path . res://src/viewer/data_viewer.tscn -- --game=4`;
  `godot --path . -- --game=4 --level=13`.
- **Volgende stap: D3**, een level tekenen (`Keen4View` met drie
  tile-lagen, animatie uit `TILEINFO`, de camera met scroll-blokken).

## Mijlpaal D1: wat er nu is

- **Onderzoek in `docs/keen4/`** (19-10-2026), alleen documenten, geen code.
  Een developer-agent bracht de code in kaart (wat Keen 4 kan gebruiken:
  startscherm, menu's, instellingen, opslaan, xBRZ, `Interpolation`,
  online-transport, split-screen, tools; wat Vorticons-specifiek is:
  decoders, `LevelMap`, `KeenBody`, `LevelCollision`, actoren, kaart,
  `GameWindow`, `Hud`), een onderzoeksagent las Omnispeak en de
  Galaxy-code van Commander Genius.
- **De Keen 4 van de gebruiker is versie 1.0** (geüpload 19-10-2026;
  Omnispeak en Commander Genius kennen 1.4). De EXE is LZEXE-ingepakt;
  alle zes headers (`AUDIOHED`, `EGAHEAD`, `MAPHEAD`, `TILEINFO`,
  `AUDIODCT`, `EGADICT`) zijn **op inhoud** gevonden. 1.0 heeft 107
  plaatjes (1.4: 115), dus alle chunknummers daarna verschillen: nooit
  vaste chunknummers. 397 sprites, 1296 + 2916 tiles, 20 maps die alle
  goed uitpakken, de tileinfo-volgorde nagekeken.
- **Besluiten van de gebruiker (19-10-2026):** Omnispeak-getallen mogen
  (`(Omni)`), de gereconstrueerde broncode niet; 35 logische frames per
  seconde zoals het origineel; in breedbeeld wordt wat achter een
  scroll-blok ligt afgedekt; het scorebord is de HUD; een eigen
  OPL2-synthesizer in GDScript met cache, AdLib en muziek standaard aan;
  omhoog/omlaag voor twee spelers; Paddle War en de demo's wel,
  Real-ESRGAN niet; D2 pas als Keen 3 op `main` staat (20-10-2026: zo).
- **Vragen aan de gebruiker gaan altijd als keuzemenu** (wens van de
  gebruiker, 19-10-2026; nu ook in `CLAUDE.md`).

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

### Fix na C11 (20-10): lift, achtergronden, level 10

Drie bugs die de gebruiker vond, op dezelfde branch.
- [x] **Springen van een lift:** Keen werd naar het eind van de lift
  gegooid. Oorzaak: Keen gaat pas de tick ná de sprong omhoog, maar een
  lift die omhoog gaat (of de bal) schoof in die tick al in zijn voeten;
  omdat hij al "stijgend" was gold dat als een botsing van opzij.
  `Keen3Carrier` zet een stijgende Keen nu op de lift zolang die alleen in
  zijn voeten omhoog kwam, zonder hem opzij te schuiven. Nieuwe suite
  `test_keen3_lift_jump` (beide platforms beide kanten op, de bal; links,
  midden, rechts; springen, kort springen, pogo; terug landen; tegen de
  zijkant lopen duwt nog wel). Ook met de echte levels nagelopen (elke
  lift en bal, 900 sprongen): van 198 naar 13 met een zijstap, en die 13
  komen niet van het afspringen: een tweede bal of iets anders dat tegen
  hem aan komt, een bal die echt van opzij komt, of Keen klem tussen een
  plafond en een bal (1-2 px, was al zo; open punt).
- [x] **Achtergronden:** levels 4 en 5: de stad staat nu op een vlakte
  die doorloopt tot de heuvels; level 2: de verre stad loopt door achter
  de nabije; levels 1, 6 en 7: koepels, huisjes en het fort staan op de
  laagste grond eronder. Level 14 is helemaal nieuw (noorderlicht boven
  een bevroren zee, ijsbergen, een planeet met ring, een wachttoren met
  zoeklicht). De tekenhulp staat nu in `tools/background_painter.py` (sinds D11 gedeeld met Keen 4). 3, 8, 11,
  13 en 15 zweefden niet en zijn niet veranderd.
- [x] **Level 10 (en 9) een plaatje:** een level krijgt nu een plaatje
  als het lucht heeft, en het plaatje komt alleen door de lucht (tile
  143), nooit door het donkergrijs van een basis (`Keen3SceneScreen`
  kiest de kleur van de lucht). Level 9 heeft ook lucht boven zijn basis
  en kreeg er ook een; 12 en 16 hebben geen lucht. Nieuwe plaatjes: level
  9 een groene ochtend met kliffen en watervallen, level 10 een vlakte met
  een raket op een lanceertoren. Gecontroleerd met screenshots: de basis
  blijft grijs.
- [x] **Tests:** 67 suites, alle slagen, gdlint schoon. In
  `test_keen3_extras` was de oude verwachting de bug (levels 9 en 10 geen
  plaatje; de basis met lucht "past niet"); aangepast. Keen 1- en
  Keen 2-controle tegen `9fa77d0`: alles gelijk; geen gedeelde code
  veranderd (alleen de testlijst).

### Fix na C11 (20-10): schot door de muur

Bug van de gebruiker, op dezelfde branch.
- [x] **Oorzaak:** Keens schot begint vlak vóór hem
  (`KeenBody.shot_position`). Staat hij minder dan 16 px van een muur, dan
  begint het schot al ín de muur, en de zijwaartse sweep kijkt alleen naar
  de tiles vóór het schot: in een dikke muur spatte het in de muur, door
  een dunne muur (één rotsblok) vloog het gewoon verder. Nagebootst in
  level 1 (Keen tegen een rotsblok: het schot vloog erachter verder).
- [x] **Oplossing (alleen Keen 3-code):** `Keen3Shot.fired_by_keen` (via
  `Keen3LevelSession._create_shot`) veegt het schot van Keens midden naar
  zijn begin; zit er een muur tussen, dan komt het schot tegen de voorkant
  van de muur en spat het meteen (KEENFIRE, dan SHOTHIT), zoals in het
  origineel (Choco). Staand, springend en op de pogo, beide kanten op.
- [x] **Vijandschoten nagelopen:** de vuurbal van de moeder begint binnen
  haar box en spatte al als hij in een muur begint; het schot van een
  wapen in de muur begint in zijn eigen cel (zo bedoeld); de golf van de
  Meep gaat bewust door muren. Niets veranderd.
- [x] **Keen 1 en 2 hebben dezelfde bug** (gedeelde `RaygunShot`): met
  dezelfde zelfgemaakte test (alleen in de scratchpad) vliegt het schot
  door een dunne muur en spat het in een dikke muur, in 60 van de 66
  gevallen per muur. **Niet opgelost**: vraag voor de gebruiker (past bij
  C12).
- [x] **Tests:** nieuwe suite `test_keen3_shot_wall` (faalt op de oude
  code: 120 gevallen); 68 suites, alle slagen, gdlint schoon. Keen 1- en
  Keen 2-controle tegen `cd8be97`: alles gelijk; geen gedeelde code
  veranderd (alleen de testlijst). Apps opnieuw gebouwd.
- [x] **Keen 2 nu ook opgelost** (gevraagd door de gebruiker, 20-10): de
  regel staat in Keen 2-code, `Keen2Shot.put_against_wall` (veegt het schot
  van het midden van de schutter naar zijn begin), en Keen 3 gebruikt
  dezelfde helper (gedrag gelijk). Keen 2: Keens schot via
  `Keen2Shot.fired_by_keen` (`Keen2LevelSession._create_shot`); ook de
  schoten van de Elite en de Guard robot hadden de bug (vlak bij een muur
  vloog het schot door een dunne muur) en gaan nu via
  `Keen2EnemyShot.fired_from`. Nieuwe suite `test_keen2_shot_wall` (faalt
  op de oude code: 172 gevallen); 69 suites, alle slagen, gdlint schoon.
  Keen 1- en Keen 2-controle tegen `fea79ad`: alles gelijk; geen gedeelde
  code veranderd. Apps opnieuw gebouwd.
- [ ] **Keen 1 heeft de bug nog** (`RaygunShot`, niet gevraagd): open vraag
  voor C12.

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

Realistische graphics (R):

1. R2 (branch `milestone-r2-realistisch-optie`): de optie REALISTIC (F8)
   en de sfeerlaag in alle vijf de spellen; vragen van R1 beantwoord op
   24-10 (zie het blok "Realistische graphics" hierboven).
2. Daarna R3 (licht), R4 (achtergronden) en de SDXL-proef R5 met de
   originele plaatjes.

Achtergronden Keen 1 en 2:

1. **Voor de gebruiker:** bouwen vanaf `milestone-a-b-backgrounds` en
   Keen 1 en 2 in breedbeeld spelen: past elke wand en lucht bij zijn
   level? Zeg wat beter kan (een eigen textuur proberen kan zonder bouwen:
   `game_data/keen2/backgrounds/wallNN.png`).
2. Daarna kan `milestone-a-b-backgrounds` in één keer naar `main`.

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
   met naaminvoer (alle drie). **Vraag aan de gebruiker:** het schot dat
   vlak bij een muur door die muur gaat (in Keen 3 en Keen 2 opgelost na
   C11) zit nog in Keen 1; daar ook oplossen (in C12, met
   `Keen2Shot.put_against_wall`)?
11. Later: Eigen achtergrondplaatjes voor Keen 1 en Keen 2, later in een
   eigen branch (wens van de gebruiker, 19-10-2026).


Keen 4:

1. **Voor de gebruiker:** de fixes van D13.2 proberen in `build/` (bouw
   vanaf `milestone-d13.2-fixes`): kijken met twee spelers in split
   screen, stilstand in pauzes (vloeiende beweging aan), Shift+G en
   Shift+I in een level en op de kaart, Configure > Online Game, en
   level 9 (Miragia) met plaatjes aan (ook de lucht boven de lage richel
   bij de slak), en in breedbeeld of er nog iets aan de rand opduikt.
   Daarna verder Keen 4 helemaal
   spelen: ook online en met de bestanden van 1.4 als je die hebt.
2. `milestone-d13.2-fixes` (bevat D13.1) kan in één keer naar `main`.
3. Eventueel later: de open punten van D13 (de plaatjes van het optrekken
   aan een richel, de Dopefish-beet, de Foot, Smirky's teleport).
4. Daarna Keen 5 en 6 (zelfde Galaxy-engine; zie de lessen in
   `docs/keen4/research.md`).

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
