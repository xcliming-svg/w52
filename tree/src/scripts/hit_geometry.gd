class_name RHitGeometry
extends RefCounted

static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d: Vector2 = b-a
	var length_sq: float = d.length_squared()
	if length_sq <= 0.00001:
		return p.distance_to(a)
	return p.distance_to(a+d*clampf((p-a).dot(d)/length_sq,0.0,1.0))

static func intersects_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> bool:
	return segment_distance(center,a,b) <= radius

static func within_cone(origin: Vector2, forward: Vector2, point: Vector2, half_angle: float) -> bool:
	var relative: Vector2 = point-origin
	if relative.length_squared() < 0.00001:
		return true
	return forward.normalized().dot(relative.normalized()) >= cos(half_angle)
