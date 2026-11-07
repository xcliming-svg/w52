extends RefCounted
# Five separate physical projectiles, independent hit IDs and falloff.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._shotgun(origin,Vector2(target.pos),damage,rng,tree)
