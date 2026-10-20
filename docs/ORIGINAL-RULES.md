# Falcon Patrol (C64, 1983): Regeln des Originals

Ergebnis von M0 (Recherche), Stand 2026-10-20.
Quellen: C64-Wiki (Falcon Patrol), Lemon64-Review und Kommentare, MobyGames. Das verlinkte Longplay-Video (Myrryspeikko, 7:52) liefert nur Metadaten, keinen Text. Beobachtungen daraus stehen unten bei „Zu verifizieren“.

Eckdaten: Entwickler und Musiker Steve Lee, Publisher Virgin Games, 1983. Nachfolger: Falcon Patrol II (1984).

**Wichtige Korrektur zu früheren Annahmen:** Das Spiel ist ein Defender-Verwandter (Zwei-Wege-Scrolling, Radar) in einem Wüsten-/Ölfeld-Setting, kein klassischer Rechts-Scroller mit Bodenbomben. Der Spieler fliegt ein VTOL-Flugzeug, schießt Raketen auf feindliche Jets und muss auf Flugplätzen landen, um aufzutanken.

## Spielziel
- Als letzter Pilot der „Falcon Patrol“-Staffel feindliche Jets in Wellen abschießen.
- Die **sechs Flugplätze** vor Bombardierung schützen. Sie werden zum Auftanken und Aufmunitionieren in den Pausen zwischen den Angriffen gebraucht.
- Highscore-Jagd (kein festes Ende bekannt).

## Spielwelt
- Wüstenlandschaft, möglicherweise ein Ölfördergebiet: gelber Boden, Palmen, Öltanks, rechtwinklige Straßen, eckige Gebäude, abgestellte schwarze Lkw (statisch, nicht animiert).
- **Zwei-Wege-Scrolling**, Welt wiederholt sich nahtlos nach ca. **6 Bildschirmen**. Das Scrolling im Original ist ruckelig.
- **Radar** unten in der Mitte des Bildschirms: zeigt Positionen der Feinde und der noch unzerstörten Flugplätze.
- Kollision: Sprite-basiert. Im Original gehen eigene Raketen teils wirkungslos durch Gegner, umgekehrt nie (schwache Trefferabfrage, siehe Abschnitt Modifikation).

## Steuerung (Original, Joystick oder Tastatur)
| Aktion | Joystick | Tastatur (Original) |
|---|---|---|
| Flughöhe ändern (Steigen/Sinken) | vor/zurück | ← / 1 |
| Drehen links/rechts, beschleunigen | links/rechts | CTRL / 2 |
| Feuer | Feuerknopf | Leertaste |

- Starke **Trägheit**: Der Jet braucht „einige Sekunden“ für eine volle Richtungsumkehr.
- Beim Steigen/Sinken in die Gegenrichtung drücken, um die Höhe zu halten.

## Ressourcen
- **Treibstoff** und **Raketen** sind begrenzt.
- Warnton („schriller Alarm“), wenn der Treibstoff knapp wird.
- Ist der Treibstoff leer, stürzt der Jet ab.

## Landen und Auftanken
- Landen nur auf einer **Landeplattform (Flugplatz)**: Jet muss **vollständig zum Stehen kommen** direkt über der Plattform.
- Beim Landen/Auftanken ist der Jet verwundbar (Gegner können ihn dabei überholen und bombardieren).
- Auftanken ist **langsam** und kann nicht abgebrochen werden. Es gibt eigene Sounds fürs Tanken und ein „Standby“-Signal.
- **Zu Beginn jedes Lebens** läuft ebenfalls die Auftank-Sequenz (ca. 20 Sekunden Pause laut einem Kommentar).
- Flugplätze werden zerstört, wenn sie bombardiert werden oder ein Gegner hineinstürzt. Zerstörte Flugplätze werden **schwarz** und sind nicht mehr nutzbar.
- Laut C64-Wiki werden zerstörte Flugplätze erst **nach dem Verlust des aktuellen Lebens** erneuert.

