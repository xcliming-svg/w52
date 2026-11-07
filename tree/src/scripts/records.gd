class_name RRecords
extends RefCounted

static func submit(summary: Dictionary) -> bool:
	if str(summary.get("end_reason","")).is_empty():
		return false
	return RSaveStore.add_record(summary)

static func all() -> Array:
	return RSaveStore.records()

static func ordered_by_survival() -> Array:
	var records: Array=all()
	records.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.get("tick",0))>int(b.get("tick",0)))
	return records
