#!/bin/bash
# Mafad One Plus Desktop Pro Runner
cd "$(dirname "$0")"

if [ -f "./build/linux/x64/release/bundle/mafad_desktop" ]; then
    echo "Starting Mafad One Plus Desktop (Release)..."
    ./build/linux/x64/release/bundle/mafad_desktop "$@"
else
    echo "Starting with flutter run..."
    flutter run -d linux
fi
