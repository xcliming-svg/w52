class_name RTimePoints
extends RefCounted

static func per_second(economy_depth: int) -> float:
	return RBalance.TP_PER_SECOND * minf(RBalance.TP_MULTIPLIER_CAP,1.0+0.03*clampi(economy_depth,0,10))

static func accrue(current: float, delta: float, depth: int) -> float:
	return maxf(0.0,current)+per_second(depth)*maxf(0.0,delta)
