class_name RPriorityVFX
extends RefCounted

static func detailed(reward_scale: float, quality: float, present_count: int) -> bool:
	if quality<=0.05:
		return false
	if reward_scale>=4.0:
		return true
	var cap: int=RVfxBudget.quota()
	return present_count < int(float(cap)*0.75)

static func lossless_gameplay() -> bool:
	# Visual budget is unrelated to damage/death events and is never read by weapons.
	return true
