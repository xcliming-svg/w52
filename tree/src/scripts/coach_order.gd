class_name RCoachOrder
extends RefCounted

static func swap(train: RTrain, first: int, second: int) -> bool:
	if train.order_cooldown>0.0 or first<1 or second<1 or first==second or first>=train.cars.size() or second>=train.cars.size():
		return false
	var car: Dictionary=train.cars[first]
	train.cars[first]=train.cars[second]
	train.cars[second]=car
	train.cars[first].slot=first
	train.cars[second].slot=second
	train.order_cooldown=3.0
	train.cars_changed.emit()
	return true
