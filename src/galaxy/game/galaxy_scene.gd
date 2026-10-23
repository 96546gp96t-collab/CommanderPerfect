class_name GalaxyScene
extends RefCounted
## A scene of a Galaxy episode that runs over the whole screen on the
## original's clock instead of the game (milestone E7), such as Keen 5's
## exploding galaxy ([Keen5GalaxyExplosion]): [GalaxyFrontScreen] lets the
## tics pass, shows [method screen] faded to [method fade_level]
## ([GalaxyEgaFade]) and passes a key on; when [method is_done] the screen
## goes on. The defaults are a scene that is over at once.


## Lets [param _tics] tics pass; returns whether the screen changed.
func advance(_tics: int) -> bool:
	return false


## A key was pressed; returns whether the scene took it.
func press() -> bool:
	return false


## The screen as it is now (320 × 200), or null to show what lies under
## the scene (the game's last picture).
func screen() -> Image:
	return null


## How far the screen is faded ([GalaxyEgaFade]: 3 whole, 0 black).
func fade_level() -> int:
	return GalaxyEgaFade.WHOLE


func is_done() -> bool:
	return true
