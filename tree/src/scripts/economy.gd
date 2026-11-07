class_name REconomy
extends RefCounted

var tp: float = RBalance.START_TP
var xp: float = RBalance.START_XP
var scrap: float = RBalance.START_SCRAP
var purchased_nodes: int = 0
var total_cars_bought: int = 0
var event_ids: Dictionary = {}
var ledger: Array = []
var transaction_serial: int = 0
var last_transaction_id: String = ""
var recent_kill_ids: Array[String] = []
const RECENT_KILL_WINDOW: int = 8192

func step(delta: float, economy_tier: int) -> void:
	tp = RTimePoints.accrue(tp,delta,economy_tier)

func record_once(event_id: String, category: String, data: Dictionary) -> bool:
	if event_ids.has(event_id):
		return false
	event_ids[event_id] = true
	if category == "kill":
		recent_kill_ids.append(event_id)
		if recent_kill_ids.size() > RECENT_KILL_WINDOW:
			event_ids.erase(recent_kill_ids.pop_front())
	ledger.append({"id": event_id, "category": category, "data": data.duplicate(true)})
	if ledger.size() > 2048:
		ledger.pop_front()
	return true

func award_kill(kill_id: String, reward_multiplier: float, economy_tier: int, elite_bonus: bool, salvage_bonus: float, e4: bool=false) -> bool:
	if not record_once(kill_id, "kill", {"scale": reward_multiplier}):
		return false
	xp += RXpRewards.kill(reward_multiplier,economy_tier)
	scrap += RScrapRewards.kill(reward_multiplier,economy_tier,e4)
	if elite_bonus:
		scrap += 5.0
	if salvage_bonus > 0.0:
		scrap += salvage_bonus
	return true

func research_cost(depth: int) -> Dictionary:
	return RUpgradePricing.quote(depth,purchased_nodes)

func can_research(depth: int) -> bool:
	var price: Dictionary = research_cost(depth)
	return RUpgradePricing.affordable(tp,xp,price)

func purchase_research(node_id: String, depth: int, tick: int) -> bool:
	var transaction: String = "node:%s:%d:%d" % [node_id, tick, transaction_serial]
	if event_ids.has(transaction) or not can_research(depth):
		return false
	var price: Dictionary = research_cost(depth)
	tp -= float(price.tp)
	xp -= float(price.xp)
	purchased_nodes += 1
	if not record_once(transaction, "research", {"node": node_id, "price": price, "tick": tick}):
		purchased_nodes -= 1
		tp += float(price.tp)
		xp += float(price.xp)
		return false
	last_transaction_id = transaction
	transaction_serial += 1
	return true

func car_price() -> float:
	return RWagonPricing.quote(total_cars_bought)

func purchase_car(wagon_id: String, tick: int) -> bool:
	var price: float = car_price()
	var transaction := "car:%d:%d" % [total_cars_bought, tick]
	if scrap + 0.000001 < price or event_ids.has(transaction):
		return false
	scrap -= price
	total_cars_bought += 1
	return record_once(transaction, "car", {"wagon": wagon_id, "price": price})

func snapshot() -> Dictionary:
	return {"tp":tp,"xp":xp,"scrap":scrap,"purchased_nodes":purchased_nodes,"total_cars_bought":total_cars_bought,"event_ids":event_ids.duplicate(true),"ledger":ledger.duplicate(true),"transaction_serial":transaction_serial,"last_transaction_id":last_transaction_id,"recent_kill_ids":recent_kill_ids.duplicate()}

func restore(data: Dictionary) -> void:
	tp = maxf(0.0, float(data.get("tp", 0.0)))
	xp = maxf(0.0, float(data.get("xp", 20.0)))
	scrap = maxf(0.0, float(data.get("scrap", 0.0)))
	purchased_nodes = maxi(0, int(data.get("purchased_nodes", 0)))
	total_cars_bought = maxi(0, int(data.get("total_cars_bought", 0)))
	event_ids = data.get("event_ids", {}).duplicate(true)
	ledger = data.get("ledger", []).duplicate(true)
	transaction_serial = maxi(0,int(data.get("transaction_serial",0)))
	last_transaction_id = str(data.get("last_transaction_id",""))
	recent_kill_ids.clear()
	for key in data.get("recent_kill_ids",[]):
		recent_kill_ids.append(str(key))
