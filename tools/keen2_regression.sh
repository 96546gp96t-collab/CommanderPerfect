#!/bin/sh
# Takes a fixed set of Keen 2 screenshots (title, level 1, a walk in level
# 1, the world map), so that a later milestone can show that Keen 2 still
# looks exactly the same. The same shape as tools/keen1_regression.sh, but
# for Keen 2: it needs the player's own Keen 2 files in game_data/keen2 and
# a display (on Linux it uses xvfb-run). The start screen is left out: it
# changes whenever a game is added.
#
# Usage:
#   tools/keen2_regression.sh OUT_DIR              take the screenshots
#   tools/keen2_regression.sh OUT_DIR BASE_DIR     ... and compare them with
#                                                  an earlier set; exits 1 on
#                                                  any difference
#
# Make BASE_DIR from the reference commit first (a git worktree, see
# docs/keen3/architecture.md), then run it again on the milestone branch.
set -e
cd "$(dirname "$0")/.."

OUT=${1:?usage: tools/keen2_regression.sh OUT_DIR [BASE_DIR]}
BASE=$2
mkdir -p "$OUT"

if command -v xvfb-run >/dev/null 2>&1; then
	RUN="xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60"
else
	RUN="godot --fixed-fps 60"
	# A new macOS window stays blank for a varying number of frames.
	export WAIT_FOR_WINDOW=1
fi

SCENE=res://src/keen2/keen2_view.tscn

shoot() {
	# $1 = STEPS, rest = game options (after --game=2)
	steps=$1
	shift
	STEPS="$steps" SCENE="$SCENE" OUT="$OUT" $RUN --path . \
		--script res://tools/scripted_play.gd -- --game=2 "$@" >/dev/null 2>&1
}

shoot "40:shot_keen2_title"
shoot "40:shot_keen2_level1,60:hold_Right,100:shot_keen2_level1_walk,101:up_Right" --level=1
# Keen 2 has no --level=80: open the menu (Space), start a new game
# (Enter) and wait until the Keens Left box is gone.
shoot "40:Space,80:Enter,320:shot_keen2_map"

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