## Gegner
- Eine Art feindliche Jets/Bomber (rot, einfarbige Hires-Sprites, wenige Animationsframes). Spieler- und Feind-Jet unterscheiden sich nur in der Farbe.
- Sie werfen Bomben auf Flugplätze und auf den Spieler. Nähe zum Gegner ist gefährlich: Wer zu eifrig verfolgt, bekommt eine Bombe ab oder kollidiert.
- **Höchstens zwei Gegner gleichzeitig** auf dem Bildschirm (Kommentar auf Lemon64, mit Vorsicht zu behandeln).
- Gegner drehen nach einiger Zeit ab und werden durch eine neue Welle ersetzt, wenn man sie nicht rechtzeitig abschießt.
- Kollision mit dem Gegner kostet ein Leben und gibt **keine Punkte**.

## Wellen und Schwierigkeit
- Wellen kommen nacheinander, **die Pausen zwischen den Angriffen werden kürzer**.
- Anfangs 2 Jets pro Welle. Nach 6 Wellen steigt die Zahl auf **3**, nach weiteren 6 auf **4** Maschinen (Hinweis im C64-Wiki; der Wiki-Text „every six waves one more“ ist leicht widersprüchlich formuliert).
- Die ersten sechs Wellen gelten als sehr leicht.

## Punkte und Leben
- Abschüsse pro Welle gestaffelt: **1. Jet 25, 2. Jet 50, 3. Jet 100, 4. Jet 200** Punkte. Der letzte Jet einer Welle ist mehr wert als alle vorherigen zusammen.
- Kollisionen geben keine Punkte.
- Start mit **3 Leben**. **Einmaliger Extra-Leben-Bonus bei 3.000 Punkten** (kurzes Signal).
- Highscore-Tabelle mit Buchstabeneingabe; jeder Buchstabe wird von einem von 7 Tönen begleitet.
- Zum Vergleich: Rekorde der Community liegen bei ca. 11.425 Punkten.

## Sound (wichtiger Teil des Gefühls)
- **Triebwerksgeräusch** über das SID-Filterregister: wird lauter, je näher man dem Gegner ist; beim Abschuss und Absturz ein langgezogenes Heulen.
- Schuss- und Bombengeräusche, zischende Explosionen, Tank-Sounds, Alarm bei wenig Treibstoff, Standby-Signal.
- Kurze, heroische Trompeten-Titelmelodie.
- Die Community lobt vor allem die Sound-Effekte, die Grafik gilt als zweckmäßig.

## Zu verifizieren (Emulator oder Video)
Folgende Punkte sind nicht belegt und müssen vor M2/M3 am Original (VICE oder Longplay) abgelesen werden:
1. Anzahl der Raketen pro Betankung und ob mehrere Schüsse gleichzeitig fliegen dürfen.
2. Treibstoffmenge und Verbrauch (pro Sekunde, bei Beschleunigung?).
3. Genaues Gegnerverhalten: Flugmuster, Bombenabwurf-Logik, Verhalten beim Abdrehen.
4. Geschwindigkeiten und Trägheitswerte (Beschleunigung, Höchsttempo, Wenden).
5. Wie das Spiel endet (alle Flugplätze zerstört? nur Leben aufgebraucht?) und was „erneuert nach Lebensverlust“ genau bedeutet.
6. Bildschirmaufbau: Höhe des Spielfeldes, Position und Größe des Radars/HUD, Höhe von Boden und Gebäuden.
7. Titelbildschirm und Ablauf der Tank-Sequenz zu Beginn eines Lebens.

## Hinweise zur Modifikation und Veröffentlichung
- Der Wiki-Eintrag und die Reviews nennen **schwache Kollisionsabfrage** und **ruckeliges Scrolling** als Mängel. Für Originaltreue als Option (`classic_mode`) umsetzbar, standardmäßig besser: saubere Kollision und flüssiges Scrolling.
- Die lange Tank-Sequenz zu Beginn jedes Lebens ist ein oft kritisierter Punkt. Als Option „Tank-Sequenz überspringen“ vorsehen.
- Es gibt ein bekanntes Windows-Remake („Patrol Falcon“, 2007). Für eine spätere Veröffentlichung sollte das Remake eigene Grafik, eigene Sounds und einen eigenen Titel haben.
