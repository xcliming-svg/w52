class_name RBossRailCharge
extends RefCounted

# Charge telegraphs a fixed rail contact and collides at current vehicle positions.
static func charge(boss: Dictionary, train: RTrain, tree: RTreeRules) -> int:
	var center: Vector2 = RRailPath.nearest_rail_position(Vector2(boss.pos))
	var hits: int = 0
	for i in train.active_count():
		if float(train.cars[i].hp)<=0.0 or train.position_for(i).distance_to(center)>50.0:
			continue
		var power: float = float(boss.hull_damage)*0.45
		if i==0:
			train.take_hull_damage(power,tree)
		else:
			train.take_wagon_damage(i,power)
		hits += 1
	return hits
