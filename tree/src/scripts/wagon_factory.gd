class_name RWagonFactory
extends RefCounted

static func build(registry: RData, id: String) -> Dictionary:
	if not registry.wagons.has(id):
		return {}
	return RWagonInstance.construct(registry.wagons[id])

static func build_from_spec(spec: Dictionary) -> Dictionary:
	if not spec.has("id") or not spec.has("family"):
		return {}
	return RWagonInstance.construct(spec)
