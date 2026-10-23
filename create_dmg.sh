#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "  MacTab - DMG Disk Image Ersteller"
echo "=========================================="
echo ""

# 1. Sicherstellen, dass die aktuelle Release-App gebaut ist
echo "[1/4] Erstelle frischen Release-Build..."
"$DIR/build.sh"

# 2. Temporäres Staging-Verzeichnis vorbereiten
echo "[2/4] Bereite DMG-Inhalte vor..."
DMG_TEMP="$DIR/.dmg_staging"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# App kopieren
cp -R "$DIR/MacTab.app" "$DMG_TEMP/MacTab.app"

# Lizenz beilegen
cp "$DIR/LICENSE" "$DMG_TEMP/LICENSE.txt"

# Drag-and-Drop Symlink zu /Applications erstellen
ln -s /Applications "$DMG_TEMP/Applications"

# Kurze Installationsanleitung beilegen
cat << 'EOF' > "$DMG_TEMP/Installationshinweis.txt"
==================================================
  MacTab - Schnellanleitung zur Installation
==================================================

1. Ziehe "MacTab.app" einfach nach rechts auf den
   Ordner "Applications" (Programme).

2. Starte MacTab aus deinem Programme-Ordner
   (oder über Spotlight mit Cmd+Leertaste).

3. Wichtig beim ersten Start (macOS Berechtigungen):
   Damit MacTab Fenster erkennen und umschalten kann,
   benötigt es zwei Freigaben unter:
   Systemeinstellungen -> Datenschutz & Sicherheit
   - Bedienungshilfen (Accessibility)
   - Bildschirmaufnahme (Screen Recording für Fenster-Vorschauen)

4. Steuerung:
   Drücke Option (Alt) + Tab, um durch deine Fenster
   zu blättern. Lass die Taste los, um zum gewählten
   Fenster zu wechseln!

5. Lizenz:
   Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)
   Urheber: mrgoldsmitt (https://github.com/mrgoldsmitt/MacTab)
   Kopieren & Verteilen erlaubt unter Nennung des Autors. Nicht-kommerziell.

Viel Spaß mit MacTab!
EOF

# Changelog beilegen
cat << 'EOF' > "$DMG_TEMP/Changelog.txt"
==================================================
  MacTab - Changelog
==================================================

Version 0.2.0 (21. Oktober 2026)
--------------------------------------------------
- Das echte Fenster wird auf dem Bildschirm farbig umrandet, solange es im
  Switcher ausgewählt ist (in den Einstellungen abschaltbar).

Version 0.1.0 (20. Oktober 2026) - Initialer Release
--------------------------------------------------
- Initialer Release: Schlanker & stabiler nativer Fenster-Umschalter für macOS.
- 150ms AX-Timeouts & Auto-Healing Event Tap (verhindert Hänger unresponsiver Apps).
- 4-Spalten-Raster mit automatischem Zeilenumbruch & 2D-Tastaturnavigation (↑/↓/←/→).
- MRU-Fokus: Zuletzt aktives Fenster steht immer direkt als nächstes zur Auswahl.
- Präzises Einzelfenster-Highlighting ohne überlappende Markierungen.
- Kompaktes Tastatur-Hilfe-Icon unten rechts im Switcher-HUD.
- Automatischer Systemstart (Launch at Login via SMAppService & LaunchAgent).
- In-App Installation nach /Applications, Uninstaller & MacTab.dmg zur Weitergabe.
- TCC-Berechtigungsmanager mit Reset-Funktion bei Systemkonflikten.
EOF

# 3. Vorheriges DMG löschen, falls vorhanden
DMG_OUTPUT="$DIR/MacTab.dmg"
if [ -f "$DMG_OUTPUT" ]; then
    rm -f "$DMG_OUTPUT"
fi

# 4. DMG mit hdiutil erstellen (komprimiert via UDZO)
echo "[3/4] Erzeuge komprimiertes Disk Image (UDZO)..."
hdiutil create \
    -volname "MacTab" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT"

# Bereinigung
rm -rf "$DMG_TEMP"

echo "[4/4] Fertig!"
echo ""
echo "=========================================="
echo "  Erfolgreich erstellt: $DMG_OUTPUT"
echo "  Größe: $(du -h "$DMG_OUTPUT" | cut -f1)"
echo "=========================================="
