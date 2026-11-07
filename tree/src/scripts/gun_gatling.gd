extends RefCounted
# Rapid individual projectiles with deterministic gameplay RNG spread.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	var spread := Vector2(rng.range_game(-15.0,15.0),rng.range_game(-15.0,15.0))
	system._emit_projectile("gatling",origin,Vector2(target.pos)+spread,int(target.uid),damage,730.0,rng,tree)
