# Roadmap Keen 3

De mijlpalen voor het derde deel ("Keen Must Die!"). De actuele status
staat in [PROGRESS.md](../../PROGRESS.md). Hoe Keen 3 naast Keen 1 en 2 komt
te staan, staat in [architecture.md](architecture.md). Wat er over het spel
bekend is, staat in [research.md](research.md).

Afspraken:

- Elke mijlpaal heeft een branch `milestone-c<n>-<onderwerp>`. Zolang de
  B-branches niet op `main` staan, begint C1 vanaf `milestone-b10-origineel`
  en elke volgende C-branch vanaf de vorige.
- **Keen 1 en Keen 2 blijven zoals ze zijn.** Elke mijlpaal eindigt met de
  controle uit [architecture.md](architecture.md): alle bestaande tests
  slagen zonder dat ze zijn aangepast, `gdlint` is schoon, gescript spelen
  van Keen 1 én Keen 2 geeft dezelfde screenshots, en de Keen 1- en Keen
  2-bestanden zijn niet veranderd.
- De architect schrijft per mijlpaal de opdracht (hieronder). De developer
  bouwt die, met tests, en werkt `PROGRESS.md` bij. De architect controleert
  daarna de diff tegen de opdracht en de regels.
- Getallen komen eerst uit Chocolate Keen (`(Choco)`, besluit van de
  gebruiker op 17-10-2026), anders uit Commander Genius (`# estimate`).
  Nooit code overnemen.
- **Naast het origineel tijdens het werk:** elke mijlpaal met iets
  zichtbaars eindigt met een korte vergelijking in js-dos (zie
  research.md, "Watching the original"). Wat dan gemeten is, vervangt de
  schatting meteen.
- De gebruiker heeft Keen 3 **versie 1.00**. We zoeken alles in de EXE op
  inhoud, zodat 1.31 (Steam/GOG) ook werkt. De twee bugs van 1.00 (de gele
  sleutel in level 10 en de school in level 13 zijn onbereikbaar) laten we
  zoals ze zijn: het origineel blijft het origineel.
- Extra's zijn standaard uit, met dezelfde uitzonderingen als bij Keen 1 en
  2 (widescreen met HUD, plaatjes achter de levels).
- Na elke mijlpaal: de app opnieuw bouwen voor macOS en Windows, committen
  en de branch pushen.

Na C7 is Keen 3 van begin tot eind uit te spelen. C8 en C9 maken het af en
mooi, C10 voegt co-op toe en C11 werkt de laatste punten naast het origineel
af.

## C1. Onderzoek (`milestone-c1-onderzoek`)

- De huidige code in kaart: wat van Keen 1 en Keen 2 Keen 3 kan gebruiken,
  welke gedeelde plekken een derde spel moeten kennen.
- De Keen 3-bestanden van de gebruiker uitgelezen (in de scratchpad, niets
  in git): versie 1.00, 624 tiles met een tabel van 715 breed, 148 sprites,
  de info-waarden per level, de teleporters en Messie op de kaart.
- Commander Genius en Chocolate Keen als documentatie, KeenWiki, en het
  origineel in js-dos ([research.md](research.md)).
- De architectuur ([architecture.md](architecture.md)), deze roadmap, en de
  handleiding voor volgende delen bijgewerkt
  ([../new-episode-guide.md](../new-episode-guide.md)).
- Er komt nog geen code.

## C2. De bestanden van Keen 3 inlezen (`milestone-c2-bestanden`)

Doel: alle data van Keen 3 is leesbaar en te bekijken; het startscherm
heeft drie iconen. Er beweegt nog niets.

Opdracht voor de developer:

1. `Keen3Files`: vindt `game_data/keen3` (of `--data-dir-keen3=PATH`, of naast
   de app) met `KEEN3.EXE`, `EGAHEAD.CK3`, `EGALATCH.CK3`, `EGASPRIT.CK3`.
   Levelnummers 1-16, 80, 81, 90.
2. `TileProperties.find_in_image` krijgt de optionele parameter `stride`
   (standaard `tile_count`). Een test bewijst dat Keen 1 en Keen 2 hetzelfde
   lezen als voorheen, en dat Keen 3 met 624/715 de juiste tabel vindt (en
   met 624/624 niet).
