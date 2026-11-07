class_name RTargetSelector
extends RefCounted

# Filters are called before sorting: no off-range, off-arc, or already-dead shots.
static func threat_score(enemy: Dictionary, origin: Vector2, priority: String) -> float:
	var pos: Vector2 = enemy.pos
	var distance: float = origin.distance_to(pos)
	var escape_time: float = pos.distance_to(RBalance.CORNERS[int(enemy.target)])/maxf(1.0,float(enemy.speed)*(1.0-float(enemy.slow)))
	match priority:
		"nearest": return distance
		"elite": return -10000.0*float(enemy.reward)+escape_time
		"hp": return -float(enemy.hp)
	return escape_time

static func best(candidates: Array, origin: Vector2, radius: float, priority: String, facing: Vector2) -> Dictionary:
	var winner: Dictionary = {}
	var best_score: float = INF
	for enemy in candidates:
		if str(enemy.state)!="alive":
			continue
		if origin.distance_to(Vector2(enemy.pos))>radius+float(enemy.size)*0.5:
			continue
		var delta: Vector2 = (Vector2(enemy.pos)-origin).normalized()
		if facing.dot(delta)<-0.20:
			continue
		var score: float = threat_score(enemy,origin,priority)
		if score<best_score:
			best_score=score
			winner=enemy
	return winner
