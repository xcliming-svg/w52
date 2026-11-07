class_name RStatusArmorBreak
extends RefCounted

static func apply_break(enemy: Dictionary, amount: float, duration: float) -> void:
	var limit: float=0.25 if str(enemy.get("ai",""))=="boss_pattern" else 0.60
	enemy.armor_break=maxf(float(enemy.get("armor_break",0.0)),minf(limit,maxf(0.0,amount)))
	enemy.armor_break_remaining=maxf(float(enemy.get("armor_break_remaining",0.0)),duration)

static func tick(enemy: Dictionary, delta: float) -> void:
	enemy.armor_break_remaining=maxf(0.0,float(enemy.get("armor_break_remaining",0.0))-delta)
	if float(enemy.armor_break_remaining)==0.0:
		enemy.armor_break=0.0
	# Regeneration is suspended during burns; boss shielding is a separate layer.
	if enemy.get("burn",[]).is_empty():
		enemy.hp=minf(float(enemy.max_hp),float(enemy.hp)+float(enemy.get("regen",0.0))*delta)

static func effective_armor(enemy: Dictionary) -> float:
	return maxf(0.0,float(enemy.get("armor",0.0))*(1.0-float(enemy.get("armor_break",0.0))))
