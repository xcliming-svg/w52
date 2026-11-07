class_name RAiElite
extends RefCounted

static func is_elite(enemy: Dictionary) -> bool:
	return str(enemy.get("ai","")) in ["rush_corner","boss_pattern"]

static func attack_pattern(enemy: Dictionary) -> int:
	if str(enemy.ai)!="boss_pattern":
		return -1
	return int(float(enemy.elapsed)/9.0)%4

static func pattern_warning(phase: int) -> String:
	var items: Array[String]=["부채 탄막","레일 돌파","보호막·분열","열차 교란"]
	return "보스: "+items[clampi(phase,0,3)]+" 2초 예고"

static func rush_scale(enemy: Dictionary) -> float:
	if str(enemy.ai)=="rush_corner" and fmod(float(enemy.elapsed),4.0)>3.2:
		return 2.3
	return 1.0
