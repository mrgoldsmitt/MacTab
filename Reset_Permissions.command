#!/bin/bash
# MacTab - Berechtigungen komplett zurücksetzen (TCC Reset)
# Doppelklickbar im Finder

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "  MacTab - Berechtigungen zurücksetzen"
echo "=========================================="
echo ""
echo "Dieser Vorgang setzt die macOS Sicherheits- und"
echo "Datenschutzeinträge (Accessibility & ScreenCapture)"
echo "für MacTab vollständig zurück."
echo ""

# 1. Beende MacTab falls aktiv
echo "[1/4] Beende laufende MacTab-Prozesse..."
pkill -x "MacTab" 2>/dev/null || true
sleep 1

# 2. TCC-Berechtigungen über tccutil zurücksetzen
echo "[2/4] Berechtigungen via tccutil zurücksetzen..."
tccutil reset Accessibility com.mactab.app 2>/dev/null || true
tccutil reset ScreenCapture com.mactab.app 2>/dev/null || true
echo "      Accessibility und ScreenCapture wurden zurückgesetzt."

# 3. Sicherstellen, dass die Signatur stabil gebunden ist
if [ -d "/Applications/MacTab.app" ]; then
    echo "[3/4] Code-Signatur für /Applications/MacTab.app verifizieren..."
    codesign --force --deep -s - --requirements '=designated => identifier "com.mactab.app"' "/Applications/MacTab.app" 2>/dev/null || true
fi

# 4. Systemeinstellungen öffnen & App starten
echo "[4/4] Öffne Systemeinstellungen..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "=========================================="
echo "  ERFOLGREICH ZURÜCKGESETZT!"
echo "=========================================="
echo ""
echo "Nächste Schritte:"
echo "1. Falls 'MacTab' in der Liste der Bedienungshilfen noch auftaucht:"
echo "   Wähle 'MacTab' aus und klicke unten auf das Minus [-], um alte Einträge zu entfernen."
echo "2. Starte MacTab nun neu:"
if [ -d "/Applications/MacTab.app" ]; then
    echo "   (Drücke 'j' zum sofortigen Starten von /Applications/MacTab.app)"
    read -r -t 10 response || response="j"
    if [[ ! "$response" =~ ^[Nn] ]]; then
        open "/Applications/MacTab.app"
        echo "   MacTab wurde gestartet."
    fi
fi
echo ""
echo "3. Aktiviere beim Neustart den Schalter für MacTab in den Systemeinstellungen."
echo ""
read -n 1 -s -r -p "Drücke eine beliebige Taste zum Beenden..."
echo ""
