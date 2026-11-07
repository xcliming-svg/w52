class_name RSpawnScaling
extends RefCounted

# 10-hour design horizon; candidates require real playtesting before release.
const HORIZON_SECONDS: float = 36000.0

static func progress(elapsed: float) -> float:
	return clampf(maxf(0.0,elapsed)/HORIZON_SECONDS,0.0,1.0)

static func minute(elapsed: float) -> float:
	return maxf(0.0,elapsed)/60.0

static func spawn_rate(elapsed: float) -> float:
	return RBalance.SPAWNS_PER_SEC + 1.25*pow(progress(elapsed),1.4)

static func max_health(elapsed: float, base_multiplier: float) -> float:
	return RBalance.ENEMY_BASE_HP*(1.0+18.0*pow(progress(elapsed),1.35))*maxf(0.1,base_multiplier)

static func base_speed(elapsed: float) -> float:
	return RBalance.ENEMY_SPEED + 26.0*pow(progress(elapsed),1.2)

static func size_scale(elapsed: float) -> float:
	return 0.78+0.70*progress(elapsed)

static func opacity(elapsed: float) -> float:
	return 0.38+0.62*progress(elapsed)

static func wave_multiplier(elapsed: float) -> float:
	return 1.0+0.18*progress(elapsed) if fmod(elapsed,300.0)<20.0 else 1.0
