#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "  MacTab Installer für macOS"
echo "=========================================="
echo ""

# 1. Sicherstellen, dass die Release-App gebaut ist
echo "[1/4] Erstelle Release-Build von MacTab..."
"$DIR/build.sh"

# 2. Laufende MacTab-Instanzen beenden
echo "[2/4] Beende eventuell laufende MacTab-Instanzen..."
pkill -x "MacTab" 2>/dev/null || true
sleep 1

# 3. In /Applications installieren
echo "[3/4] Installiere in /Applications/MacTab.app..."
TARGET_DIR="/Applications/MacTab.app"

if [ -d "$TARGET_DIR" ]; then
    echo "      Entferne vorherige Version in /Applications..."
    rm -rf "$TARGET_DIR"
fi

cp -R "$DIR/MacTab.app" "$TARGET_DIR"
xattr -dr com.apple.quarantine "$TARGET_DIR" 2>/dev/null || true
codesign --force --deep -s - --requirements '=designated => identifier "com.mactab.app"' "$TARGET_DIR" 2>/dev/null || true

# 4. Autostart bei Systemstart einrichten (LaunchAgent)
echo "[4/5] Richte Autostart bei Systemstart ein..."
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.mactab.app.plist"
mkdir -p "$LAUNCH_AGENT_DIR"
cat << 'EOF' > "$LAUNCH_AGENT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mactab.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/MacTab.app/Contents/MacOS/MacTab</string>
    </array>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
echo "      ✓ Autostart-Eintrag für MacTab registriert."

# 5. Fertigstellen & Starten
echo "[5/5] Installation erfolgreich abgeschlossen!"
echo ""
echo "MacTab liegt nun in: /Applications/MacTab.app"
echo ""
echo "Möchtest du MacTab jetzt starten? (J/n)"
read -r -t 10 response || response="j"
if [[ "$response" =~ ^[Nn] ]]; then
    echo "MacTab kann jederzeit über Spotlight oder 'open /Applications/MacTab.app' gestartet werden."
else
    echo "Starte MacTab..."
    open "$TARGET_DIR"
fi
echo ""
echo "Hinweis: Bitte stelle sicher, dass MacTab in den macOS Systemeinstellungen"
echo "unter 'Datenschutz & Sicherheit' die Berechtigungen für"
echo "'Bedienungshilfen' und 'Bildschirmaufnahme' erteilt sind."
echo "=========================================="
