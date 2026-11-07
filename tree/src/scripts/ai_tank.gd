class_name RAiTank
extends RefCounted

static func configure(enemy: Dictionary) -> void:
	match str(enemy.ai):
		"armored":
			enemy.armor=7.0
		"front_shield":
			enemy.shield=28.0

static func mitigate(enemy: Dictionary, raw_damage: float, damage_kind: String) -> float:
	var damage: float=maxf(0.0,raw_damage)
	if damage_kind=="kinetic":
		damage=maxf(0.0,damage-float(enemy.get("armor",0.0)))
	if str(enemy.ai)=="front_shield" and damage_kind=="kinetic":
		damage*=0.75
	return damage

static func has_protection(enemy: Dictionary) -> bool:
	return float(enemy.get("armor",0.0))>0.0 or float(enemy.get("shield",0.0))>0.0
