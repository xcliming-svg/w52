class_name RScrapRewards
extends RefCounted

static func multiplier(economy_depth: int, milestone_e4: bool=false) -> float:
	var value: float=1.0+0.045*float(clampi(economy_depth,0,10))
	if milestone_e4:
		value*=1.03
	return minf(RBalance.SCRAP_MULTIPLIER_CAP,value)

static func kill(reward_multiplier: float, economy_depth: int, milestone_e4: bool=false) -> float:
	return RBalance.SCRAP_PER_KILL*maxf(0.0,reward_multiplier)*multiplier(economy_depth,milestone_e4)
