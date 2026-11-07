extends RefCounted
# Short fan-cleave with a single hit transaction across eligible victims.
static func fire(system, origin: Vector2, target: Dictionary, damage: float, field: REnemyField, tree: RTreeRules, rng: RGameRng) -> void:
	system._melee("blade",origin,Vector2(target.pos),damage,108.0,field,tree,rng)
