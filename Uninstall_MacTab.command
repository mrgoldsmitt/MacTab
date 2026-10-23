#!/bin/bash
# MacTab - Uninstaller (per Doppelklick im Finder ausführbar)

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "  MacTab Uninstaller (macOS)"
echo "=========================================="
echo ""

# Ausführen des Deinstallations-Skripts
"$DIR/uninstall.sh"

echo ""
echo "=========================================="
echo "  Fertig! Du kannst dieses Fenster schließen."
echo "=========================================="
echo ""
read -n 1 -s -r -p "Drücke eine beliebige Taste zum Beenden..."
echo ""
