class_name REnemyFactory
extends RefCounted

# Each JSON variant owns its exact color, geometry, AI tag and scale.
static func create(spec: Dictionary, id: int, elapsed: float, where: Vector2, corner: int) -> Dictionary:
	var hp: float = RSpawnScaling.max_health(elapsed,float(spec.get("hpMultiplier",1.0)))
	var enemy: Dictionary = {
		"uid":id, "kind":str(spec.id), "ai":str(spec.ai), "shape":str(spec.shape),
		"color":str(spec.color), "size":float(spec.get("sizePx",14.0)),
		"pos":where, "target":corner, "hp":hp, "max_hp":hp,
		"speed":RBalance.ENEMY_SPEED*float(spec.get("speedMultiplier",1.0)),
		"state":"alive", "shield":0.0, "armor":0.0,
		"slow":0.0, "slow_time":0.0, "frozen_time":0.0,
		"burn":[], "phase":0.0, "phase_time":0.0, "elapsed":0.0,
		"timer":0.0, "impact_cd":0.0, "detonate_timer":-1.0, "children":0,
		"reward":float(spec.get("rewardMultiplier",1.0)),
		"escape_damage":float(spec.get("escapeDamage",1.0)),
		"damage_type":str(spec.get("damageType","escape")),
		"hull_damage":float(spec.get("hullDamage",0.0)),
		"can_escape":bool(spec.get("canEscape",true)),
		"damaged_by":{}, "hit_count":0, "crit_cooldown_tick":-360
	}
	RAiTank.configure(enemy)
	if str(enemy.ai)=="boss_pattern":
		enemy.shield=hp*0.15
		enemy.timer=2.0
		enemy.impact_cd=2.0
	return enemy
