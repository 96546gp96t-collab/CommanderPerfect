class_name Keen4TitleLoop
extends GalaxyTitleLoop
## The order of Keen 4's title loop, what plays while nobody plays (Omni
## `ck_main.c`: CK_DemoLoop; seen in the original, D8): the intro credits
## with the title picture, demo 0, the story, demo 1, the high scores (demo
## 4, played on the high-score map behind the table), demo 2, demo 3, and
## round again; the shared [GalaxyTitleLoop] (since milestone E13).

## The high scores are demo 4 on map 19.
const HIGH_SCORE_DEMO := 4


func _init() -> void:
	high_score_demo = HIGH_SCORE_DEMO
