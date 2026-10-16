# Roadmap Keen 2

De mijlpalen voor het tweede deel ("The Earth Explodes"). De actuele status
staat in [PROGRESS.md](../../PROGRESS.md). Hoe Keen 2 naast Keen 1 komt te
staan, staat in [architecture.md](architecture.md). Wat er over het spel
bekend is, staat in [research.md](research.md).

Afspraken:

- Elke mijlpaal heeft een branch `milestone-b<n>-<onderwerp>`, vanaf `main`.
- **Keen 1 blijft zoals het is.** Elke mijlpaal eindigt met de controle uit
  [architecture.md](architecture.md): alle bestaande tests slagen zonder dat
  ze zijn aangepast, `gdlint` is schoon, gescript spelen van Keen 1 geeft
  dezelfde screenshots, en de Keen 1-bestanden zijn niet veranderd.
- De architect schrijft per mijlpaal de opdracht (hieronder). De developer
  bouwt die, met tests, en werkt `PROGRESS.md` bij. De architect controleert
  daarna de diff tegen de opdracht en de regels.
- Keen 2 is geen shareware. Testen met echte data kan alleen met de eigen
  bestanden van de gebruiker (op de Mac, of geüpload in een cloud-sessie).
  Alles wat zonder data kan, wordt met zelfgemaakte testlevels getest.
- Extra's zijn standaard uit, met dezelfde uitzonderingen als bij Keen 1
  (widescreen met HUD, plaatjes achter de levels).

Na B6 is Keen 2 van begin tot eind uit te spelen. B7 en B8 maken het af en
mooi, B9 voegt co-op toe en B10 legt alles naast het origineel.

## B1. Onderzoek (`milestone-b1-onderzoek`)

- De huidige code in kaart brengen: wat werkt voor beide delen, wat is van
  Keen 1 alleen.
- Alles over Keen 2 verzamelen wat verschilt van Keen 1: bestanden, versies,
  geluiden en teksten in de EXE, vijanden, schakelaars, de Tantalus-straal,
  de wereldkaart en het einde ([research.md](research.md)).
- De architectuur vastleggen ([architecture.md](architecture.md)).
- Een handleiding voor volgende delen
  ([../new-episode-guide.md](../new-episode-guide.md)), zodat dit onderzoek
  niet opnieuw hoeft.
- Er komt nog geen code.

## B2. De bestanden van Keen 2 inlezen (`milestone-b2-bestanden`)

Doel: alle data van Keen 2 is leesbaar en te bekijken. Er beweegt nog niets.

Opdracht voor de developer:

1. `Keen2Files`: vindt `game_data/keen2` (of `--data-dir-keen2=PATH`, of naast
   de app), met `KEEN2.EXE`, `EGAHEAD.CK2`, `EGALATCH.CK2` en `EGASPRIT.CK2`
   als vereiste bestanden. Er is geen `SOUNDS.CK2` en geen tekstbestand.
   Daarvoor komen de additieve wijzigingen in `GameFiles` uit
   architecture.md.
2. `Keen2Executable`: pakt `KEEN2.EXE` uit (bestaande `DosExecutable`),
   herkent de versie (1.31 verwacht, 1.00 als het kan), en vindt op
   **inhoud** (niet alleen op vaste adressen) het geluidsblok (`SND\0`), de
   tile-eigenschappen (689 tiles), het verhaal, het eindtekst-blok, de
   namen van de acht steden, de berichten van de Vorticon-oudste en de
   teksten van het einde.
3. EGA-graphics, levels 1-16, 80, 81 en 90, en `FINALE.CK2` laden met de
   bestaande decoders (met de additieve extensie-parameter).
4. De data viewer en `tools/export_graphics.gd` kunnen Keen 2 tonen of
   exporteren (`--game=2` of `GAME=keen2`).
5. Op het startscherm een tweede icoon "Keen 2", rechts van Keen 1. Zonder
   data is het grijs met uitleg (zoals bij Keen 1). Met data opent het
   voorlopig een scherm "Keen 2: komt eraan" met "Choose Game" terug.
6. De open vragen 1-12 uit research.md die met de bestanden te beantwoorden
   zijn, beantwoorden en in `docs/keen2/file-formats.md` zetten (alleen
   beschrijvingen en getallen, nooit data uit de bestanden zelf).
7. Tests: `test_keen2_files.gd` (zonder data: zelfgemaakt mini-EXE-beeld met
   een `SND`-blok en teksten, het zoeken op inhoud, de catalogus met twee
   spellen) en `test_keen2_data.gd` (met echte data, anders overgeslagen).

