class_name RTrainStorage
extends RefCounted

static func store(train: RTrain, car: Dictionary) -> void:
	car.slot=-1
	train.storage.append(car)

static func synchronize(train: RTrain, capacity: int) -> void:
	var cap: int=clampi(capacity,1,RBalance.MAX_TRAIN)
	while train.cars.size()>cap:
		var car: Dictionary=train.cars.pop_back()
		car.slot=-1
		train.storage.push_front(car)
	for i in range(train.storage.size()-1,-1,-1):
		if train.cars.size()>=cap:
			break
		var wagon: Dictionary=train.storage[i]
		if not RWagonInstance.operational(wagon):
			continue
		train.storage.remove_at(i)
		wagon.slot=train.cars.size()
		train.cars.append(wagon)
	for i in train.cars.size():
		train.cars[i].slot=i
	train.cars_changed.emit()
