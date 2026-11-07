class_name RBossController
extends RefCounted

static func tick(boss: Dictionary, field, train: RTrain, tree: RTreeRules, rng: RGameRng, warning: Callable) -> void:
	var phase: int=RAiElite.attack_pattern(boss)
	if phase<0:
		return
	if phase!=int(boss.phase):
		boss.phase=phase
		boss.timer=2.0
		if warning.is_valid():
			warning.call(RAiElite.pattern_warning(phase),Vector2(boss.pos))
	# The 2s telegraph is always resolved before a new pattern can attack.
	if float(boss.timer)>0.0 or float(boss.impact_cd)>0.0:
		return
	boss.impact_cd=6.0
	match phase:
		0: RBossFanPattern.unleash(field,boss,train)
		1: RBossRailCharge.charge(boss,train,tree)
		2: RBossSummonShield.activate(field,boss,rng)
		3: RBossReverse.interfere(train)
