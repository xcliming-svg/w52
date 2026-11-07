class_name RSpawnDirector
extends RefCounted

static func accrue(credit: float, elapsed: float, delta: float, rng: RGameRng) -> float:
	var raw: float = RDifficultyDirector.spawn_rate(elapsed)
	return minf(50.0,credit+raw*delta*rng.range_game(0.86,1.14))

static func regular_template_index(rng: RGameRng, total: int) -> int:
	return rng.index_game(maxi(1,total-2))

static func spawn_limit_per_tick() -> int:
	return 12

static func warn_minute(elapsed: float) -> int:
	var candidate: int = int((elapsed+15.0)/60.0)
	return candidate if candidate>0 and candidate%5==0 else 0

static func due(now: int, last: int) -> bool:
	return now>0 and now!=last
