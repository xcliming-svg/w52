class_name REventBus
extends RefCounted

signal economy_changed(category: String, transaction_id: String)
signal combat_hit(target_id: int, damage: float, kind: String, hit_id: String)
signal combat_kill(target_id: int, kill_id: String)
signal state_changed(from_state: String, to_state: String)
signal warning_raised(description: String)

var emitted: Dictionary={}

func emit_once(scope: String, key: String, payload: Variant=null) -> bool:
	var id: String=scope+":"+key
	if emitted.has(id):
		return false
	emitted[id]=true
	match scope:
		"economy":economy_changed.emit(str(payload),key)
		"kill":combat_kill.emit(int(payload),key)
		"warning":warning_raised.emit(str(payload))
	return true

func clear_run() -> void:
	emitted.clear()

func snapshot() -> Dictionary:
	return emitted.duplicate(true)

func restore(data: Dictionary) -> void:
	emitted=data.duplicate(true)
