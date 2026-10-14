#!/bin/sh
# Downloads the Keen 1 shareware release (version 1.1) and unpacks it into
# game_data/keen1/, so that the game can be played straight away.
#
# Episode 1 was released by its makers as freely distributable shareware. It
# is never part of this repository: this script fetches the diskette image
# that PCjs keeps in the public GitHub repository jeffpar/pcjs-gamedisks, and
# tools/extract_pcjs_diskette.py checks every file against its MD5 hash.
#
# Usage:
#   tools/get_shareware.sh [FOLDER]     (default: game_data/keen1)
#
# Files that are already in the folder are kept: then nothing is downloaded.
set -e
cd "$(dirname "$0")/.."

TARGET=${1:-game_data/keen1}
URL=https://raw.githubusercontent.com/jeffpar/pcjs-gamedisks/master/pcx86/game/id/commander_keen/KEEN1-V11.json

if ls "$TARGET"/*.CK1 >/dev/null 2>&1 || ls "$TARGET"/*.ck1 >/dev/null 2>&1; then
	echo "$TARGET already holds game files; nothing to do."
	exit 0
fi

DOWNLOAD=$(mktemp -d)
trap 'rm -rf "$DOWNLOAD"' EXIT
echo "Downloading the Keen 1 shareware diskette..."
curl -fsSL -o "$DOWNLOAD/KEEN1-V11.json" "$URL"
mkdir -p "$TARGET"
python3 tools/extract_pcjs_diskette.py "$DOWNLOAD/KEEN1-V11.json" "$TARGET"
echo "Done: the game files are in $TARGET. Start the game with: godot --path ."
