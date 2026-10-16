#!/bin/sh
# Takes a fixed set of Keen 1 screenshots (start screen, title, level 1, a
# walk in level 1, the world map), so that a later milestone can show that
# Keen 1 still looks exactly the same. Needs the Keen 1 game data and a
# display (on Linux it uses xvfb-run).
#
# Usage:
#   tools/keen1_regression.sh OUT_DIR              take the screenshots
#   tools/keen1_regression.sh OUT_DIR BASE_DIR     ... and compare them with
#                                                  an earlier set; exits 1 on
#                                                  any difference
#
# Make BASE_DIR from main first (git stash or a worktree), then run it again
# on the milestone branch.
set -e
cd "$(dirname "$0")/.."

OUT=${1:?usage: tools/keen1_regression.sh OUT_DIR [BASE_DIR]}
BASE=$2
mkdir -p "$OUT"

if command -v xvfb-run >/dev/null 2>&1; then
	RUN="xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60"
else
	RUN="godot --fixed-fps 60"
fi

shoot() {
	# $1 = STEPS, $2 = scene (empty for the game screen), rest = game options
	steps=$1
	scene=$2
	shift 2
	STEPS="$steps" SCENE="$scene" OUT="$OUT" $RUN --path . \
		--script res://tools/scripted_play.gd -- "$@" >/dev/null 2>&1
}

shoot "30:shot_launcher" "res://src/launcher/launcher.tscn"
shoot "40:shot_title" ""
shoot "40:shot_level1,60:hold_Right,100:shot_level1_walk,101:up_Right" "" --level=1
shoot "40:shot_map" "" --level=80

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
