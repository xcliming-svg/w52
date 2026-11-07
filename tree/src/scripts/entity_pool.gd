class_name REntityPool
extends RefCounted

var available: Array[Dictionary] = []
var limit: int = 8000
var allocations: int = 0
var reused: int = 0

func acquire() -> Dictionary:
	if not available.is_empty():
		reused += 1
		return available.pop_back()
	allocations += 1
	return {}

func recycle(entity: Dictionary) -> void:
	if available.size() >= limit:
		return
	entity.clear()
	available.append(entity)

func clear() -> void:
	available.clear()
	allocations = 0
	reused = 0
