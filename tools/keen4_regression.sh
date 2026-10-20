#!/bin/sh
# Takes a fixed set of Keen 4 screenshots (level 1 and level 11, each in
# widescreen and in 4:3), so that a later milestone can show that Keen 4
# still looks exactly the same. The same shape as
# tools/keen2_regression.sh: it needs the player's own Keen 4 files in
# game_data/keen4 and a display (on Linux it uses xvfb-run). The title
# follows once Keen 4 has one (D8). Run it with an empty user folder: F2
# switches between widescreen and 4:3 and is remembered (each run switches
# back at the end).
#
# Usage:
#   tools/keen4_regression.sh OUT_DIR              take the screenshots
#   tools/keen4_regression.sh OUT_DIR BASE_DIR     ... and compare them with
#                                                  an earlier set; exits 1 on
#                                                  any difference
set -e
cd "$(dirname "$0")/.."

OUT=${1:?usage: tools/keen4_regression.sh OUT_DIR [BASE_DIR]}
BASE=$2
mkdir -p "$OUT"

if command -v xvfb-run >/dev/null 2>&1; then
	RUN="xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60"
else
	RUN="godot --fixed-fps 60"
	# A new macOS window stays blank for a varying number of frames.
	export WAIT_FOR_WINDOW=1
fi

SCENE=res://src/keen4/keen4_view.tscn

shoot() {
	# $1 = STEPS, rest = game options (after --game=4)
	steps=$1
	shift
	STEPS="$steps" SCENE="$SCENE" OUT="$OUT" $RUN --path . \
		--script res://tools/scripted_play.gd -- --game=4 "$@" >/dev/null 2>&1
}

shoot "40:shot_keen4_level1_wide,41:F2,50:shot_keen4_level1,51:F2" --level=1
shoot "40:shot_keen4_level11_wide,41:F2,50:shot_keen4_level11,51:F2" --level=11

if [ -n "$BASE" ]; then
	status=0
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
