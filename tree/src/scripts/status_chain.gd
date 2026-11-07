class_name RStatusChain
extends RefCounted

static func next_target(source: Dictionary, nearby: Array, visited: Dictionary, radius: float) -> Dictionary:
	var selected: Dictionary={}
	var nearest: float=radius
	for enemy in nearby:
		if str(enemy.get("state",""))!="alive" or visited.has(int(enemy.uid)):
			continue
		var distance: float=Vector2(source.pos).distance_to(Vector2(enemy.pos))
		if distance<nearest:
			nearest=distance
			selected=enemy
	return selected

static func hop_damage(original: float, index: int) -> float:
	return maxf(0.0,original)*pow(0.75,float(clampi(index,0,3)))
