class_name RXpRewards
extends RefCounted

static func multiplier(economy_depth: int) -> float:
	return minf(RBalance.XP_MULTIPLIER_CAP,1.0+0.04*float(clampi(economy_depth,0,10)))

static func kill(reward_multiplier: float, economy_depth: int) -> float:
	return RBalance.XP_PER_KILL*maxf(0.0,reward_multiplier)*multiplier(economy_depth)
