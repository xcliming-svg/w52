class_name RResumeRun
extends RefCounted

static func apply(run, saved: Dictionary) -> bool:
	if not RSaveSchema.valid({"schema_version":RSaveSchema.SCHEMA_VERSION,"run":saved}):
		return false
	run.seed_value=int(saved.seed)
	run.tick=int(saved.tick)
	run.clock.restore(saved.get("clock",{"tick":run.tick,"multiplier":saved.speed,"paused":saved.get("paused",false),"assisted":saved.assisted}))
	run.speed=clampi(int(saved.speed),1,3)
	run.assisted=bool(saved.assisted)
	run.paused=bool(saved.get("paused",false))
	run.rng.restore(saved.rng)
	run.economy.restore(saved.economy)
	run.tree.restore(saved.tree)
	run.train.restore(saved.train)
	run.field.restore(saved.field)
	run.weapons.restore(saved.weapons)
	run.milestones.restore(saved.get("milestones",{}))
	run.progression.restore(saved.get("progression",{}))
	run.events.restore(saved.get("event_bus",{}))
	run.highest_train=int(saved.get("highest_train",1))
	# Do not reorder active/storage cars on load: exact saved formation wins.
	return true
