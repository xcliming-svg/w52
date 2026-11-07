extends RefCounted
# Expanding shockwave checks each live enemy once and moves it away from rail.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._shockwave(origin,damage,field,tree,rng)
