class_name RBossReverse
extends RefCounted

static func interfere(train: RTrain) -> void:
	train.direction = -1
	train.reverse_seconds = maxf(train.reverse_seconds,1.5)
