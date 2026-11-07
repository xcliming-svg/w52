class_name RWagonInstance
extends RefCounted

static func construct(spec: Dictionary) -> Dictionary:
	var car: Dictionary=spec.duplicate(true)
	var tier: int=clampi(int(spec.get("tier",1)),1,3)
	car.typeID=str(spec.get("id",""))
	car.max_hp=maxf(1.0,float(spec.get("hp",52.0)))
	car.hp=car.max_hp
	car.armor=maxf(0.0,float(spec.get("armor",0.0)))
	car.cd=0.0
	car.heat=0.0
	car.aim="escape"
	car.shield=0.0
	car.slot=-1
	car.continuous_fire=0.0
	car.active=true
	car.kinetic_resist=clampf(0.02*(tier-1),0.0,0.65)
	car.fire_resist=clampf(0.03*(tier-1),0.0,0.65)
	car.cold_resist=clampf(0.03*(tier-1),0.0,0.65)
	car.electric_resist=clampf(0.03*(tier-1),0.0,0.65)
	var step: float=float(tier-1)
	car.regen=0.02*step
	car.range_bonus=0.035*step
	car.fire_rate_bonus=0.04*step
	car.aoe_bonus=0.055*step
	car.dot_bonus=0.07*step
	car.crit_bonus=0.012*step
	car.boss_bonus=0.075*step
	car.knockback_bonus=0.08*step
	car.pierce_bonus=int(step) if str(car.family)=="sniper" else 0
	car.chain_bonus=int(step) if str(car.family)=="tesla" else 0
	car.spread_bonus=-0.10*step
	car.lifesteal=0.005*step
	car.heat_capacity=1.0+0.20*step
	car.maintenance_factor=1.0+0.35*step
	car.salvage=0.01*step
	return car

static func operational(car: Dictionary) -> bool:
	return bool(car.get("active",true)) and float(car.get("hp",0.0))>0.0

static func target_mode(car: Dictionary, mode: String) -> bool:
	if mode not in ["escape","nearest","elite","hp"]:
		return false
	car.aim=mode
	return true
