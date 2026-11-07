class_name RAssistedRunRecords
extends RefCounted

static func classify(assisted: bool, speed: int, used_pause: bool) -> String:
	return "assisted" if assisted or speed>1 or used_pause else "standard"

static func separate(records: Array) -> Dictionary:
	var ordinary: Array=[]
	var aided: Array=[]
	for row in records:
		if bool(row.get("assisted",false)):
			aided.append(row)
		else:
			ordinary.append(row)
	return {"ordinary":ordinary,"assisted":aided}
