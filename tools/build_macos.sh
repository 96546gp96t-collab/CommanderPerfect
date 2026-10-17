#!/bin/sh
# Builds build/CommanderPerfect.app and copies the game files (Keen 1 and,
# when present, Keen 2 and Keen 3) next to it, so that the app can be
# started with a double click.
#
# Needs the Godot 4.7.2 export template for macOS. The game files are only
# copied into build/, which git ignores; they are never part of the
# repository.
set -e
cd "$(dirname "$0")/.."
mkdir -p build
godot --headless --path . --export-release "macOS" build/CommanderPerfect.app
if [ -d game_data/keen1 ]; then
	mkdir -p build/game_data
	cp -R game_data/keen1 build/game_data/
fi
if [ -d game_data/keen2 ]; then
	mkdir -p build/game_data
	cp -R game_data/keen2 build/game_data/
fi
if [ -d game_data/keen3 ]; then
	mkdir -p build/game_data
	cp -R game_data/keen3 build/game_data/
fi
echo "Built build/CommanderPerfect.app"
