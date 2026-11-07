class_name RVfxLightGuard
extends RefCounted

static func allowed_flash(settings: Dictionary, flashes_last_second: int) -> bool:
	return not bool(settings.get("low_flash",true)) and flashes_last_second<8

static func alpha(requested: float, settings: Dictionary) -> float:
	if bool(settings.get("low_flash",true)):
		return minf(requested,0.08)
	return minf(requested,0.22)
