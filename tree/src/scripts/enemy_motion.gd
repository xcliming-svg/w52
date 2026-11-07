class_name REnemyMotion
extends RefCounted

static func advance(enemy: Dictionary, heading: Vector2, speed_factor: float, delta: float) -> void:
	if not REnemyLifecycle.alive(enemy):
		return
	var vector: Vector2=heading.normalized()
	if not vector.is_finite():
		return
	enemy.pos=Vector2(enemy.pos)+vector*maxf(0.0,float(enemy.speed))*clampf(speed_factor,0.0,5.0)*delta

static func has_escaped(enemy: Dictionary) -> bool:
	return bool(enemy.get("can_escape",true)) and Vector2(enemy.pos).distance_to(RCornerTargeting.corner_position(int(enemy.target)))<=14.0

static func near_corner(enemy: Dictionary, radius: float) -> bool:
	return Vector2(enemy.pos).distance_to(RCornerTargeting.corner_position(int(enemy.target)))<=radius
