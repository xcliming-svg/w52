class_name REnemyDeathReward
extends RefCounted

static func apply(economy: REconomy, event_uid: int, enemy_kind: String, multiplier: float, econ_depth: int, elite_bonus: bool, salvage_bonus: float, e4: bool=false) -> bool:
	# Event ID is invariant across explosions, DOT and multi-projectile hits.
	return economy.award_kill("kill:%d" % event_uid,multiplier,econ_depth,elite_bonus,salvage_bonus,e4)

static func classify(multiplier: float) -> String:
	if multiplier>=15.0:
		return "boss"
	if multiplier>=4.0:
		return "elite"
	return "ordinary"
