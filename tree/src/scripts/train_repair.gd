class_name RTrainRepair
extends RefCounted

static func repair_car(train: RTrain, economy: REconomy, car: Dictionary) -> bool:
	var missing: float=maxf(0.0,float(car.get("max_hp",1.0))-float(car.get("hp",0.0)))
	var cost: float=ceilf(missing*0.10*float(car.get("maintenance_factor",1.0)))
	if missing<=0.0 or economy.scrap+0.000001<cost:
		return false
	economy.scrap-=cost
	car.hp=car.max_hp
	car.active=true
	if train.cars.size()>0 and str(car.get("id",""))=="LOCOMOTIVE":
		train.hull_hp=float(car.hp)
	return true

static func repair_storage(train: RTrain, economy: REconomy, storage_index: int, capacity: int) -> bool:
	if storage_index<0 or storage_index>=train.storage.size():
		return false
	if not repair_car(train,economy,train.storage[storage_index]):
		return false
	RTrainStorage.synchronize(train,capacity)
	return true
