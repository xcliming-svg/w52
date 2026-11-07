class_name RHelpCodex
extends RefCounted

static func content(registry: RData, category: String) -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	var source: Array=[]
	match category:
		"wagon":source=registry.ordered_wagons
		"enemy":source=registry.ordered_enemies
		"tree":source=registry.ordered_nodes
	for row in source:
		rows.append({"id":str(row.get("id","")),"name":str(row.get("name","")),"description":str(row.get("summary",row.get("ai",row.get("family",""))))})
	return rows

static func counts(registry: RData) -> Dictionary:
	return {"wagons":registry.ordered_wagons.size(),"enemies":registry.ordered_enemies.size(),"nodes":registry.ordered_nodes.size()}
