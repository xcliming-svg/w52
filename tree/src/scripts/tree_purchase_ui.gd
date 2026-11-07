class_name RTreePurchaseUI
extends RefCounted

static func state(tree: RTreeRules, node_id: String) -> String:
	if tree.purchased.has(node_id):
		return "purchased"
	if not tree.data.nodes.has(node_id):
		return "invalid"
	for prerequisite in tree.data.nodes[node_id].get("requires",[]):
		if not tree.purchased.has(str(prerequisite)):
			return "locked"
	return "available" if tree.may_buy(node_id) else "unaffordable"

static func button_enabled(tree: RTreeRules, node_id: String, paused: bool) -> bool:
	return not paused and state(tree,node_id)=="available"
