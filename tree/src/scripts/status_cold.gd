class_name RStatusCold
extends RefCounted

static func apply_slow(enemy: Dictionary, fraction: float, seconds: float) -> void:
	var max_slow: float=0.40 if str(enemy.ai)=="boss_pattern" else 0.75
	enemy.slow=minf(max_slow,maxf(float(enemy.get("slow",0.0)),fraction))
	enemy.slow_time=maxf(float(enemy.get("slow_time",0.0)),maxf(0.0,seconds))

static func apply_freeze(enemy: Dictionary, seconds: float) -> void:
	var cap: float=0.15 if str(enemy.ai)=="boss_pattern" else 0.35
	enemy.frozen_time=maxf(float(enemy.get("frozen_time",0.0)),minf(seconds,cap))

static func release(enemy: Dictionary, delta: float) -> void:
	enemy.slow_time=maxf(0.0,float(enemy.get("slow_time",0.0))-delta)
	enemy.frozen_time=maxf(0.0,float(enemy.get("frozen_time",0.0))-delta)
	if float(enemy.slow_time)<=0.0:
		enemy.slow=0.0
