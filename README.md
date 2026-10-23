# MacTab 🪟⚡

Ein moderner, hochperformanter und stabiler Fenster-Umschalter (Alt-Tab Switcher) für macOS – inspiriert von der klassischen Windows Alt+Tab Navigation, von Grund auf neu entwickelt mit **Swift**, **SwiftUI** und **AppKit**.

---

## 🔍 Technische Architektur & Stabilitäts-Engine

MacTab löst die typischen Stabilitätsprobleme und Performance-Schwachstellen herkömmlicher macOS-Fenster-Umschalter von Grund auf:

| Typische Problemzone bei macOS | Technische Ursache | Wie MacTab das Problem löst (Stabilitäts-Boost) |
| :--- | :--- | :--- |
| **Hänger & UI-Freezes** | `AXUIElementCopyAttributeValue` blockiert den Main Thread synchron, wenn eine App beschäftigt oder unresponsiv ist (bis zu 6 Sekunden Default-Timeout!). | **Strikte AX-Timeouts**: Jedes `AXUIElement` wird mit `AXUIElementSetMessagingTimeout(ax, 0.15)` (150 ms) abgesichert. Die Fenstererkennung läuft auf einer dedizierten Hintergrund-Queue (`com.mactab.windowdiscovery`). Der Main Thread blockiert niemals. |
| **Shortcut reagiert plötzlich nicht mehr** | macOS schaltet `CGEventTap` stumm (`kCGEventTapDisabledByTimeout`), wenn Events zu langsam verarbeitet werden oder Systemlast auftritt. | **Auto-Healing Event Tap & Watchdog**: Der Event-Callback fängt `tapDisabledByTimeout` sofort ab und reaktiviert den Tap via `CGEvent.tapEnable`. Ein Heartbeat-Watchdog prüft alle 1,5s die Bereitschaft. |
| **Hoher RAM- & CPU-Verbrauch** | Mehrmaliges Aufnehmen unskalierter 4K/5K-Fensterbitmaps via CoreGraphics erzeugt Memory Spikes (teilweise hunderte Megabytes). | **Smart Thumbnail Engine mit LRU-Cache**: Thumbnails werden im Hintergrund gecacht, auf handliche Maße herunterskaliert (max. 300 KB pro Fenster statt 40 MB) und beim Schließen des Switchers bereinigt. Gesamtspeicher bleibt unter 35 MB. |
| **Zuverlässiger Space- & Fenster-Fokus** | Beim Umschalten auf minimierte Fenster oder andere Spaces scheiterte oft die Aktivierung. | **4-Stufen-Fokus**: 1. `app.unhide()` -> 2. `kAXMinimizedAttribute = false` -> 3. `app.activate(options: .activateIgnoringOtherApps)` -> 4. `kAXRaiseAction` + `kAXMainAttribute = true`. |

---

## ✨ Features

- **Globaler Shortcut**: Standardmäßig `⌥ + ⇥` (Option + Tab) oder konfigurierbar auf `⌘ + ⇥` bzw. `⌃ + ⇥`.
- **Echtes Alt-Tab-Verhalten**: Fenster sind nach präziser Z-Order sortiert; Index 0 ist das aktive Fenster und Index 1 immer das zuletzt im Vordergrund gewesene Fenster. Ein kurzes Antippen von `Option+Tab` wechselt sofort zwischen den beiden zuletzt genutzten Fenstern hin und her.
- **Glassmorphic HUD mit 4er-Raster**: Transparenter Liquid-Glass-Hintergrund (`NSVisualEffectView`). Maximal **4 Fenster pro Zeile** – ab dem 5. Fenster erfolgt automatisch ein sauberer Zeilenumbruch mit großzügiger Rahmenhöhe.
- **Präzises Einzelfenster-Highlighting**: Nur das aktuell mit Tab/Pfeiltasten selektierte Fenster wird akzentuiert hervorgehoben; vorherige Highlights und Mouseover-Hover werden beim Weiterschalten sofort bereinigt.
- **Kompakte Legende als Info-Icon**: Statt eines breiten Fußbereichs befindet sich unten rechts ein dezentes Info-Symbol (`?`), das alle Tastatur-Kurzbefehle per Klick oder Tooltip anzeigt.
- **Umrandung des echten Fensters**: Das im Switcher ausgewählte Fenster wird zusätzlich direkt auf dem Bildschirm mit einem farbigen Rahmen (Systemakzentfarbe) markiert. Abschaltbar in den Einstellungen unter *„Ausgewähltes Fenster auf dem Bildschirm umranden“*. Minimierte, ausgeblendete oder auf anderen Spaces liegende Fenster werden nicht umrandet.
- **Schnellaktionen während der Switcher offen ist**:
  - `⇥` (Tab) oder `→`: Nächstes Fenster
  - `⇧ + ⇥` (Shift+Tab) oder `←`: Vorheriges Fenster
  - `↑ / ↓`: Zeilenweise springen (eine Reihe nach oben/unten)
  - `1` bis `9`: Direkter Sprung zu Fenster 1–9
  - `W`, `X` oder `⌫` (Delete): Ausgewähltes Fenster sofort schließen
  - `M`: Ausgewähltes Fenster minimieren
  - `H`: Zugehörige App verstecken
  - `Leertaste`: Schnellvorschau (Quick Look)
  - `Esc`: Switcher abbrechen ohne Umschalten
  - **Loslassen der Modifier-Taste (⌥)**: Sofortiges Umschalten und Fokussieren!
