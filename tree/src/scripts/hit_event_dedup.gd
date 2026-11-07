class_name RHitEventDedup
extends RefCounted

const MAX_IDS: int=192

static func accept(enemy: Dictionary, event_id: String) -> bool:
	if event_id.is_empty():
		return false
	var recent: Dictionary=enemy.get("damaged_by",{})
	if recent.has(event_id):
		return false
	recent[event_id]=true
	if recent.size()>MAX_IDS:
		recent.erase(recent.keys()[0])
	enemy.damaged_by=recent
	return true
