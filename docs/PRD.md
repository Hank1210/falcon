# PRD: Falcon Patrol Remake

Status: Entwurf v0.1 · Datum: 2026-10-20

**Fortschritt:** M0 bis M6 sind umgesetzt (Mac-App-Export funktioniert, ad-hoc signiert) (Spielkern, Landen und Tanken, Bomben, Wellen, Titelbild, Game Over, Highscore, Pause, synthetisierte Sounds, Pixel-Grafik, Scanlines). Offen: Abgleich der Spielwerte mit dem Original; Optik und Layout sind an Screenshots des Originals angepasst (siehe ORIGINAL-RULES.md); Klang ist noch nicht abgeglichen. Messwerte aus dem Original stehen noch aus (siehe ORIGINAL-RULES.md).

## 1. Ziel und Vision

Ein spielbarer Nachbau des C64-Klassikers *Falcon Patrol* (ca. 1983/84), einem horizontal scrollenden Shoot-'em-up. Das Remake soll sich wie das Original anfühlen (direkte Steuerung, einfache, aber fordernde Wellen, Highscore-Jagd), aber auf aktuellen Geräten laufen.

**Erfolgskriterium:** Eine Person kann das Spiel ohne Erklärung starten, versteht in unter einer Minute das Ziel und will nach einem Game Over sofort neu starten.

## 2. Zielgruppe und Plattform

- Primär: Retro-Fans und der Autor selbst (privates Projekt).
- Plattform: Godot 4.x, Zielsystem macOS. Ein Web-Export bleibt möglich (siehe Risiken).
- Eingabe: nur Tastatur.

## 3. Rechtlicher Rahmen

- Spielmechanik und Idee sind frei nachbaubar. Original-Grafiken, Sounds, Code und evtl. der Name sind geschützt.
- **Alle Assets werden neu erstellt** (eigene Pixel-Grafik, eigene Sounds).
- Der Quelltext ist öffentlich einsehbar (GitHub-Repository `falcon`), aber **nur für private, nicht-kommerzielle Nutzung** gedacht. Es wird keine Lizenz zur Weiterverbreitung vergeben (siehe README, Abschnitt „Hinweise zur Nutzung“).
- **Keine kompilierten Builds:** Es werden keine fertigen Apps oder Binaries bereitgestellt (weder im Repository noch als Download). Wer das Spiel spielen will, erzeugt den Build selbst aus dem Quelltext (README, Abschnitt „Export“).
- Das Projekt ist eine Hommage und nicht mit den Rechteinhabern von *Falcon Patrol* verbunden. Der Titel „Falcon Patrol Remake“ bleibt bewusst bestehen, weil kein Produkt vertrieben wird.

## 4. Umfang (Scope)

### In Scope
- Horizontal scrollende Spielwelt mit Parallax-Hintergrund
- Steuerbares Spielerfahrzeug mit Hauptwaffe und zweiter Waffe
- Mehrere Gegnertypen in Wellen mit steigendem Schwierigkeitsgrad
- Ressourcen (Leben, Treibstoff/Munition, falls im Original vorhanden)
- Punktestand, Highscore (lokal gespeichert), Game Over
- Retro-Optik (niedrige Auflösung, begrenzte Palette) und Retro-Sounds

### Out of Scope (v1)
- Mehrspieler, Online-Funktionen, Bestenliste im Netz
- Level-Editor, Story, Zwischensequenzen
- Mobile-Touch-Steuerung
- Exakte Übernahme von Original-Grafik oder -Musik

## 5. Funktionale Anforderungen

Die Regeln des Originals stehen in [ORIGINAL-RULES.md](ORIGINAL-RULES.md) (Ergebnis von M0). Das Spiel ist ein Defender-Verwandter: VTOL-Jet, Zwei-Wege-Scrolling, Radar, Landen und Auftanken auf Flugplätzen. Punkte, die dort unter „Zu verifizieren“ stehen, werden vor M2/M3 am Original (VICE oder Longplay) abgelesen.

