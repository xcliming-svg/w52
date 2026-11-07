class_name REnemyLifecycle
extends RefCounted

static func alive(enemy: Dictionary) -> bool:
	return str(enemy.get("state",""))=="alive"

static func mark_dying(enemy: Dictionary) -> bool:
	if not alive(enemy):
		return false
	enemy.state="dying"
	return true

static func mark_escaped(enemy: Dictionary) -> bool:
	if not alive(enemy):
		return false
	enemy.state="dying"
	enemy.escape_applied=true
	return true

static func finalize(enemy: Dictionary) -> bool:
	if str(enemy.get("state",""))!="dying":
		return false
	enemy.state="dead"
	return true

static func can_hit(enemy: Dictionary, unique_id: String) -> bool:
	return alive(enemy) and not enemy.get("damaged_by",{}).has(unique_id) and float(enemy.get("phase_time",0.0))<=0.0
