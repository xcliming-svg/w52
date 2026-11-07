class_name RCornerTargeting
extends RefCounted

static func uniform_corner(rng: RGameRng) -> int:
	return rng.index_game(4)

static func corner_position(index: int) -> Vector2:
	return RBalance.CORNERS[clampi(index,0,3)]

static func eta(enemy: Dictionary) -> float:
	var speed: float = maxf(1.0,float(enemy.get("speed",1.0)))
	var slow: float = clampf(float(enemy.get("slow",0.0)),0.0,0.9)
	return Vector2(enemy.pos).distance_to(corner_position(int(enemy.target)))/(speed*(1.0-slow))

static func risk_score(enemy: Dictionary) -> float:
	return eta(enemy)/maxf(0.1,float(enemy.get("escape_damage",1.0)))
