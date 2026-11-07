class_name RAutosave
extends RefCounted

const PERIOD_TICKS: int=60*RBalance.TICK_RATE
var last_tick: int=-1

func when_due(run_snapshot: Dictionary) -> bool:
	var tick: int=int(run_snapshot.get("tick",0))
	if tick<=0 or tick%PERIOD_TICKS!=0 or tick==last_tick:
		return false
	last_tick=tick
	return RSaveStore.save_run(run_snapshot)

func on_menu_or_hide(run_snapshot: Dictionary) -> bool:
	if str(run_snapshot.get("status",""))!="RUN":
		return false
	last_tick=int(run_snapshot.get("tick",last_tick))
	return RSaveStore.save_run(run_snapshot)
