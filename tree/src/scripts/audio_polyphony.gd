class_name RAudioPolyphony
extends RefCounted

const LIMITS: Dictionary={"fire":12,"blast":8,"warning":2,"ui":2}
const GROUP_MS: int=90

static func available(category: String, last_ms: int, now_ms: int) -> bool:
	return LIMITS.has(category) and now_ms-last_ms>=GROUP_MS

static func cap(category: String) -> int:
	return int(LIMITS.get(category,0))

static func next_player(index: int, category: String) -> int:
	var max_voices: int=maxi(1,cap(category))
	return (index+1)%max_voices
