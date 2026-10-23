#!/bin/bash
# MacTab - DMG Disk Image Ersteller (per Doppelklick im Finder ausführbar)

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "  MacTab - DMG Erstellung"
echo "=========================================="
echo ""

"$DIR/create_dmg.sh"

echo ""
echo "=========================================="
echo "  Fertig! Du findest 'MacTab.dmg' im Ordner:"
echo "  $DIR"
echo "=========================================="
echo ""
read -n 1 -s -r -p "Drücke eine beliebige Taste zum Beenden..."
echo ""
