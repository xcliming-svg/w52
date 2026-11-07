class_name RAiRunner
extends RefCounted

# Distinct runner families share motion geometry but not timing.
static func dash_telegraph(enemy: Dictionary, delta: float) -> bool:
	if str(enemy.get("ai","")) not in ["dash","rush_corner"]:
		return false
	var phase: float=fmod(float(enemy.get("elapsed",0.0)),4.0)
	return phase>=3.0 and phase<3.0+delta

static func steering(enemy: Dictionary, heading: Vector2, delta: float) -> Dictionary:
	var speed_factor: float=1.0
	var direction: Vector2=heading
	match str(enemy.ai):
		"fast_corner":
			speed_factor=1.0
		"zigzag_corner":
			direction=heading.rotated(sin(float(enemy.elapsed)*6.5)*0.35)
		"dash", "rush_corner":
			var phase: float=fmod(float(enemy.elapsed),4.0)
			if phase>=3.2:
				speed_factor=2.3
	return {"heading":direction,"speed":speed_factor}
