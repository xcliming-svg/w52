class_name RBossFanPattern
extends RefCounted

# Projectile fan telegraphed by RBossController and intercepted by the train collision bridge.
static func unleash(field, boss: Dictionary, train: RTrain) -> int:
	var origin: Vector2 = boss.pos
	var direction: float = (train.position_for(0)-origin).angle()
	var fired: int = 0
	for offset in range(-3,4):
		var target: Vector2 = origin + Vector2.from_angle(direction+float(offset)*0.16)*850.0
		field._fire_hazard(origin,target,5.0,"boss_fan")
		fired += 1
	return fired
