extends RefCounted
# Neighbor-only direct shield/cooldown buff; excludes other support wagons.
static func fire(system, train: RTrain, slot: int, car: Dictionary) -> void:
	system._support(train,slot,car)
