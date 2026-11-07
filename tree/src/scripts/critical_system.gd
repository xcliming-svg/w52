class_name RCriticalSystem
extends RefCounted

static func roll(base: float, chance: float, multiplier: float, rng: RGameRng) -> Dictionary:
	var is_crit: bool=rng.random_game()<clampf(chance,0.0,0.60)
	var crit_multiplier: float=clampf(multiplier,1.0,4.0)
	return {"damage":maxf(0.0,base)*(crit_multiplier if is_crit else 1.0),"critical":is_crit}
