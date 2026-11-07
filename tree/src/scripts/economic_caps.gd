class_name REconomicCaps
extends RefCounted

static func salvage_chance(econ_depth: int) -> float:
	return clampf(float(maxi(0,econ_depth-6))*0.03,0.0,0.12)

static func can_salvage(econ_depth: int, rng: RGameRng) -> bool:
	var rate: float=salvage_chance(econ_depth)
	return rng.random_game()<rate

static func cap_total(multiplier: float, category: String) -> float:
	match category:
		"xp": return minf(RBalance.XP_MULTIPLIER_CAP,multiplier)
		"scrap":return minf(RBalance.SCRAP_MULTIPLIER_CAP,multiplier)
		"tp":return minf(RBalance.TP_MULTIPLIER_CAP,multiplier)
	return maxf(0.0,multiplier)
