extends RefCounted
# Nearest-neighbor chain with per-hop visited set, maximum three leaps.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._tesla(origin,target,damage,field,tree,rng)
