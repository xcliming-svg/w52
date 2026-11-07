class_name RFrameBudget
extends RefCounted

static func effective_speed(speed: int, fps: float) -> int:
	if fps>0.0 and fps<20.0:
		return maxi(1,clampi(speed,1,3)-1)
	return clampi(speed,1,3)

static func headroom(fps: float) -> float:
	return clampf(fps/60.0,0.0,1.0)

static func alert(previous_speed: int, adjusted_speed: int) -> String:
	return "프레임 부족: 배속 자동 제한" if adjusted_speed<previous_speed else ""
