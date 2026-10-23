class_name GalaxyTitleLoop
extends RefCounted
## The order of a Galaxy episode's title loop, what plays while nobody
## plays (made from Keen 4's [Keen4TitleLoop], milestone E7; Omni
## `ck_main.c`: CK_DemoLoop; seen in Keen 4, D8, and Keen 5, E7): the intro
## credits with the title picture, demo 0, the story, demo 1, the high
## scores (a demo played on the high-score map behind the table), demo 2,
## demo 3, and round again. Keen 4 and 5 have the same order.

enum Step { INTRO, DEMO, STORY, HIGH_SCORES }

const STEPS: Array[Step] = [
	Step.INTRO, Step.DEMO, Step.STORY, Step.DEMO, Step.HIGH_SCORES, Step.DEMO, Step.DEMO
]
## The demo each step plays (-1: none; the high scores' demo is the
## rules', [member high_score_demo]).
const DEMOS: PackedInt32Array = [-1, 0, -1, 1, -1, 2, 3]

## The step shown now (an index into [constant STEPS]); -1 before the
## first.
var index := -1
## The demo of the high scores (Keen 4 and 5: demo 4).
var high_score_demo := 4


static func create(high_scores: int) -> GalaxyTitleLoop:
	var loop := GalaxyTitleLoop.new()
	loop.high_score_demo = high_scores
	return loop


## Goes to the next step and returns it.
func next() -> Step:
	index = (index + 1) % STEPS.size()
	return STEPS[index]


## The step shown now.
func step() -> Step:
	return STEPS[maxi(index, 0)]


## The demo of the step shown now, or -1.
func demo() -> int:
	if step() == Step.HIGH_SCORES:
		return high_score_demo
	return DEMOS[maxi(index, 0)]
