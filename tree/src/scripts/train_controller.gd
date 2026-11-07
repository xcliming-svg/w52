class_name RTrain
extends RefCounted

signal hull_hit(amount: float)
signal defeated
signal wagon_broken(index: int)
signal cars_changed

var milestones
var cars: Array[Dictionary] = []
var storage: Array[Dictionary] = []
var distance: float = 0.0
var direction: int = 1
var hull_hp: float = RBalance.HULL_MAX
var slow_seconds: float = 0.0
var reverse_seconds: float = 0.0
var order_cooldown: float = 0.0
var shield_cooldown: float = 0.0
var shield_charges: int = 0

func initialize() -> void:
	cars.clear()
	storage.clear()
	distance = 0.0
	hull_hp = RBalance.HULL_MAX
	direction = 1
	cars.append(RWagonInstance.construct({"id":"LOCOMOTIVE","family":"pistol","tier":1,"hp":RBalance.HULL_MAX,"armor":0.0,"color":"#f8f9fa","baseDps":11.0,"cycleSeconds":0.45,"role":"dps"}))
	cars[0].slot=0
	cars[0].instance_id=0
	cars_changed.emit()

func step(delta: float, tree: RTreeRules) -> void:
	var mods: Dictionary = tree.stats()
	var slow: float = 0.75 if slow_seconds > 0.0 else 1.0
	var speed: float = RBalance.START_SPEED * float(mods.speed) * slow
	if milestones != null:
		speed *= milestones.speed_multiplier(tree,distance)
	if reverse_seconds > 0.0:
		reverse_seconds = maxf(0.0, reverse_seconds - delta)
	else:
		direction = 1
	distance = RBalance.positive_mod(distance + speed * float(direction) * delta, RBalance.PERIMETER)
	slow_seconds = maxf(0.0, slow_seconds - delta)
	order_cooldown = maxf(0.0, order_cooldown - delta)
	shield_cooldown = maxf(0.0, shield_cooldown - delta)
	for wagon in cars:
		wagon.cd = maxf(0.0, float(wagon.cd) - delta)
		if RWagonInstance.operational(wagon):
			wagon.hp=minf(float(wagon.get("max_hp",1.0)),float(wagon.hp)+float(wagon.get("regen",0.0))*delta)
		wagon.heat = maxf(0.0, float(wagon.heat) - delta * 0.6)
		if float(wagon.get("shield", 0.0)) > 0.0:
			wagon.shield = maxf(0.0, float(wagon.shield) - delta * 0.1)

func position_for(index: int) -> Vector2:
	return RCoachFormation.position(distance,index)

func active_count() -> int:
	return cars.size()

func add_car(spec: Dictionary, tree: RTreeRules, economy: REconomy, tick: int) -> bool:
	return RWagonShop.buy(self,spec,tree,economy,tick)
func synchronize_capacity(tree: RTreeRules) -> void:
	RTrainStorage.synchronize(self,tree.capacity())
func swap_order(first: int, second: int) -> bool:
	return RCoachOrder.swap(self,first,second)
func take_hull_damage(amount: float, tree: RTreeRules) -> void:
	RHullDamage.apply_hull(self,amount,tree)
func take_wagon_damage(index: int, amount: float) -> void:
	RHullDamage.hit_wagon(self,index,amount)
func repair(index: int, economy: REconomy) -> bool:
	if index<0 or index>=cars.size():
		return false
	return RTrainRepair.repair_car(self,economy,cars[index])

func repair_storage(index: int, economy: REconomy, tree: RTreeRules) -> bool:
	return RTrainRepair.repair_storage(self,economy,index,tree.capacity())
func snapshot() -> Dictionary:
	return {"cars":cars.duplicate(true),"storage":storage.duplicate(true),"distance":distance,"direction":direction,"hull_hp":hull_hp,"slow_seconds":slow_seconds,"reverse_seconds":reverse_seconds,"order_cooldown":order_cooldown,"shield_cooldown":shield_cooldown,"shield_charges":shield_charges}

func restore(s: Dictionary) -> void:
	cars = s.get("cars", []).duplicate(true)
	storage = s.get("storage", []).duplicate(true)
	distance = float(s.get("distance", 0.0))
	direction = int(s.get("direction", 1))
	hull_hp = float(s.get("hull_hp", RBalance.HULL_MAX))
	slow_seconds = float(s.get("slow_seconds", 0.0))
	reverse_seconds = float(s.get("reverse_seconds", 0.0))
	order_cooldown = float(s.get("order_cooldown", 0.0))
	shield_cooldown = float(s.get("shield_cooldown", 0.0))
	shield_charges = int(s.get("shield_charges", 0))
	cars_changed.emit()