- **Statusleisten-Icon**: Unauffälliges Menüleisten-Symbol (`LSUIElement: true`, kein störendes Dock-Icon) mit Einstellungsdialog, Autostart-Schalter und Rechte-Status.
- **Automatischer Systemstart (Launch at Login)**: Startet auf Wunsch bei jeder Benutzeranmeldung im Hintergrund (`SMAppService` / `LaunchAgent`). Lässt sich im Menüleisten-Icon und in den Einstellungen mit einem Klick ein-/ausschalten.

---

## 📦 Installation & Deinstallation

### 1. In den Programme-Ordner installieren

#### Methode A: Über das native DMG-Image (klassisch per Drag & Drop)
Doppelklicke auf:
👉 **`MacTab.dmg`**
Ziehe `MacTab.app` einfach per Drag-and-Drop auf die Verknüpfung `Applications`. Fertig!

#### Methode B: Per Doppelklick-Installer im Finder
Doppelklicke auf die Datei:
👉 **`Install_MacTab.command`**
(Alternativ im Terminal: `./install.sh`)

Das Skript baut automatisch die Release-Version von MacTab, beendet vorherige Versionen sauber, kopiert `MacTab.app` nach `/Applications/MacTab.app`, richtet den Autostart ein, entfernt Quarantäne-Attribute und startet die App direkt.

#### Methode C: Direkt aus der App heraus
Wenn du `MacTab.app` aus dem Projektordner startest (`open MacTab.app`), findest du sowohl im **Menüleisten-Symbol** als auch in den **Einstellungen** die Option **"In Programme-Ordner installieren"**. Ein Klick kopiert die App nach `/Applications`, startet sie von dort und beendet die lokale Instanz.

---

### 2. Deinstallieren

#### Methode A: Per Doppelklick im Finder
Doppelklicke einfach auf die Datei:
👉 **`Uninstall_MacTab.command`**
(Alternativ im Terminal: `./uninstall.sh`)

Das Skript beendet die App, entfernt `/Applications/MacTab.app` (sowie eventuelle Kopien in `~/Applications`), setzt gespeicherte Benutzereinstellungen zurück und bereinigt Caches.

#### Methode B: Direkt aus der App heraus
Im Menüleisten-Icon oder in den **Einstellungen** auf **"MacTab deinstallieren..."** klicken. Nach Bestätigung der Sicherheitsabfrage löscht sich die App aus `/Applications`, setzt ihre Einstellungen zurück und beendet sich.

---

## 🔑 Berechtigungen vergeben & Probleme beheben

macOS benötigt für Fenster-Umschalter zwei Standard-Berechtigungen (erreichbar über das Menüleisten-Icon -> *Einstellungen*):
1. **Bedienungshilfen (Accessibility)**: Zum Erkennen und Steuern/Aktivieren von Fenstern.
2. **Bildschirmaufnahme (Screen Recording)**: Zum Anzeigen von Live-Fenster-Vorschauen (Thumbnails).

### ⚠️ Schalter lässt sich nicht aktivieren oder Rechte werden nicht erkannt? (TCC-Reset)
Wenn macOS nach einem Update oder Build die Berechtigungen "einfriert" oder nicht mehr akzeptiert:
- **Lösung 1 (Per Doppelklick)**: Doppelklicke auf 👉 **`Reset_Permissions.command`**.
  Dieses Skript setzt die macOS-Sicherheitsdatenbank (TCC) für MacTab sauber zurück (`tccutil reset`), öffnet die Systemeinstellungen und startet die App neu.
- **Lösung 2 (In der App)**: In den MacTab-*Einstellungen* unter *System Permissions* auf **"Rechte zurücksetzen"** klicken.
- **Lösung 3 (Manuell in macOS Systemeinstellungen)**:
  Unter *Systemeinstellungen* -> *Datenschutz & Sicherheit* -> *Bedienungshilfen*: Wähle `MacTab` aus und klicke auf das **Minus [-]**, um den veralteten Eintrag zu löschen. Starte MacTab dann neu und bestätige den Dialog.

---

## 💿 DMG Disk Image erstellen (zur Weitergabe)

Du kannst jederzeit ein frisches, komprimiertes Disk Image erzeugen:
- **Per Doppelklick**: 👉 **`Create_DMG.command`**
- **Oder im Terminal**:
  ```bash
  ./create_dmg.sh
  ```
Erzeugt die Datei `MacTab.dmg` im Projektordner mit integrierter `Applications`-Verknüpfung und Installationshinweis – ideal zum Weitergeben an andere Macs!

