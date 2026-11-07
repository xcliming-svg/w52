class_name RAiSuicide
extends RefCounted

static func tick(enemy: Dictionary, delta: float, train: RTrain, tree: RTreeRules, warning: Callable) -> bool:
	var position: Vector2=enemy.pos
	var rail_gap: float=RRailPath.nearest_rail_position(position).distance_to(position)
	if rail_gap<90.0 and float(enemy.get("detonate_timer",-1.0))<0.0:
		enemy.detonate_timer=2.0
		if warning.is_valid():
			warning.call("자폭 2초 예고",position)
	elif float(enemy.get("detonate_timer",-1.0))>0.0:
		enemy.detonate_timer=maxf(0.0,float(enemy.detonate_timer)-delta)
		if float(enemy.detonate_timer)==0.0:
			for i in train.active_count():
				if float(train.cars[i].hp)<=0.0 or train.position_for(i).distance_to(position)>=60.0:
					continue
				if i==0:
					train.take_hull_damage(float(enemy.hull_damage),tree)
				else:
					train.take_wagon_damage(i,float(enemy.hull_damage))
			return true
	return false
