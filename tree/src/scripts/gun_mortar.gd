extends RefCounted
# Fixed impact ground target; delayed telegraph and outer AoE falloff.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._mortar(origin,Vector2(target.pos),damage,tree)
