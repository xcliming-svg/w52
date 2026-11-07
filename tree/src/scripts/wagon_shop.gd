class_name RWagonShop
extends RefCounted

# Transaction succeeds only after registry, wallet, and inventory count validate.
static func buy(train: RTrain, spec: Dictionary, tree: RTreeRules, economy: REconomy, tick: int) -> bool:
	if spec.is_empty() or str(spec.get("id","")).is_empty() or str(spec.get("family","")).is_empty():
		return false
	if not RWagonPricing.is_affordable(economy.scrap,economy.total_cars_bought):
		return false
	if train.cars.size()+train.storage.size()>=999 or tree.capacity()<1:
		return false
	var car: Dictionary=RWagonFactory.build_from_spec(spec)
	if car.is_empty():
		return false
	if not economy.purchase_car(str(spec.id),tick):
		return false
	car.instance_id=economy.total_cars_bought
	if train.cars.size()<tree.capacity():
		car.slot=train.cars.size()
		train.cars.append(car)
	else:
		RTrainStorage.store(train,car)
	train.cars_changed.emit()
	return true
