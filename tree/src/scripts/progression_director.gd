class_name RProgressionDirector
extends RefCounted

var purchases: Array[Dictionary]=[]
var first_wagon_tick: int=-1
var first_research_tick: int=-1

func record(tick: int, category: String, item_id: String, tp: float, xp: float, scrap: float) -> void:
	if category=="wagon" and first_wagon_tick<0:
		first_wagon_tick=tick
	if category=="research" and first_research_tick<0:
		first_research_tick=tick
	purchases.append({"tick":tick,"category":category,"item":item_id,"tp":tp,"xp":xp,"scrap":scrap})
	if purchases.size()>2048:
		purchases.pop_front()

func snapshot() -> Dictionary:
	return {"purchases":purchases.duplicate(true),"first_wagon_tick":first_wagon_tick,"first_research_tick":first_research_tick}

func restore(data: Dictionary) -> void:
	purchases=data.get("purchases",[]).duplicate(true)
	first_wagon_tick=int(data.get("first_wagon_tick",-1))
	first_research_tick=int(data.get("first_research_tick",-1))
