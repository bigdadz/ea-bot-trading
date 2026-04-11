#!/bin/bash
# Deploy GoldScalper EA to MetaTrader 5
# Usage: ./deploy.sh

SRC="$(cd "$(dirname "$0")" && pwd)"
DST="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5"

if [ ! -d "$DST" ]; then
    echo "ERROR: MT5 directory not found: $DST"
    exit 1
fi

# Create target directories
mkdir -p "$DST/Experts/GoldScalper"
mkdir -p "$DST/Include/GoldScalper"

# Copy EA files
cp "$SRC/Experts/GoldScalper/"*.mq5 "$DST/Experts/GoldScalper/"
cp "$SRC/Include/GoldScalper/"*.mqh "$DST/Include/GoldScalper/"

echo "Deployed to: $DST"
echo "  Experts: $(ls "$DST/Experts/GoldScalper/" | wc -l | tr -d ' ') files"
echo "  Include: $(ls "$DST/Include/GoldScalper/" | wc -l | tr -d ' ') files"
echo ""
echo "Next: Open MetaEditor -> Compile (F7)"
