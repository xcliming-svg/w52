class_name RCleanupLifecycle
extends RefCounted

static func clear_run(run) -> void:
	if run==null or not is_instance_valid(run):
		return
	if run.weapons!=null:
		run.weapons.initialize()
	if run.field!=null:
		run.field.enemies.clear()
		run.field.hostile_projectiles.clear()
	if run.visuals!=null:
		run.visuals.sparks.clear()
		run.visuals.numbers.clear()
		run.visuals.flashes.clear()

static func disconnect_if_connected(emitter: Signal, method: Callable) -> void:
	if emitter.is_connected(method):
		emitter.disconnect(method)
