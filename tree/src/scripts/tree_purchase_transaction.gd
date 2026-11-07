class_name RTreePurchaseTransaction
extends RefCounted

static func commit(tree: RTreeRules, node_id: String, tick: int) -> bool:
	if tree.data==null or tree.economy==null or node_id=="C000" or not tree.data.nodes.has(node_id) or tree.purchased.has(node_id):
		return false
	var row: Dictionary=tree.data.nodes[node_id]
	for prerequisite in row.get("requires",[]):
		if not tree.purchased.has(str(prerequisite)):
			return false
	var depth: int=int(row.depth)
	var cost: Dictionary=tree.economy.research_cost(depth)
	if tree.economy.tp+0.000001<float(cost.tp) or tree.economy.xp+0.000001<float(cost.xp):
		return false
	if not tree.economy.purchase_research(node_id,depth,tick):
		return false
	tree.purchased[node_id]=true
	tree.purchase_info[node_id]={"tick":tick,"tp":cost.tp,"xp":cost.xp,"transaction_id":tree.economy.last_transaction_id}
	if row.has("milestone"):
		tree.milestone_ids[str(row.milestone.effectId)]=true
	tree.changed.emit()
	return true
