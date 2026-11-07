extends RefCounted
# Slow/freeze diamond projectile; boss receives reduced maximum control.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._emit_projectile("frost",origin,Vector2(target.pos),int(target.uid),damage,360.0,rng,tree)
