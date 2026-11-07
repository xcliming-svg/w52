class_name RTreeEffects
extends RefCounted

static func preview(stat: String, value: float, tree: RTreeRules) -> String:
	match stat:
		"wagon_capacity":
			return "%d → %d량" % [tree.capacity(),mini(50,tree.capacity()+int(value))]
		"economy_tier":
			var level: int=tree.depth("E")
			return "경제 %d→%d단, TP 상한 +24%%" % [level,mini(10,level+1)]
		"fire_multiplier","synergy_multiplier","chain_power","blast_power","crit_multiplier","pierce_multiplier":
			return "계열 배율 +%.1f%%" % (value*100.0)
		"leak_mitigation":
			return "누수 감소 +%.1f%%p (분모형)" % (value*100.0)
		"enemy_travel_bonus_sec":
			return "적 제어 후보 +%.2f초" % value
		"coverage_bonus":
			return "철도 속력/커버리지 +%.1f%%p" % (value*100.0)
	return "공격/방어 공통 계산에 적용"

static func tier_stats(tree: RTreeRules) -> Dictionary:
	# Returns real runtime numbers from the same tree stats dictionary used by weapons.
	return tree.stats()
