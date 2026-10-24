class_name RealisticGrade
extends RefCounted
## How the realistic look ([RealisticLook]) colours one game: the tint of
## its shadows and highlights, how much bright things glow, and the rest of
## the atmosphere. Each game picks its own mood (docs/realistic/research.md,
## layer A); the numbers are ours, tuned by eye.

var shadow_tint := Color(1.0, 1.0, 1.0)
var highlight_tint := Color(1.0, 1.0, 1.0)
var bloom_strength := 0.45
var bloom_threshold := 0.7
var lift := 0.02
var saturation := 1.0
var contrast := 0.12
var vignette := 0.18
var grain := 0.012
## How much the relief (light from [member light_direction] on the slopes
## of the picture) changes it, and how steep its slopes are.
var relief_strength := 0.5
var relief_bump := 3.0
var light_direction := Vector3(-0.45, -0.6, 0.66)
## How much a lamp brightens the air around it.
var halo := 0.12


static func create(shadows: Color, highlights: Color) -> RealisticGrade:
	var grade := RealisticGrade.new()
	grade.shadow_tint = shadows
	grade.highlight_tint = highlights
	return grade


## A neutral grade, for a game without a mood of its own.
static func neutral() -> RealisticGrade:
	return RealisticGrade.new()


## Keen 1: Mars, warm dust in the light and cool shade.
static func keen1() -> RealisticGrade:
	return create(Color(0.94, 0.96, 1.06), Color(1.03, 1.0, 0.97))


## Keen 2: inside the Vorticon Mothership, cold grey-blue metal.
static func keen2() -> RealisticGrade:
	var grade := create(Color(0.92, 0.97, 1.08), Color(0.99, 1.0, 1.02))
	grade.saturation = 0.94
	return grade


## Keen 3: Vorticon cities, a violet dusk.
static func keen3() -> RealisticGrade:
	return create(Color(0.98, 0.93, 1.07), Color(1.03, 1.0, 0.97))


## Keen 4: the forests of Gnosticus IV, warm sunlight and green shade.
static func keen4() -> RealisticGrade:
	return create(Color(0.95, 1.02, 0.98), Color(1.03, 1.01, 0.96))


## Keen 5: the Omegamatic, cold teal light in a dark station.
static func keen5() -> RealisticGrade:
	var grade := create(Color(0.92, 1.0, 1.07), Color(0.99, 1.01, 1.02))
	grade.bloom_strength = 0.55
	return grade
