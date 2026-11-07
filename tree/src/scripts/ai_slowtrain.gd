class_name RAiSlowTrain
extends RefCounted

static func influence(enemy: Dictionary, train: RTrain) -> void:
	var rail: Vector2=RRailPath.nearest_rail_position(Vector2(enemy.pos))
	if rail.distance_to(Vector2(enemy.pos))<110.0:
		train.slow_seconds=minf(2.0,maxf(train.slow_seconds,0.35))
