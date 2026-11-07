class_name RTreeRules
extends RefCounted

signal changed

var data: RData
var economy: REconomy
var purchased: Dictionary = {"C000": true}
var purchase_info: Dictionary = {}
var reset_used: bool = false
var milestone_ids: Dictionary = {}
var settings: Dictionary = {}

func configure(registry: RData, money: REconomy) -> void:
	data = registry
	economy = money

func is_visible(node_id: String) -> bool:
	if data == null or not data.nodes.has(node_id):
		return false
	if purchased.has(node_id):
		return true
	for parent_id in data.nodes[node_id].get("requires",[]):
		if not purchased.has(str(parent_id)):
			return false
	return true

func may_buy(node_id: String) -> bool:
	if not data.nodes.has(node_id) or purchased.has(node_id) or node_id == "C000":
		return false
	var row: Dictionary = data.nodes[node_id]
	for prereq in row.get("requires", []):
		if not purchased.has(prereq):
			return false
	return economy.can_research(int(row.depth))

func purchase(node_id: String, tick: int) -> bool:
	return RTreePurchaseTransaction.commit(self,node_id,tick)
func cancel_same_tick(node_id: String, tick: int) -> bool:
	return RTreeRefund.cancel(self,node_id,tick)
func reset_once(tick: int) -> bool:
	return RTreeReset.execute(self,tick)
func depth(branch: String) -> int:
	var count: int = 0
	for level in range(1,11):
		if purchased.has("%s%02d" % [branch,level]):
			count += 1
	return count

func has_milestone(branch: String, tier: int) -> bool:
	return milestone_ids.has("milestone_%s_%d" % [branch, tier])

func capacity() -> int:
	var total := 1
	for level in range(1, 11):
		if purchased.has("W%02d" % level):
			if level == 10:
				total += 4 if has_milestone("W",10) else 0
			else:
				total += 5
	return mini(RBalance.MAX_TRAIN, total)

func stats() -> Dictionary:
	var levels := {}
	for branch in RTreeData.branches():
		levels[branch] = depth(branch)
	var bonus := {
		"capacity": capacity(), "economy_tier":levels.E,
		"fire_rate":1.0 + 0.104 * levels.R,
		"damage":(minf(1.72,1.0+0.09*levels.S) if has_milestone("S",10) else 1.0+0.09*levels.S)+0.065*levels.H,
		"range":1.0 + 0.028 * levels.C + 0.028 * levels.P,
		"aoe":1.0 + 0.028 * levels.X,
		"escape_reduction": 1.0 / (1.0 + 0.035 * levels.A),
		"slow_power":0.65 * levels.F,
		"speed":1.0 + 0.025 * levels.L,
		"crit_chance":clampf(0.02 + (0.04 if has_milestone("U",4) else 0.0), 0.0, 0.6),
		"crit_multiplier":clampf(1.5 + 0.065 * levels.U + (0.15 if has_milestone("U",7) else 0.0), 1.0, 4.0),
		"chain":mini(3, levels.C / 3),
		"pierce":mini(3, levels.P / 3),
		"salvage_chance":minf(0.12, maxi(0,levels.E-6)*0.03)
	}
	return bonus

func snapshot() -> Dictionary:
	return {"purchased": purchased.duplicate(true),"purchase_info":purchase_info.duplicate(true),"reset_used":reset_used,"milestones":milestone_ids.duplicate(true)}

func restore(value: Dictionary) -> void:
	purchased = value.get("purchased", {"C000":true}).duplicate(true)
	purchase_info = value.get("purchase_info", {}).duplicate(true)
	reset_used = bool(value.get("reset_used", false))
	milestone_ids = value.get("milestones", {}).duplicate(true)
	changed.emit()