3. `Keen3Executable`: pakt `KEEN3.EXE` uit, herkent de versie (beeld 127.086
   bytes = 1.00; 127.104 = 1.31, zie research §0), en vindt op **inhoud**: het
   geluidsblok (45 namen), de tile-tabel, de vier teksten (volgorde help,
   eind, previews, verhaal; de eerste niet twee bytes te vroeg), het
   statusvak (11 regels), de berichten van Mortimer, de vier pagina's van
   het einde, "The End... For now!", de vier scheepsberichten, de
   highscore-teksten. Gebruikt de statische hulpfuncties van
   `Keen2Executable`, verandert die niet.
4. `Keen3GameData`: graphics, tile-eigenschappen, geluiden, teksten,
   `FINALE.CK3`.
5. Het startscherm: een derde icoon "Keen 3" rechts van Keen 2, met Keen uit
   de eigen Keen 3-graphics; zonder bestanden grijs met uitleg. Met
   bestanden voorlopig een scherm "Keen 3 - coming soon" (Enter/Escape
   terug).
6. `--game=3` (met of zonder `--level=N`), ook in de data viewer en
   `tools/export_graphics.gd` (naar `exported/keen3/`). Uitzondering 2 uit
   architecture.md: wat vroeger werkte, geeft hetzelfde antwoord.
7. `tools/keen2_regression.sh`, zoals `keen1_regression.sh` maar voor Keen 2
   met de echte Keen 2-bestanden; de referentie komt van `a9d04cc` in een
   worktree. Vanaf nu draaien beide aan het eind van elke mijlpaal.
8. De bouwscripts nemen `game_data/keen3` mee als die er is; `game_data/README.md`
   krijgt een stukje over Keen 3.
9. `docs/keen3/file-formats.md`: wat de bestanden zeggen (beschrijvingen en
   getallen, nooit data uit de bestanden).
10. Tests: `test_keen3_files.gd` (zonder data: zelfgemaakt EXE-beeld met
    `SND`-blok en teksten in Keen 3-volgorde, de stride, de catalogus met drie
    spellen, `--game=3`) en `test_keen3_data.gd` (met echte data: 624 tiles,
    148 sprites, sprite-namen en -boxen, versie 1.00, de geluidsnamen, de
    teksten, de info-waarden van map 80).

Klaar als: het startscherm drie iconen toont, de data viewer alle tiles,
sprites, bitmaps en levels van Keen 3 laat zien, en de Keen 1- en Keen
2-controle slaagt.

## C3. Een level spelen (`milestone-c3-level`)

- `Keen3View` (eigen scène en schermketen bovenop `GameScreen`),
  `Keen3LevelSession extends Keen2LevelSession`, `Keen3Body extends
  Keen2Body`, `Keen3Inventory`.
- Keen loopt, springt, pogo't (vanaf het begin), botst. De rand van 2 tiles
  (tile 245, "OH no!") is nooit te zien, ook niet in widescreen.
- Items: punten (snoepreep 500, hamburger 100: de tabel, niet de helptekst),
  het straalgeweer (+5), de losse lading (gedrag 28, +1), sleutelkaarten en
  deuren, en een opgepakt item laat de eerste tile van zijn rij achter.
- **De ankh** (gedrag 27): geluid ANKH, het schild (sprites 61/62), Keen kan
  niet dood en niet verdoofd, behalve door uit het level te vallen; de tijd
  uit Chocolate Keen.
- Twee uitgangen in levels 12, 13 en 15; de juiste van de twee starts in
  level 9.
- HUD: levens, score, ladingen, sleutelkaarten, ankh-tijd.
- Startwaarden (levens, ladingen) uit Chocolate Keen, in js-dos nagekeken.
- Voorlopig verloop zoals B3: level na level, dood, game over, `--game=3
  --level=N`.

Klaar als: je elk level zonder vijanden kunt uitspelen en de ankh werkt.

## C4. Vijanden (`milestone-c4-vijanden`)

- Grunt en youth (subklassen van Keen 2's, met de eigen sprites; de youth
  verdooft, de laatste frame is 30).
