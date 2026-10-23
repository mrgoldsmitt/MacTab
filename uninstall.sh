#!/usr/bin/env bash
set -e

echo "=========================================="
echo "  MacTab Uninstaller für macOS"
echo "=========================================="
echo ""

# 1. Laufende Instanz beenden
echo "[1/3] Beende laufende MacTab-Instanzen..."
pkill -x "MacTab" 2>/dev/null || true
sleep 1

# 2. App-Bundle entfernen
echo "[2/3] Entferne MacTab aus /Applications..."
REMOVED=0
if [ -d "/Applications/MacTab.app" ]; then
    rm -rf "/Applications/MacTab.app"
    echo "      ✓ /Applications/MacTab.app gelöscht."
    REMOVED=1
fi

if [ -d "$HOME/Applications/MacTab.app" ]; then
    rm -rf "$HOME/Applications/MacTab.app"
    echo "      ✓ $HOME/Applications/MacTab.app gelöscht."
    REMOVED=1
fi

if [ $REMOVED -eq 0 ]; then
    echo "      Keine MacTab.app im Programme-Ordner gefunden."
fi

# 3. Autostart / LaunchAgent entfernen
echo "[3/4] Entferne Autostart / LaunchAgent..."
rm -f "$HOME/Library/LaunchAgents/com.mactab.app.plist" 2>/dev/null || true
echo "      ✓ Autostart-Eintrag bereinigt."

# 4. Einstellungen und Caches zurücksetzen
echo "[4/4] Bereinige Einstellungen und Caches..."
defaults delete com.mactab.app 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.mactab.app" 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/MacTab" 2>/dev/null || true
echo "      ✓ Konfiguration bereinigt."

echo ""
echo "=========================================="
echo "  MacTab wurde erfolgreich deinstalliert!"
echo "=========================================="