Klaar als: het startscherm twee iconen toont, de data viewer alle tiles,
sprites, bitmaps en levels van Keen 2 laat zien, en de Keen 1-controle
slaagt.

## B3. Een level spelen (`milestone-b3-level`)

- `Keen2View` (eigen scène, bovenop de gedeelde `GameScreen`) en
  `Keen2LevelSession`. Een level tekenen, de camera, widescreen met HUD.
- Keen loopt, springt, pogo't (de pogo heeft hij vanaf het begin) en botst.
- Snoep en punten, sleutelkaarten en deuren, het straalgeweer met munitie,
  de uitgang, doodgaan en levens.
- Starten met `--game=2 --level=N`.
- Na deze mijlpaal kun je een level zonder vijanden uitspelen.

## B4. Vijanden en meerijden (`milestone-b4-vijanden`)

- Vorticon (grunt), Vorticon youth (Keen raakt verdoofd in plaats van dood),
  Vorticon Elite (schiet, stormt op Keen af), Guard robot (onkwetsbaar,
  schiet salvo's), Scrub (kruipt over muren en plafonds, Keen kan erop
  meerijden), het bewegende platform.
- Schoten van Keen en van vijanden, ook of vijanden elkaar raken.
- "Meerijden" (carriers) als nieuwe, additieve haak in `KeenBody`; Keen 1
  gebruikt hem niet.
- Getallen uit Commander Genius krijgen het label *estimate*.

## B5. Schakelaars en de Tantalus-straal (`milestone-b5-tantalus`)

- Schakelaars bedienen met de pogo-knop: bruggen die tile voor tile
  uitschuiven en terugtrekken, het licht uit en aan (donker beeld, ook met
  xBRZ, HD en widescreen; Vorticons springen niet in het donker).
- De berichten van de Vorticon-oudste.
- De Tantalus-straalmachine: één schot op de vonk, daarna de vaste reeks
  van kapotte tiles, vonken en punten.
- De verkeerde schakelaar: de aarde ontploft (map 81: de straal, de
  explosie, de brokstukken), en het spel is voorbij, hoeveel levens Keen
  ook heeft.

## B6. Wereldkaart en einde (`milestone-b6-kaart-einde`)

- De wereldkaart van het moederschip (map 80): lopen, levels in- en uitgaan,
  "done"-bordjes. Geen teleporters en geen schip.
- Steden redden (levels 4, 6, 7, 9, 11, 13, 15 en 16) en bijhouden.
- Het statusscherm met "Targets saved" in plaats van scheepsonderdelen.
- Het einde: Keens schip en het moederschip op map 81, `FINALE.CK2` met de
  vier pagina's, en daarna (uitzoeken) de eindtekst en "TO BE CONTINUED".
- Na deze mijlpaal kun je Keen 2 van begin tot eind uitspelen.

## B7. Geluid, menu's en opslaan (`milestone-b7-geluid-menus`)

- De geluiden uit `KEEN2.EXE`, ook `EARTHPOW` bij de ontploffing.
- Titelscherm (map 90), hoofdmenu (de gedeelde menu-klassen), het verhaal,
  de highscores met het aantal geredde steden.
- Opslaan en laden in `user://keen2/` (los van Keen 1); toetsen en
  beeldinstellingen zijn gedeeld.
- "Choose Game" terug naar het startscherm.

## B8. Mooier maken (`milestone-b8-extras`)

- Hogere framerate, xBRZ en de Real-ESRGAN-pipeline voor Keen 2
  (`GAME=keen2`), plaatjes achter levels in `assets/backgrounds/keen2/`.
- De builds voor macOS en Windows nemen `game_data/keen2` mee als die er
  is.

## B9. Co-op (`milestone-b9-coop`)

- Twee spelers op één toetsenbord met split-screen, zoals bij Keen 1.
- Online: de handshake noemt het deel (een Keen 1-host weigert een Keen
  2-gast), de snapshot van Keen 2 stuurt steden in plaats van onderdelen.
  De punten van de Tantalus-machine en de ontploffing van de aarde gelden
  voor beide spelers.

## B10. Naast het origineel (`milestone-b10-origineel`)

- De lijst "alleen te zien in het origineel" uit research.md afwerken in
  DOSBox: donker, de verkeerde schakelaar, levenspunten, snelheden, de
  verdoving, het einde, de geluidssnelheid.
- De *estimate*-getallen vervangen door gemeten waarden.
