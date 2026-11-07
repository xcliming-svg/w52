class_name RTreeReset
extends RefCounted

static func execute(tree: RTreeRules, tick: int) -> bool:
	if tree.reset_used:
		return false
	tree.reset_used=true
	for info in tree.purchase_info.values():
		tree.economy.tp+=float(info.tp)*0.70
		tree.economy.xp+=float(info.xp)*0.70
	tree.purchased={"C000":true}
	tree.purchase_info.clear()
	tree.milestone_ids.clear()
	tree.economy.purchased_nodes=0
	tree.economy.record_once("reset:%d" % tick,"reset",{"returned":0.70})
	tree.changed.emit()
	return true
