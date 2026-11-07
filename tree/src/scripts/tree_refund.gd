class_name RTreeRefund
extends RefCounted

# Effect becomes visible to combat on the next 60Hz tick, not a five-second window.
static func cancel(tree: RTreeRules, node_id: String, tick: int) -> bool:
	if not tree.purchase_info.has(node_id) or int(tree.purchase_info[node_id].tick)!=tick:
		return false
	# CONTRACT C07: same-tick full refunds are exclusive to research depths 1-3.
	if tree.data==null or not tree.data.nodes.has(node_id) or int(tree.data.nodes[node_id].get("depth",0))<1 or int(tree.data.nodes[node_id].get("depth",0))>3:
		return false
	for other_id in tree.purchased.keys():
		if other_id!=node_id and other_id!="C000" and node_id in tree.data.nodes[str(other_id)].get("requires",[]):
			return false
	var paid: Dictionary=tree.purchase_info[node_id]
	var refund_id: String = "refund:" + str(paid.get("transaction_id","node:%s:%d" % [node_id,tick]))
	if not tree.economy.record_once(refund_id,"refund",{"node":node_id,"tick":tick}):
		return false
	tree.economy.tp+=float(paid.tp)
	tree.economy.xp+=float(paid.xp)
	tree.economy.purchased_nodes=maxi(0,tree.economy.purchased_nodes-1)
	tree.purchased.erase(node_id)
	tree.purchase_info.erase(node_id)
	var row: Dictionary=tree.data.nodes[node_id]
	if row.has("milestone"):
		tree.milestone_ids.erase(str(row.milestone.effectId))
	tree.changed.emit()
	return true
