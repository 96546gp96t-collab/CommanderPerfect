#!/bin/sh
# Builds build/windows/CommanderPerfect.exe (64-bit, with the game inside the
# .exe) and copies the game files next to it, so that the whole
# build/windows folder can be copied to a Windows PC and started there.
#
# Runs on the Mac (or Linux); needs the Godot 4.7.2 export templates for
# Windows (windows_release_x86_64.exe in the export_templates folder of
# Godot). The game files are only copied into build/, which git ignores;
# they are never part of the repository.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/windows
godot --headless --path . --export-release "Windows Desktop" build/windows/CommanderPerfect.exe
if [ -d game_data/keen1 ]; then
	rm -rf build/windows/game_data
	mkdir -p build/windows/game_data
	cp -R game_data/keen1 build/windows/game_data/
fi
echo "Built build/windows/CommanderPerfect.exe"