---

## 📜 Changelog

### Version 0.2.0 (21. Oktober 2026)
- 🔲 **Umrandung des echten Fensters**: Das im Switcher ausgewählte Fenster wird auf dem Bildschirm farbig umrandet (klick-durchlässiges Overlay, abschaltbar).

### Version 0.1.0 (20. Oktober 2026) - Initialer Release
- ✨ **Initialer Release**: Schlanker, nativer und performanter Fenster-Umschalter für macOS.
- ⚡ **Stabilitäts-Boost**: 150ms strikte AX-Timeouts (`AXUIElementSetMessagingTimeout`) verhindern UI-Freezes durch blockierte Apps.
- 🛡 **Auto-Healing Event Tap**: Automatisches Wiederherstellen stummgeschalteter Shortcuts mit 1,5s Heartbeat-Watchdog.
- 📐 **4-Spalten-Raster**: Automatischer Zeilenumbruch ab dem 5. Fenster mit 2D-Tastaturnavigation (`↑`/`↓`/`←`/`→`).
- 🔄 **MRU-Priorisierung**: Zuletzt aktives Fenster steht immer direkt an Index 1 der Auswahl (perfektes Hin- und Herwechseln).
- 🎯 **Exklusives Highlighting**: Nur das aktiv gewählte Fenster wird akzentuiert; sofortiges Ent-Highlighten beim Weiterschalten.
- ℹ️ **Dezentes Info-Icon**: Schnellübersicht aller Kurzbefehle als kompaktes Hilfe-Symbol (`?`) unten rechts.
- 🚀 **Autostart-Unterstützung**: Nahtlose Integration in `SMAppService` und macOS-LaunchAgent.
- 💿 **Native Distribution**: Bereitstellung von `MacTab.dmg`, Doppelklick-Skripten und In-App Installer/Uninstaller.
- 🔑 **TCC-Sicherheit**: Integrierter Berechtigungs-Reset bei macOS-Sicherheitskonflikten.

---

## 📁 Projektstruktur

```
MacTab/
├── Package.swift                    # Swift Package Manager Manifest (macOS 13+)
├── Resources/
│   └── Info.plist                   # Bundle-ID com.mactab.app, Version, LSUIElement
├── Sources/MacTab/
│   ├── main.swift                   # Einstiegspunkt (NSApplication + AppDelegate)
│   ├── AppDelegate.swift            # App-Start, Statusleiste, Keyboard-Hook-Delegate
│   ├── KeyboardHook.swift           # Globaler CGEventTap mit Auto-Healing & Watchdog
│   ├── WindowEngine.swift           # Fenstererkennung (CGWindowList + AX), Fokus, Schließen
│   ├── WindowModel.swift            # Datenmodell eines Fensters
│   ├── ThumbnailEngine.swift        # Vorschaubilder mit Downscaling & LRU-Cache
│   ├── SwitcherView.swift           # SwiftUI-HUD (4er-Raster, Kacheln, Hilfe-Icon)
│   ├── SwitcherWindowController.swift # NSPanel des Switchers, Größe, Auswahl-Sync
│   ├── WindowHighlightOverlay.swift # Rahmen um das echte ausgewählte Fenster
│   ├── StatusBarController.swift    # Menüleisten-Icon und Menü
│   ├── PreferencesView.swift        # Einstellungsfenster inkl. Changelog
│   ├── PreferencesManager.swift     # Persistente Einstellungen (UserDefaults)
│   ├── PermissionsManager.swift     # Bedienungshilfen/Bildschirmaufnahme, TCC-Reset
│   ├── InstallationManager.swift    # In-App Installation/Deinstallation
│   └── LaunchAtLoginManager.swift   # Autostart (SMAppService + LaunchAgent)
├── build.sh                         # Release-Build + Bundle + stabile Signatur
├── install.sh / Install_MacTab.command         # Installation nach /Applications
├── uninstall.sh / Uninstall_MacTab.command     # Rückstandslose Deinstallation
├── Reset_Permissions.command        # TCC-Berechtigungen zurücksetzen
├── create_dmg.sh / Create_DMG.command          # MacTab.dmg erzeugen
├── deploy_release.sh                # Automatisiertes DMG-Build & GitHub Release Deployment
├── MacTab.app                       # Zuletzt gebautes App-Bundle (Build-Ergebnis)
├── MacTab.dmg                       # Disk Image zur Weitergabe (Build-Ergebnis)
└── README.md
```

---

## 🛠 Technische Details

- **Sprache**: Swift 6 / modernstes Swift 5 API
- **Frameworks**: SwiftUI, AppKit, ApplicationServices (Accessibility), CoreGraphics
- **Größe**: Nur ~700 KB (keine externen Abhängigkeiten oder Framework-Bloat)
- **Kompatibilität**: macOS 13.0+ (Ventura, Sonoma, Sequoia) – Universal / Apple Silicon (M1/M2/M3/M4) optimiert.
