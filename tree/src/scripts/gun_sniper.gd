extends RefCounted
# Swept continuous segment with bounded target penetration.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._sniper(origin,Vector2(target.pos),damage,field,tree,rng)
