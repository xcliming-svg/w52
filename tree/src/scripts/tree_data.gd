class_name RTreeData
extends RefCounted

static func valid(registry: RData) -> bool:
	if registry.nodes.size()!=RBalance.TREE_NODES:
		return false
	if not registry.nodes.has("C000"):
		return false
	for row in registry.ordered_nodes:
		var depth: int=int(row.get("depth",-1))
		if depth<0 or depth>10:
			return false
		for prereq in row.get("requires",[]):
			if not registry.nodes.has(str(prereq)):
				return false
			if int(registry.nodes[str(prereq)].depth)>=depth:
				return false
	return true

static func prerequisites(registry: RData, node_id: String) -> Array:
	if not registry.nodes.has(node_id):
		return []
	return registry.nodes[node_id].get("requires",[])

static func branches() -> Array[String]:
	return ["W","R","S","H","C","X","A","E","F","L","U","P"]
