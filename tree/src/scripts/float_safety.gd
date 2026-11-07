class_name RFloatSafety
extends RefCounted

static func safe_mod(value: float, perimeter: float) -> float:
	return 0.0 if not is_finite(value) or perimeter<=0.0 else fposmod(value,perimeter)

static func bounded_value(value: float, low: float, high: float, fallback: float=0.0) -> float:
	return clampf(value,low,high) if is_finite(value) else fallback

static func next_counter(value: int) -> int:
	return maxi(0,value+1) if value<0x7FFFFFFFFFFFFFFE else value

static func valid_snapshot_numbers(snapshot: Dictionary) -> bool:
	for key in ["distance","hull_hp"]:
		if snapshot.has(key) and not is_finite(float(snapshot[key])):
			return false
	return true
