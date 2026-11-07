class_name RGameClock
extends RefCounted

const TICKS_PER_SECOND: int=RBalance.TICK_RATE
var tick: int=0
var multiplier: int=1
var paused: bool=false
var assisted: bool=false

func set_speed(value: int) -> void:
	multiplier=clampi(value,1,3)
	if multiplier>1:
		assisted=true

func set_paused(value: bool) -> void:
	if value:
		assisted=true
	paused=value

func consume_ticks() -> int:
	return 0 if paused else multiplier

func advance_one() -> void:
	if not paused and tick<0x7FFFFFFFFFFFFFFE:
		tick+=1

func elapsed_seconds() -> float:
	return float(tick)/float(TICKS_PER_SECOND)

func snapshot() -> Dictionary:
	return {"tick":tick,"multiplier":multiplier,"paused":paused,"assisted":assisted}

func restore(s: Dictionary) -> void:
	tick=maxi(0,int(s.get("tick",0)))
	multiplier=clampi(int(s.get("multiplier",1)),1,3)
	paused=bool(s.get("paused",false))
	assisted=bool(s.get("assisted",false))
