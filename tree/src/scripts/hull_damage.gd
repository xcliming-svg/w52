class_name RHullDamage
extends RefCounted

static func hit_wagon(train: RTrain, index: int, amount: float) -> bool:
	if index<=0 or index>=train.cars.size() or amount<=0.0:
		return false
	var car: Dictionary=train.cars[index]
	if float(car.hp)<=0.0:
		return false
	var shielded: float=minf(float(car.get("shield",0.0)),amount)
	car.shield=maxf(0.0,float(car.get("shield",0.0))-shielded)
	var mitigation: float=clampf(float(car.get("kinetic_resist",0.0)),0.0,0.65)
	var taken: float=maxf(0.0,(amount-shielded)*(1.0-mitigation)-float(car.get("armor",0.0))*0.4)
	car.hp=maxf(0.0,float(car.hp)-taken)
	if float(car.hp)<=0.0:
		car.active=false
		train.wagon_broken.emit(index)
	return taken>0.0

static func apply_hull(train: RTrain, amount: float, tree: RTreeRules) -> float:
	var mitigation: float=float(tree.stats().escape_reduction)
	var hit: float=maxf(0.0,amount)*mitigation
	if train.milestones!=null:
		hit*=train.milestones.mitigation_for_collision(tree)
	if tree.has_milestone("A",7) and train.shield_cooldown<=0.0 and train.hull_hp<=RBalance.HULL_MAX*0.30:
		train.shield_cooldown=90.0
		train.shield_charges=1
	if train.shield_charges>0:
		train.shield_charges-=1
		return 0.0
	train.hull_hp=maxf(0.0,train.hull_hp-hit)
	if not train.cars.is_empty():
		train.cars[0].hp=train.hull_hp
	train.hull_hit.emit(hit)
	if train.hull_hp<=0.0:
		train.defeated.emit()
	return hit
