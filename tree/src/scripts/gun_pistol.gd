extends RefCounted
# Single kinetic rectangular round, with per-projectile piercing milestones.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._emit_projectile("pistol",origin,Vector2(target.pos),int(target.uid),damage,520.0,rng,tree)
