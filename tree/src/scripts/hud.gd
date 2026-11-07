class_name RHud
extends RefCounted

static func summary(run) -> String:
	return " %02d:%02d | TP %.1f XP %.1f 고철 %.1f | 방벽 %.1f/30 기관차 %.0f/250 | %d/%d량 | 킬 %d " % [
		int(run.tick/3600),int(run.tick/60)%60,run.economy.tp,run.economy.xp,
		run.economy.scrap,run.field.barrier,run.train.hull_hp,
		run.train.active_count(),run.tree.capacity(),run.field.killed_count
	]

static func result_time(ticks: int) -> Dictionary:
	var seconds: int=maxi(0,ticks)/RBalance.TICK_RATE
	return {"hours":int(seconds/3600),"minutes":int(seconds/60)%60,"seconds":seconds%60}
