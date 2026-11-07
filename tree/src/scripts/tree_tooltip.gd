class_name RTreeTooltip
extends RefCounted

static func text_for(registry: RData, tree: RTreeRules, money: REconomy, id: String) -> String:
	if not registry.nodes.has(id):
		return ""
	var node: Dictionary=registry.nodes[id]
	var price: Dictionary=money.research_cost(int(node.get("depth",0))) if id!="C000" else {"tp":0,"xp":0}
	var state: String="완료" if tree.purchased.has(id) else ("구매 가능" if tree.may_buy(id) else "잠김")
	var prereq: Array=node.get("requires",[])
	var stat: String=str(node.get("stat",""))
	var preview: String=RTreeEffects.preview(stat,float(node.get("value",0)),tree)
	var milestone: String=""
	if node.has("milestone"):
		milestone="\n특수: "+str(node.milestone.get("description",""))
	return "%s [%s] %s\n전제: %s | TP %s / XP %s\n%s\n현재→구매후: %s\n상한: 치명 60%%, 연쇄 3, 관통 3, 편성 50량, 경제 XP +28%% / 고철 +30%% %s" % [str(node.get("name","")),id,state,", ".join(PackedStringArray(prereq)),str(price.tp),str(price.xp),str(node.get("summary","")),preview,milestone]
