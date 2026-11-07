class_name RDefenseResists
extends RefCounted

# Kinetic armor and elemental resistance both clamp before subtracting shields.
static func mitigate(enemy: Dictionary, raw: float, dtype: String, penetration: float = 0.0) -> float:
	var damage: float=maxf(0.0,raw)
	if dtype=="kinetic":
		damage=maxf(0.0,damage-maxf(0.0,RStatusArmorBreak.effective_armor(enemy)-maxf(0.0,penetration)))
	var resist_key: String="resist_"+dtype
	var resist: float=clampf(float(enemy.get(resist_key,0.0)),-0.50,0.90)
	damage*=1.0-resist
	if str(enemy.get("ai",""))=="front_shield" and dtype=="kinetic":
		damage*=0.75
	return maxf(0.0,damage)
