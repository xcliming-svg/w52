class_name RTreeSearch
extends RefCounted

static func find(registry: RData, query: String) -> Array[String]:
	var matches: Array[String]=[]
	var q: String=query.strip_edges()
	if q.is_empty():
		return matches
	for row in registry.ordered_nodes:
		var effect: String=str(row.get("summary",""))
		if row.has("milestone"):
			effect+=" "+str(row.milestone.get("description",""))
		var text: String=str(row.id)+" "+str(row.get("name",""))+" "+effect
		if text.containsn(q):
			matches.append(str(row.id))
	return matches

static func contains(node: Dictionary, query: String) -> bool:
	if query.strip_edges().is_empty():
		return true
	var text: String=str(node.get("id",""))+" "+str(node.get("name",""))+" "+str(node.get("summary",""))
	if node.has("milestone"):
		text+=" "+str(node.milestone.get("description",""))
	return text.containsn(query.strip_edges())
