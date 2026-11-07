class_name RVfxBudget
extends RefCounted

static func quality(base: float, entity_count: int) -> float:
	var hard_cap: int=RBalance.MAX_ENEMIES_WEB if OS.has_feature("web") else RBalance.MAX_ENEMIES_PC
	var density: float=clampf(float(entity_count)/maxf(1.0,float(hard_cap)),0.0,1.0)
	return clampf(base*(1.0-0.65*density),0.0,1.0)

static func quota() -> int:
	return RBalance.MAX_DEBRIS_WEB if OS.has_feature("web") else RBalance.MAX_DEBRIS_PC
