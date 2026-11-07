class_name RGameCamera
extends RefCounted

static func visual_offset(visuals: RVisualEffects, settings: Dictionary) -> Vector2:
	if not bool(settings.get("shake",true)) or bool(settings.get("low_flash",true)):
		return Vector2.ZERO
	var magnitude: float=clampf(visuals.shake,0.0,1.0)*3.0
	var t: float=visuals.time
	return Vector2(sin(t*93.0),cos(t*71.0))*magnitude

static func transform_offset(panel_size: Vector2, world_size: Vector2, factor: float) -> Vector2:
	return (panel_size-world_size*factor)*0.5
