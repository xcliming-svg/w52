class_name RSpawnDirector
extends RefCounted

static func accrue(credit: float, elapsed: float, delta: float, rng: RGameRng) -> float:
	var raw: float = RDifficultyDirector.spawn_rate(elapsed)
	return minf(50.0,credit+raw*delta*rng.range_game(0.92,1.08))

static func regular_template_index(rng: RGameRng, total: int, elapsed: float=0.0) -> int:
	# One newly available family every 50 minutes, retaining older families.
	var unlocked: int = mini(maxi(0,total-3),int(RSpawnScaling.minute(elapsed)/50.0))
	var roll: float = rng.range_game(0.0,1.0)
	return mini(unlocked,int(pow(roll,0.65)*float(unlocked+1)))

static func spawn_limit_per_tick() -> int:
	return 4

static func warn_minute(elapsed: float) -> int:
	var candidate: int = int((elapsed+15.0)/60.0)
	return candidate if candidate>=60 and candidate%60==0 else 0

static func due(now: int, last: int) -> bool:
	return now>0 and now!=last
