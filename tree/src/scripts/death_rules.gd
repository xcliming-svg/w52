class_name RDeathRules
extends RefCounted

static func reason(train: RTrain, enemies: REnemyField) -> String:
	if train.hull_hp<=0.0:
		return "기관차 파괴"
	if enemies.barrier<=0.0:
		return "방벽 붕괴"
	return ""

static func should_finish(run_status: String, cause: String) -> bool:
	return run_status=="RUN" and not cause.is_empty()
