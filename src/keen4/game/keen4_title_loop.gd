class_name Keen4TitleLoop
extends RefCounted
## The order of Keen 4's title loop, what plays while nobody plays (Omni
## `ck_main.c`: CK_DemoLoop; seen in the original, D8): the intro credits
## with the title picture, demo 0, the story, demo 1, the high scores (demo
## 4, played on the high-score map behind the table), demo 2, demo 3, and
## round again.

enum Step { INTRO, DEMO, STORY, HIGH_SCORES }

## The high scores are demo 4 on map 19.
const HIGH_SCORE_DEMO := 4
const STEPS: Array[Step] = [
	Step.INTRO, Step.DEMO, Step.STORY, Step.DEMO, Step.HIGH_SCORES, Step.DEMO, Step.DEMO
]
## The demo each step plays (-1: none).
const DEMOS: PackedInt32Array = [-1, 0, -1, 1, HIGH_SCORE_DEMO, 2, 3]

## The step shown now (an index into [constant STEPS]); -1 before the
## first.
var index := -1


## Goes to the next step and returns it.
func next() -> Step:
	index = (index + 1) % STEPS.size()
	return STEPS[index]


## The step shown now.
func step() -> Step:
	return STEPS[maxi(index, 0)]


## The demo of the step shown now, or -1.
func demo() -> int:
	return DEMOS[maxi(index, 0)]
