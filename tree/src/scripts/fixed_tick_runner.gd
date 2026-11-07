class_name RFixedTickRunner
extends RefCounted

static func tick_count(clock: RGameClock, frame_fps: float) -> int:
	if clock.paused:
		return 0
	return clampi(clock.multiplier,1,3)

static func simulate(clock: RGameClock, step: Callable) -> void:
	var times: int=tick_count(clock,60.0)
	for i in times:
		if clock.paused:
			break
		clock.advance_one()
		step.call()
