class_name RSpawnScaling
extends RefCounted

static func minute(elapsed: float) -> float:
	return maxf(0.0,elapsed)/60.0

static func spawn_rate(elapsed: float) -> float:
	return RBalance.SPAWNS_PER_SEC*pow(1.0+minute(elapsed)/12.0,1.255)

static func max_health(elapsed: float, base_multiplier: float) -> float:
	var minutes: float = minute(elapsed)
	var late: float = 1.14 if minutes >= 30.0 else 1.0
	return RBalance.ENEMY_BASE_HP*pow(1.0+minutes/20.0,1.71)*late*maxf(0.1,base_multiplier)

static func wave_multiplier(elapsed: float) -> float:
	return 1.35 if fmod(elapsed,300.0)<20.0 else 1.0
