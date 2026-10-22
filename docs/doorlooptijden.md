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
| Fix: lift, achtergronden, level 10 (na C11) | 20-10 | ~30 min | 24 min | Bugs van de gebruiker: Keen opzij gegooid bij springen van een lift; zwevende dingen in de plaatjes, level 14 nieuw; levels 9 en 10 een plaatje door alleen de lucht |
| Fix: schot door de muur (na C11) | 20-10 | ~18 min | 18 min | Bug van de gebruiker: vlak bij een muur ging Keens schot erdoor; eerst Keen 3 (11 min), daarna op verzoek ook Keen 2, ook de vijandschoten (7 min); Keen 1 heeft hem nog (vraag voor C12) |
| C12 Keen 1 en 2 bijwerken | | | | |
| **Totaal tot nu toe** | 17-10 t/m 20-10 | **~9 u 47** | | C1-C11, de fixes en de plaatjes; C12 (Keen 1 en 2 bijwerken) volgt nog |

## Keen 4 (mijlpalen D1-D13)

Keen 4 is een andere engine (Galaxy); de schatting per mijlpaal staat in
`docs/keen4/roadmap.md` (in totaal ~13-15 uur, ongeveer als Keen 1).

| Mijlpaal | Datum | Werktijd | Agent | Opmerking |
|---|---|---|---|---|
| D1 Onderzoek | 19-10 | ~1 u 30 | developer-agent 5 min, onderzoeksagent 13 min | In een cloud-sessie; Keen 4 v1.0 geüpload door de gebruiker en zelf uitgelezen door de architect; vragen als keuzemenu |
| D2 Bestanden | 20-10 | ~40 min | 36 min | Galaxy-lezers (Huffman, Carmack, RLEW, de zes headers op inhoud), graphics in ~1 s, data viewer, vierde icoon; alles in een cloud-sessie met Keen 4 v1.0 |
| D3 Een level tekenen | 20-10 | ~50 min | 45 min | Drie tilelagen, animaties op de tic, camera met scroll-blokken, breedbeeld afgedekt, xBRZ per level; eerste beeld van 5 levels en de kaart pixel voor pixel gelijk aan het origineel (headless js-dos) |
| D4 Keen beweegt | 20-10 | ~75 min | 70 min | Actiesysteem, botsingen met hellingen, alle toestanden van Keen, items, edelsteendeuren, scorebord; sprong 67 px en pogo 105 px gemeten in het origineel (v1.0) |
| D5 Vijanden | 20-10 | ~55 min | 51 min | 15 soorten wezens op het land, de verdoving, moeilijkheidsgraad; Bounder, paddenstoel, vogel, Arachnut, Skypest, Lick, Berkeloid en Mimrock nagekeken in het origineel |
| D6 Mechaniek | 20-10 | ~65 min | 61 min | Platforms, schakelaars, bruggen, raadsleden, conciërge, Lindsey, wetsuit, berichtvensters (pixel gelijk aan het origineel), level 17 onder water |
| D7 Wereldkaart | 20-10 | ~80 min | 73 min + 3 min | Kaart als level, levels in en uit, vlaggen, hekken, water en wetsuit, Miragia, de Foot, statusvenster en Try Again (pixel gelijk aan het origineel), map 18; controle: een vlag buiten beeld nagevraagd (geen fout) |
| D8 Einde, titel, demo's | 20-10 | ~95 min | 92 min | Eindpagina's, highscores op map 19, cheats, intro, verhaal, help; alle vijf demo's lopen tot het laatste frame gelijk met het origineel; schermen pixel gelijk |
| D8.1 Pixelstappen (fix) | 20-10 | ~25 min | 24 min | Op verzoek van de gebruiker: sprites en beeld in de stapjes van het origineel; demo 1 hele beelden 100 % gelijk, demo 0 91 % (rest: wezens, waarschijnlijk toeval) |
| D9 Geluid en muziek | 20-10 | ~75 min | dev 72 min, tester 72 min (tegelijk) | Eigen OPL2-synthesizer, AdLib-geluiden, zes liedjes, cache, PC-speaker; tegelijk met D10 gebouwd, elk met een tester |
| D10 Menu's en opslaan | 20-10 | ~70 min | dev 38 min, tester 68 min (tegelijk) | Menu pixel gelijk aan v1.0, moeilijkheid, opslaan overal (level als begin + frames) |
| Samenvoegen D8.1 + D9 + D10 | 20-10 | ~15 min | | Door de architect: twee kleine conflicten in de documenten en in `keen4_view.gd`; 101 suites groen |
| D11 Extra's, Paddle War, plaatjes | 20-10 | ~70 min | dev 50 min, tester 52 min, tekenaar 50 min (tegelijk) | Paddle War, Choose Game onder Quit, geluidskaarten, F1, xBRZ-fixes, tien eigen achtergronden; samengevoegd, 108 suites groen |
| D12 Co-op | 20-10 | ~60 min | dev 55 min, tester 57 min (tegelijk) | Split-screen, gedeelde toetsen omhoog/omlaag, online met eigen Galaxy-berichten, overschakelen; 118 suites groen |
| D13 A Demo's | 20-10 | ~65 min | 63 min | Alle vijf demo's van v1.0 in hele beelden 100 % gelijk (slapen bij de start, de gedeelde stap, de deur) |
| D13 B Metingen | 20-10 | ~52 min | 50 min (tegelijk met A en C) | Wachtanimaties, edelsteendeur, vallend platform, Game Over 333 tics, richel naar rechts |
| D13 B2 Metingen | 20-10 | ~50 min | 48 min | Dopefish, onder water, mijn, slak, wolk, dartguns; platforms stuiteren, het wetsuit wacht op zijn geluid |
| D13 C Versie 1.4 | 20-10 | ~1 u 43 | 100 min (tegelijk met A en B) | 1.4 naast 1.0, rode help- en eindpagina's, sprong na stoppen, F1 onder PAUSED |
| Samenvoegen D13 | 20-10 | ~20 min | | Door de architect: conflicten in drie documenten en `run_tests.gd`; 121 suites groen, regressies 0 verschillen |
| Fix: split-screen kijken, trillen, cheats (D13.2) | 21-10 | ~42 min | 42 min | Zes bugs van de gebruiker: kijken per helft, stilstand in pauzes, Shift+G/Shift+I met meldingen, online-pagina over de pols-computer, glas van Miragia (ingesloten lucht houdt zijn kleur); regressies Keen 1, 2 en 4 gelijk |
| Fix: split-screen in kleine ruimtes (D13.2) | 21-10 | ~22 min | 22 min | Rechte lijn door het midden zolang een speler in een kleine ruimte is (< 1,2 beeld), ruimte midden in zijn eigen helft, glijdend terug; regressies Keen 1, 2 en 4 gelijk |
| Fix: vloer van Miragia dicht, glas doorzichtig (D13.2) | 21-10 | ~15 min | 15 min | Alleen gaten in een vloerband krijgen de luchtkleur, het glas toont het plaatje weer; nagekeken op alle levels met een plaatje |
| Fix: Miragia lucht boven de looprand (D13.2) | 21-10 | ~16 min | 16 min | Een gat in de vloer moet bovenaan dicht zijn; de lucht boven een lage richel bij de slak toont het plaatje weer; naast het origineel gelegd (js-dos); regressies Keen 1, 2 en 4 gelijk |
| Fix: vijanden en items die opduiken in breedbeeld (D13.2) | 21-10 | ~13 min | 13 min | Wakker worden, slapen en "in beeld" tellen met het brede beeld (en elke split-helft) plus de marges van het origineel; 4:3 en demo's als het origineel; de breedte staat tussen de frames van een opgeslagen level; regressies Keen 1, 2 en 4 gelijk |
| Plaatjes: piramides en Miragia (D13.2) | 21-10 | ~10 min | 10 min | Piramides in 11 en 12 staan op een zandvlakte met schaduwen over het zand (in 12 lang, opzij van de lage zon); Miragia zonder heuvels, met ribbelduinen, een luchtspiegeling met rotsnaalden en palmen en een karavaan; de andere plaatjes nagekeken (ongewijzigd) |
| **Totaal** | 19-10 t/m 21-10 | **~21 u 13** opgeteld | | D1-D13 en D13.2; vanaf D9 werkten agents deels tegelijk, dus de klok liep korter. Iets meer dan de schatting (13-15 u) door co-op, online, 1.4 en de metingen naast het origineel |

## Achtergronden Keen 1 en 2 (mijlpalen AB)

| Mijlpaal | Datum | Werktijd | Agent | Opmerking |
|---|---|---|---|---|
| AB1 Onderzoek | 22-10 | ~1 u 10 | | Door de architect: alle levels geëxporteerd en gemeten (kleurregel tegen patroonregel), proefplaatjes, keuzes van de gebruiker als menu |
| AB2 De vaste wand | 22-10 | ~55 min | 45 min + 9 min (fix kasteel) | `LevelWall`, patroonregel met schaduw, lichtbundels van Keen 1 grijs |
| AB3 De plaatjes | 22-10 | ~50 min | 50 min (tegelijk met AB2) | 16 Keen 2-wanden, 11 Keen 1-luchten, 10 Keen 1-wanden |
| AB4 Samenvoegen en nakijken | 22-10 | ~40 min | | Door de architect: een conflict in `docs/graphics.md`, twee tests aangepast, 32 levels gefotografeerd, regressies |
| **Totaal** | 22-10 | **~3 u 35** opgeteld | | De klok liep korter (~2 u 30) doordat AB2 en AB3 tegelijk liepen |
