class_name RDifficultyDirector
extends RefCounted

static func spawn_rate(seconds: float) -> float:
	return RSpawnScaling.spawn_rate(seconds)*RSpawnScaling.wave_multiplier(seconds)

static func hp(seconds: float, multiplier: float) -> float:
	return RSpawnScaling.max_health(seconds,multiplier)

static func max_burst() -> int:
	return RSpawnDirector.spawn_limit_per_tick()

static func curve_preview(seconds: float) -> Dictionary:
	return {"spawn_rate":spawn_rate(seconds),"base_enemy_hp":hp(seconds,1.0),"seed_multiplier_low":0.86,"seed_multiplier_high":1.14}
