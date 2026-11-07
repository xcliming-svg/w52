extends RefCounted
# Homing rocket performs fresh target selection when its target dies.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._emit_projectile("rocket",origin,Vector2(target.pos),int(target.uid),damage,250.0,rng,tree)