| ID | Anforderung | Priorität |
|---|---|---|
| F1 | Zwei-Wege-Scrolling-Welt, die sich nach ca. 6 Bildschirmen nahtlos wiederholt (Wüste, Palmen, Öltanks, Straßen, Gebäude) | Muss |
| F2 | Jet-Steuerung mit Trägheit: Höhe ändern (rauf/runter), links/rechts drehen und beschleunigen, Feuer. Tastatur | Muss |
| F3 | Raketen als Waffe, begrenzte Munition | Muss |
| F4 | Treibstoff mit Verbrauch, Warnton bei Knappheit, Absturz bei leerem Tank | Muss |
| F5 | Sechs Flugplätze: Landen nur im Stillstand direkt über der Plattform, Auftanken und Aufmunitionieren (langsam, nicht abbrechbar) | Muss |
| F6 | Flugplätze können durch Bomben oder abstürzende Gegner zerstört werden (werden schwarz, nicht mehr nutzbar) | Muss |
| F7 | Feindliche Jets in Wellen: Anzahl steigt (2, nach 6 Wellen 3, nach weiteren 6 Wellen 4), Pausen werden kürzer, Gegner werfen Bomben | Muss |
| F8 | Radar unten in der Mitte mit Gegnern und intakten Flugplätzen | Muss |
| F9 | Punkte pro Welle gestaffelt: 25, 50, 100, 200. Kollision gibt keine Punkte | Muss |
| F10 | 3 Leben, einmaliges Extra-Leben bei 3.000 Punkten, Tank-Sequenz zu Beginn jedes Lebens | Muss |
| F11 | Titelbildschirm, Game Over, Neustart | Muss |
| F12 | Highscore-Tabelle mit Namenseingabe (lokal gespeichert) | Soll |
| F13 | Sound im SID-Stil: Triebwerk mit abstandsabhängiger Lautstärke, Schüsse, Explosionen, Tank-Sounds, Alarm, Titelmelodie | Soll |
| F14 | Pause-Funktion | Soll |
| F15 | Optionen: Tank-Sequenz überspringen, klassische oder saubere Kollision, flüssiges Scrolling statt ruckeliger Variante | Kann |
| F16 | CRT-/Scanline-Effekt, abschaltbar | Kann |

## 6. Nicht-funktionale Anforderungen

- **Performance:** stabile 60 FPS auf einem aktuellen Mac.
- **Look:** interne Auflösung 320×200 (oder 4:3-nah), ganzzahlig skaliert, Pixel scharf, begrenzte 16-Farben-Palette.
- **Steuerung:** Eingabelatenz spürbar gering, feste Zeitschritte für die Spiellogik.
- **Wartbarkeit:** Spiellogik getrennt von Darstellung, Gegnerwellen datengetrieben (Tabelle statt Hardcoding).
- **Größe:** Web-Version wenn möglich unter 10 MB (bei Godot-Web ist das nicht erreichbar, siehe Risiken).

## 7. Entwicklungsstufen

Jede Stufe endet mit einem lauffähigen, testbaren Stand.

| Stufe | Inhalt | Fertig, wenn … | Aufwand (grob) |
|---|---|---|---|
| **M0 Vorbereitung** | Original recherchieren, Regeln dokumentieren ([ORIGINAL-RULES.md](ORIGINAL-RULES.md)), Engine, Palette und Auflösung festlegen. **Erledigt** bis auf die Werte unter „Zu verifizieren“ | PRD v1.0, Messwerte aus Original ergänzt | 0,5 Tag |
| **M1 Grundgerüst** | Godot-Projekt, 320×200-Viewport, Zwei-Wege-Scrolling mit Wrap, Jet mit Trägheit und Höhensteuerung, Platzhalter-Landschaft | Jet fliegt mit Trägheit über die sich wiederholende Welt | 0,5 Tag |
| **M2 Kampfkern** | Raketen und Munition, feindlicher Jet, Kollision, Explosion, Absturz, Punkte | Man kann Gegner abschießen und abgeschossen werden | 0,5–1 Tag |
| **M3 Inhalt** | Flugplätze mit Landen und Auftanken, Treibstoff, Bomben der Gegner, Radar, Wellen-System (2/3/4 Jets, kürzere Pausen) | Kompletter Spielkreislauf: Welle, Landen, Auftanken, nächste Welle | 1 Tag |
| **M4 Spielfluss** | Titelbild, HUD, 3 Leben und Extra-Leben bei 3.000, Tank-Sequenz, Game Over, Highscore, Pause | Kompletter Spieldurchlauf von Start bis Game Over | 0,5–1 Tag |
| **M5 Sound und Look** | Eigene Pixel-Grafik, SFX, Musik, optional CRT-Effekt | Wirkt wie ein Retro-Spiel, nicht wie ein Prototyp | 1 Tag |
| **M6 Feinschliff und Release** | Balancing, Bugfixes, Optionen (F15), Build/Export, Quelltext-Veröffentlichung (ohne fertige Builds) | Selbst erzeugter Build läuft auf Zielplattform | 1 Tag |
| **M7 Optional** | Mehr Level/Bosse, Online-Highscore, weitere Plattformen | nach Bedarf | offen |

