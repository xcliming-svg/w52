class_name RRailPath
extends RefCounted

static func point(distance: float) -> Vector2:
	var d: float = RBalance.positive_mod(distance, RBalance.PERIMETER)
	if d < 1175.0:
		return Vector2(75.0 + d, 70.0)
	if d < 1950.0:
		return Vector2(1250.0, 70.0 + d - 1175.0)
	if d < 3125.0:
		return Vector2(1250.0 - d + 1950.0, 845.0)
	return Vector2(75.0, 845.0 - d + 3125.0)

static func heading(distance: float) -> float:
	var d: float = RBalance.positive_mod(distance, RBalance.PERIMETER)
	if d < 1175.0:
		return 0.0
	if d < 1950.0:
		return PI * 0.5
	if d < 3125.0:
		return PI
	return PI * 1.5

static func coach_position(locomotive_distance: float, slot: int) -> Vector2:
	return point(locomotive_distance - float(slot) * RBalance.RAIL_SPACING)

static func nearest_rail_position(p: Vector2) -> Vector2:
	var top := Vector2(clampf(p.x, 75.0, 1250.0), 70.0)
	var right := Vector2(1250.0, clampf(p.y, 70.0, 845.0))
	var bottom := Vector2(clampf(p.x, 75.0, 1250.0), 845.0)
	var left := Vector2(75.0, clampf(p.y, 70.0, 845.0))
	var best: Vector2 = top
	for q in [right, bottom, left]:
		if p.distance_squared_to(q) < p.distance_squared_to(best):
			best = q
	return best
