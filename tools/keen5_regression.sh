#!/bin/sh
# Takes a fixed set of Keen 5 screenshots (level 1 and level 11, each in
# widescreen and in 4:3; milestone E3), so that a later milestone can show
# that Keen 5 still looks the same. The same shape as
# tools/keen4_regression.sh: it needs the player's own Keen 5 files in
# game_data/keen5 and a display (on Linux it uses xvfb-run). Run it with an
# empty user folder: F2 switches between widescreen and 4:3 and is
# remembered (each run switches back at the end).
#
# Usage:
#   tools/keen5_regression.sh OUT_DIR              take the screenshots
#   tools/keen5_regression.sh OUT_DIR BASE_DIR     ... and compare them with
#                                                  an earlier set; exits 1 on
#                                                  any difference
set -e
cd "$(dirname "$0")/.."

OUT=${1:?usage: tools/keen5_regression.sh OUT_DIR [BASE_DIR]}
BASE=$2
mkdir -p "$OUT"

if command -v xvfb-run >/dev/null 2>&1; then
	RUN="xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60"
else
	RUN="godot --fixed-fps 60"
	# A new macOS window stays blank for a varying number of frames.
	export WAIT_FOR_WINDOW=1
fi

SCENE=res://src/keen5/keen5_view.tscn

shoot() {
	# $1 = STEPS, rest = game options (after --game=5)
	steps=$1
	shift
	STEPS="$steps" SCENE="$SCENE" OUT="$OUT" $RUN --path . \
		--script res://tools/scripted_play.gd -- --game=5 "$@" >/dev/null 2>&1
}

shoot "40:shot_keen5_level1_wide,41:F2,50:shot_keen5_level1,51:F2" --level=1
shoot "40:shot_keen5_level11_wide,41:F2,50:shot_keen5_level11,51:F2" --level=11

if [ -n "$BASE" ]; then
	status=0
	for picture in "$OUT"/*.png; do
		name=$(basename "$picture")
		[ -f "$BASE/$name" ] || echo "NEW        $name"
	done
	for picture in "$BASE"/*.png; do
		name=$(basename "$picture")
		if cmp -s "$picture" "$OUT/$name"; then
			echo "same       $name"
		else
			echo "DIFFERENT  $name"
			status=1
		fi
	done
	exit $status
fi
echo "Screenshots in $OUT"