Die Aufwände sind Schätzungen für Entwicklung mit KI-Unterstützung. Gesamt etwa 5–6 Tage bis M6.

## 8. Risiken

| Risiko | Auswirkung | Gegenmaßnahme |
|---|---|---|
| Quellen liefern keine Messwerte (Tempo, Trägheit, Treibstoff, Raketenzahl) | Spielgefühl weicht ab | Werte im VICE-Emulator oder Longplay ablesen, als Config halten und nachjustieren |
| Spielgefühl (Trägheit, Tempo) schwer zu treffen | Steuerung wirkt falsch | Früh in M1/M2 testen, Parameter in einer Config |
| Urheberrecht an Assets | Veröffentlichung des Quelltexts problematisch | Nur eigene Assets, nur private Nutzung, keine fertigen Builds |
| Engine-Wahl später bereut | Teilweise Neuarbeit | Spiellogik und Daten (Wellen) engine-unabhängig dokumentieren |
| Godot-Web-Build ist groß | Langsame Ladezeit | Bei Web-Fokus Canvas-Variante wählen |

## 9. Entscheidungen und offene Fragen

### Entschieden
- **Engine:** Godot 4.x mit GDScript. Entwicklung mit VS Code (Erweiterung godot-tools) und dem Godot-Editor für Szenen und Test.
- **Verbreitung:** Der Quelltext wird öffentlich bereitgestellt, die Nutzung ist aber auf den privaten Gebrauch beschränkt. Es gibt keine vorkompilierten Builds; wer spielen will, baut selbst. Von Anfang an nur eigene Assets, Original-Code und Original-Sounds werden nicht verwendet.
- **Originaltreue:** So originalgetreu wie möglich bei Regeln, Tempo, Gegnern und Spielgefühl. Modernisierungen (Pause, Gamepad, Optionen) nur als abschaltbare Extras.
- **Konsequenz:** Die Gameplay-Parameter (Geschwindigkeiten, Trägheit, Wellentabellen, Punkte) liegen in Konfigurationsdateien, damit spätere Modifikationen leicht möglich sind.

- **Look:** Original-Optik, also C64-Palette (16 Farben) und 320×200, ganzzahlig skaliert.
- **Eingabe:** Nur Tastatur. Gamepad entfällt vorerst.
- **Assets:** Sprites werden als Text-Pixelkarten (C64-Palette) im Projekt definiert und per Skript in PNGs umgewandelt. Sounds werden per Skript synthetisiert (Rechteck/Rauschen, SID-ähnlich). Keine externen Tools oder API-Zugänge nötig.

- **Godot:** 4.7.2 installiert.
- **Titel:** „Falcon Patrol Remake“ bleibt auch für das öffentliche Repository bestehen.
- **Projektordner:** `/Users/FRE_1/Documents/projects-2/falcon-remake` (Git, Branch `main`).

### Offen
1. **Messwerte des Originals** (siehe ORIGINAL-RULES.md, „Zu verifizieren“): Ist VICE vorhanden, oder soll ich anhand des Longplay-Videos schätzen?

## 10. Nächste Schritte

1. Offene Punkte aus Abschnitt 9 klären.
2. M1 starten: Godot-Projekt, Viewport, Scrolling und Jet mit Trägheit.
