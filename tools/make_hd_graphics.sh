#!/bin/sh
# Makes HD graphics from your own Keen 1 files with Real-ESRGAN, on your own
# computer. The game picks them up as Options > Graphics > HD (or F5).
#
# The result is derived from the original game files: it is written next to
# them (game_data/keen1/hd/), which git ignores, and must not be shared.
#
# Needs realesrgan-ncnn-vulkan, the portable version of Real-ESRGAN:
# download the zip for your system from
#   https://github.com/xinntao/Real-ESRGAN/releases
# and unpack it. Then either put the folder on your PATH or point to the
# program:
#   REALESRGAN=~/Downloads/realesrgan-ncnn-vulkan/realesrgan-ncnn-vulkan \
#     tools/make_hd_graphics.sh
#
# Options (environment variables):
#   REALESRGAN  the upscaler program (default: realesrgan-ncnn-vulkan)
#   MODEL       the model (default: realesrgan-x4plus-anime, made for
#               drawings; realesrgan-x4plus is the general one)
#   DATA_DIR    the folder with the game files (default: game_data/keen1)
#
# On macOS the downloaded program may first need to be allowed:
#   xattr -d com.apple.quarantine path/to/realesrgan-ncnn-vulkan
set -e
cd "$(dirname "$0")/.."

UPSCALER=${REALESRGAN:-realesrgan-ncnn-vulkan}
MODEL=${MODEL:-realesrgan-x4plus-anime}
DATA_DIR=${DATA_DIR:-game_data/keen1}
SHEETS=exported/hd_sheets

if ! command -v "$UPSCALER" >/dev/null 2>&1; then
	echo "Real-ESRGAN ($UPSCALER) not found. See the comment at the top of $0." >&2
	exit 1
fi
UPSCALER=$(command -v "$UPSCALER")
# The models come with the program, in a folder next to it.
MODELS=$(dirname "$UPSCALER")/models

rm -rf "$SHEETS"
mkdir -p "$SHEETS"
godot --headless --path . --script res://tools/export_hd_sheets.gd -- \
	--out="$PWD/$SHEETS" --data-dir="$DATA_DIR"

# Upscale into a new folder first, so that a failed run keeps the old one.
rm -rf "$DATA_DIR/hd.new"
mkdir -p "$DATA_DIR/hd.new"
if [ -d "$MODELS" ]; then
	"$UPSCALER" -i "$SHEETS" -o "$DATA_DIR/hd.new" -n "$MODEL" -s 4 -f png -m "$MODELS"
else
	"$UPSCALER" -i "$SHEETS" -o "$DATA_DIR/hd.new" -n "$MODEL" -s 4 -f png
fi
rm -rf "$DATA_DIR/hd"
mv "$DATA_DIR/hd.new" "$DATA_DIR/hd"
rm -rf "$SHEETS"

# The Mac app reads the copy of the game files next to it.
if [ -d build/game_data/keen1 ] && [ "$DATA_DIR" = game_data/keen1 ]; then
	rm -rf build/game_data/keen1/hd
	cp -R "$DATA_DIR/hd" build/game_data/keen1/
fi
echo "HD graphics written to $DATA_DIR/hd. Pick them in Options > Graphics, or press F5."
