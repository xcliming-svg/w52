extends RefCounted
# Cone pulses and capped three-layer burn status events.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._flame(origin,Vector2(target.pos),damage,field,tree,rng)
