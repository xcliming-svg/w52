class_name RAiArtillery
extends RefCounted

static func should_telegraph(enemy: Dictionary) -> bool:
	return float(enemy.get("timer",0.0))<=0.0 and RRailPath.nearest_rail_position(Vector2(enemy.pos)).distance_to(Vector2(enemy.pos))<280.0

static func begin_attack(enemy: Dictionary, train: RTrain, rng: RGameRng, warning: Callable) -> void:
	enemy.timer=5.0
	enemy.impact_cd=2.0
	enemy.artillery_target=train.position_for(rng.index_game(train.active_count()))
	if warning.is_valid():
		warning.call("적 포격 2초 예고",Vector2(enemy.pos))

static func is_ready(previous: float, current: float) -> bool:
	return previous>0.0 and current<=0.0

static func locked_target(enemy: Dictionary, train: RTrain) -> Vector2:
	var saved: Variant=enemy.get("artillery_target",null)
	return Vector2(saved) if saved is Vector2 else train.position_for(0)
