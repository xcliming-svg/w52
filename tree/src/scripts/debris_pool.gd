class_name RDebrisPool
extends RefCounted

var recycled: Array[Dictionary]=[]
var total_used: int=0

func borrow() -> Dictionary:
	if recycled.is_empty():
		total_used+=1
		return {}
	return recycled.pop_back()

func release(item: Dictionary) -> void:
	item.clear()
	if recycled.size()<RBalance.MAX_DEBRIS_PC:
		recycled.append(item)

func free_all() -> void:
	recycled.clear()
	total_used=0