- Vortimom met haar vuurbal (die Keen kan neerschieten).
- Meep met de geluidsgolf (dodelijk, door muren heen).
- VortiNinja (de twee sprongen).
- Foob (schrikt, vlucht; gaat zelf dood als Keen hem raakt).
- Schoten van Keen (sprite 102) en wat ze raken; of vijanden elkaar raken.
- In js-dos: elk van deze vijanden bekijken met Keen stil (snelheden,
  frames, wachttijden) en de getallen aanpassen.

## C5. Bal, jack, platforms en wapens in de muur (`milestone-c5-mechaniek`)

- Bal (onschuldig, kaatst) en jack (dodelijk, schoten gaan erdoor).
- Het horizontale platform en het nieuwe **verticale** platform (duwt Keen
  omlaag); meerijden via `Keen2RidingCollision` en `Keen2Carrier`.
- De onzichtbare wapens (info 14 naar rechts, 15 omlaag) die om de zoveel
  ticks tegelijk vuren.
- In js-dos nagekeken.
- Na deze mijlpaal zijn levels 1-15 met alles erop te spelen.

## C6. De wereldkaart (`milestone-c6-kaart`)

- Map 80: lopen, levels in en uit, de geblokkeerde stukken (0x8000 + n), de
  "done"-bordjes (tiles 52-55 en 56).
- **Teleporters** (info 0x0Fab: van a naar b) met hun animatie.
- **Messie**: zwemt haar rondje, wacht bij het wier, Keen stapt op en af bij
  de aanlegplekken; zo kom je bij level 16 en het geheime level 13.
- Het schip (info 20): een van de vier berichten.
- Het statusscherm (score, extra Keen, levens, pistool, ankh-tijd,
  sleutelkaarten; geen onderdelen of steden).
- "Keens Left", dood en terug naar de kaart.
- In js-dos: Messie, de teleporter, het statusscherm.

## C7. Mortimer en het einde (`milestone-c7-mortimer-einde`)

- Level 16: de berichten van Mortimer bij binnenkomst (met het geluid
  MORTIMER), de **Mangling Machine** (zes vonken, armen, benen met
  FOOTSLAM, het hart), de golven, het trillen van het scherm, de tiles die
  veranderen (ook in xBRZ en HD), en het einde van het level.
- Het einde: map 81 met de vier pagina's, de flitsen, `FINALE.CK3` met "The
  End... For now!", de eindtekst, de highscores.
- Na deze mijlpaal kun je Keen 3 van begin tot eind uitspelen.

## C8. Geluid, menu's en opslaan (`milestone-c8-geluid-menus`)

- De geluiden uit `KEEN3.EXE`, ook ANKH, MEEP, MORTIMER en FOOTSLAM.
- Titelscherm (map 90), hoofdmenu (de gedeelde menu-klassen), het verhaal,
  de highscores (alleen naam en score).
- Opslaan en laden in `user://keen3/` (los van Keen 1 en 2); toetsen en
  beeldinstellingen zijn gedeeld.
- "Choose Game" terug naar het startscherm.

## C9. Mooier maken (`milestone-c9-extras`)

- Hogere framerate en xBRZ (gedeeld; nakijken), plaatjes achter levels in
  `assets/backgrounds/keen3/` (alleen eigen plaatjes), de builds voor macOS
  en Windows.
- Real-ESRGAN: zoals bij Keen 2 overslaan, tenzij de gebruiker het anders
  wil (open vraag).

## C10. Co-op (`milestone-c10-coop`)

- Twee spelers op één toetsenbord met split-screen.
- Online: `GAME_ID_KEEN_3`; meedoen met een host van een ander deel schakelt
  over, zoals bij Keen 1 en 2. De snapshot stuurt de ankh-tijd en de
  gedane levels mee; Messie, de teleporters en de machine werken voor
  beide spelers.

## C11. Naast het origineel (`milestone-c11-origineel`)

- Wat na C3-C10 nog `# estimate` is, in js-dos nakijken (lijst in
  research.md, "Only the original can answer").
- Het einde, de titel, de highscores en het statusscherm op de pixel
  nameten, zoals B10.
