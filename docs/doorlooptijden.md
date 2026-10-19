# Doorlooptijden

Hoe lang elke mijlpaal duurde, zodat te zien is wat een hele episode kost.
De architect vult na elke mijlpaal een regel in (zie `CLAUDE.md`, "Session
routine").

Hoe er gemeten wordt:

- **Werktijd** is de tijd van de opdracht (of de vorige mijlpaal) tot de
  laatste commit van de mijlpaal, zonder pauzes van meer dan een uur
  (nachten, wachten op de gebruiker).
- **Agent** is hoe lang de developer-agent zelf bezig was. Dat is vanaf C2
  precies bekend; de rest van de werktijd is het onderzoek, de controle door
  de architect en vragen aan de gebruiker.
- Voor Keen 1 en Keen 2 is alles **achteraf geschat uit de tijden in git**.
  Een `?` betekent dat het begin niet te zien is. Mijlpaal 1-3 zijn in een
  cloud-sessie gemaakt, met tijden in een andere tijdzone.
- Speeltesten door de gebruiker telt niet mee.

## Keen 1 (mijlpalen 1-11.2)

| Mijlpaal | Datum | Werktijd (geschat) |
|---|---|---|
| 1 Bestanden inlezen | 13-10 | ? |
| 2 Levels tekenen | 13-10 | ~15 min |
| 3 Keen beweegt | 13-10 | ~40 min |
| 4 Items en vijanden | 14-10 | ~1 u 40 |
| 5 Wereldkaart en einde | 14-10 | ~45 min |
| 6 Geluid, menu's, opslaan | 14-10 | ~1 u 40 |
| 7 Framerate, xBRZ, HD, Windows | 14-10 | ~1 u 05 |
| 8 Twee spelers | 14-10 | ~1 u 20 |
| 9 Online | 15-10 | ? (plus een fix op 15-10 avond) |
| 10 Startscherm | 15-10 | ? |
| 11 Fixes | 16-10 | ? |
| 11.2 Het schip als level | 16-10 | ~2 u 45 |
| **Totaal** | 13-10 t/m 16-10 | **ongeveer 12-15 uur** werk, verspreid over vier dagen |

## Keen 2 (mijlpalen B1-B10)

| Mijlpaal | Datum | Werktijd (geschat) |
|---|---|---|
| B1 Onderzoek | 16-10 | ? (klaar 22:43) |
| B2 Bestanden | 16-10 | ~20 min |
| B3 Een level | 16-10 | ~20 min |
| B4 Vijanden | 16-10 | ~30 min |
| B5 Tantalus | 17-10 (nacht) | ~20 min |
| B5.1 Echte data | 17-10 | ? (klaar 12:31) |
| B6 Kaart en einde | 17-10 | ~45 min |
| B7 Geluid en menu's | 17-10 | ~25 min |
| B8 Extra's | 17-10 | ~20 min |
| B9 Co-op | 17-10 | ~20 min |
| B10 Naast het origineel | 17-10 | ~35 min |
| **Totaal** | 16-10 avond t/m 17-10 middag | **ongeveer 5-7 uur** werk |

## Keen 3 (mijlpalen C1-C12)

| Mijlpaal | Datum | Werktijd | Agent | Opmerking |
|---|---|---|---|---|
| C1 Onderzoek | 17-10 | ~1 u 30 | 5 onderzoeksagents tegelijk (6-53 min) | Inclusief js-dos en de vragen aan de gebruiker |
| C2 Bestanden | 17-10 | ~20 min | 19 min | |
| C3 Een level | 17-10 | ~25 min | 23 min | |
| C4 Vijanden | 17-10 | ~50 min | 43 min | Inclusief een poging in js-dos |
| C5 Bal, jack, platforms, wapens | 18-10 | ~35 min | 33 min | Inclusief het verticale platform gemeten in js-dos |
| C6 Wereldkaart | 18-10 | ~47 min | 46 min | Inclusief kaart, teleporter, Messie en statusscherm gemeten in js-dos |
| C7 Mortimer en het einde | 18-10 | ~42 min | 41 min | Armen en benen van de machine gemeten in js-dos (level 16 tijdelijk als level 1) |
| Fix: gemaskeerde tiles (na C7) | 18-10 | ~30 min | 16 min | Bug van de gebruiker: Keen achter wolken, hekken en tafels; ook Keen 2 levels 6, 7, 9; plus de kaart-screenshot van de Keen 2-controle |
| C8 Geluid, menu's, opslaan | 19-10 | ~42 min | 36 min + 4 min | In een cloud-sessie; Keen 2- en 3-bestanden geüpload door de gebruiker. Controle door de architect: een highscore-screenshot met zelfgemaakte testdata nagevraagd (geen fout). 145,65 Hz voor alle drie de delen |
| C9 Extra's | 19-10 | ~22 min | 19 min | Vloeiende beweging en xBRZ deden al alles; plaatjes achter de levels met een eigen regel (lucht); geen builds in de cloud |
| Plaatjes achter de levels (na C9) | 19-10 | ~35 min | | Op verzoek van de gebruiker: twaalf eigen plaatjes vanuit code (`tools/make_keen3_backgrounds.py`), door de architect zelf |
| C10 Co-op | 19-10 | ~40 min | 36 min | Split-screen en online (ook overschakelen van en naar Keen 3); online getest met twee xvfb-vensters; Steam niet te testen in de cloud |
| C11 Naast het origineel | 19-10 | ~65 min | 63 min | Het origineel in js-dos in een headless Chromium (nieuw: `tools/original/headless.js`); einde, eindtekst en highscores op de pixel gelijk; ankh 9,6 s bevestigd; sprongen gemeten voor C12 |
| C12 Keen 1 en 2 bijwerken | | | | |
| **Totaal tot nu toe** | 17-10 t/m 19-10 | **~9 u 00** | | C1-C11, de fix en de plaatjes; C12 (Keen 1 en 2 bijwerken) volgt nog |
