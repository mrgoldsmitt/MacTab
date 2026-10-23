#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# 1. Version aus Resources/Info.plist ermitteln
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$DIR/Resources/Info.plist" 2>/dev/null || echo "0.2.0")
TAG="v$VERSION"

echo "=========================================="
echo "  MacTab - Release & Deployment ($TAG)"
echo "=========================================="
echo ""

# 2. Disk Image bauen
echo "[1/3] Baue Release-DMG..."
"$DIR/create_dmg.sh"

# 3. Prüfen ob gh CLI verfügbar und eingeloggt ist
echo "[2/3] Prüfe GitHub CLI Status..."
if ! command -v gh &> /dev/null; then
    echo "Fehler: 'gh' CLI ist nicht installiert."
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "Fehler: 'gh' ist nicht authentifiziert. Bitte 'gh auth login' ausführen."
    exit 1
fi

# 4. Release auf GitHub erstellen oder aktualisieren
echo "[3/3] Erstelle / aktualisiere GitHub Release $TAG..."
DMG_FILE="$DIR/MacTab.dmg"

if [ ! -f "$DMG_FILE" ]; then
    echo "Fehler: $DMG_FILE wurde nicht gefunden."
    exit 1
fi

NOTES_FILE="$DIR/.release_notes_tmp.txt"
cat << 'EOF' > "$NOTES_FILE"
## MacTab v0.2.0

Ein moderner, schlanker und hochperformanter nativer Fenster-Umschalter (Alt-Tab Switcher) für macOS.

### ✨ Highlights
- **150ms AX-Timeouts & Auto-Healing Event Tap**: Verhindert Freezes und UI-Hänger unresponsiver Apps zuverlässig.
- **4-Spalten-Raster mit 2D-Tastaturnavigation**: Übersichtliche Kacheln mit automatischem Zeilenumbruch und Pfeiltasten-Steuerung (↑/↓/←/→).
- **MRU-Fokus (Most Recently Used)**: Zuletzt aktives Fenster steht immer direkt an erster Stelle (Index 1) für sofortiges Hin- und Herwechseln.
- **Echtes Fenster-Highlighting**: Das im Switcher ausgewählte Fenster wird zusätzlich direkt auf dem Bildschirm farbig umrandet.
- **Leichtgewicht**: Vollständig in Swift/SwiftUI/AppKit geschrieben, Gesamtspeicher unter 35 MB, keine externen Abhängigkeiten.
- **Native Installation**: Drag-and-Drop Installation via DMG, Autostart-Unterstützung (Launch at Login) und Berechtigungsmanager.

### 📦 Installation
1. Lade unten unter **Assets** die Datei **`MacTab.dmg`** herunter.
2. Öffne die DMG und ziehe **MacTab** in deinen Programme-Ordner (`Applications`).
3. Starte MacTab und erteile die zwei notwendigen macOS-Berechtigungen (*Bedienungshilfen* und *Bildschirmaufnahme*).

### 📄 Lizenz
Lizenziert unter **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**.
Urheber & Copyright: **mrgoldsmitt** (Kopieren, Weitergeben und Modifizieren gestattet unter Namensnennung, keine kommerzielle Nutzung).
EOF

if gh release view "$TAG" &> /dev/null; then
    echo "Aktualisiere bestehenden Release $TAG..."
    gh release upload "$TAG" "$DMG_FILE" --clobber
    gh release edit "$TAG" --title "MacTab $TAG" --notes-file "$NOTES_FILE"
else
    echo "Erstelle neuen Release $TAG..."
    gh release create "$TAG" "$DMG_FILE" --title "MacTab $TAG" --notes-file "$NOTES_FILE"
fi

rm -f "$NOTES_FILE"

echo ""
echo "=========================================="
echo "  Release $TAG erfolgreich veröffentlicht!"
echo "=========================================="
