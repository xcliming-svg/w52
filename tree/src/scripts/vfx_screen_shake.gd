class_name RVfxScreenShake
extends RefCounted

static func impulse(current: float, scale: float, quality: float) -> float:
	return clampf(current+0.10*clampf(scale,0.0,3.0)*clampf(quality,0.0,1.0),0.0,1.0)

static func fade(current: float, delta: float) -> float:
	return maxf(0.0,current-delta*5.0)
