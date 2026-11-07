class_name RWeaponBase
extends RefCounted

static func cycle(car: Dictionary, fire_multiplier: float) -> float:
	var base: float = float(car.get("cycleSeconds",0.45))
	var heat: float = maxf(0.0,float(car.get("heat",0.0)))/maxf(1.0,float(car.get("heat_capacity",1.0)))
	var cd: float = maxf(0.045,base/maxf(0.1,fire_multiplier*(1.0+float(car.get("fire_rate_bonus",0.0)))))
	if str(car.get("family",""))=="gatling":
		cd *= 1.0+heat*0.02
	return cd

static func base_hit(car: Dictionary, damage_multiplier: float) -> float:
	return maxf(0.0,float(car.get("baseDps",0.0))*float(car.get("cycleSeconds",1.0))*damage_multiplier)

static func can_fire(car: Dictionary) -> bool:
	return float(car.get("hp",0.0))>0.0 and float(car.get("cd",0.0))<=0.0
