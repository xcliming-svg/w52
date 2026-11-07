class_name RTreeInteraction
extends RefCounted

static func hovered_node(registry: RData, point: Vector2, area: Vector2, pan: Vector2, zoom: float, radius: float=22.0, purchased: Dictionary={}) -> String:
	var closest: String = ""
	var best: float = radius
	for row in registry.ordered_nodes:
		var id: String = str(row.id)
		if not purchased.is_empty() and not purchased.has(id):
			var ready: bool = true
			for parent_id in row.get("requires",[]):
				if not purchased.has(str(parent_id)):
					ready = false
					break
			if not ready:
				continue
		var dist: float = point.distance_to(RTreeCamera.to_screen(row,area,pan,zoom))
		if dist < best:
			best = dist
			closest = id
	return closest

static func pan_delta(previous: Vector2, current: Vector2, zoom: float, pan: Vector2) -> Vector2:
	return RTreeCamera.clamp_pan(pan+(current-previous)/maxf(0.05,zoom))

static func zoom_wheel(current: float, upward: bool) -> float:
	return RTreeCamera.clamp_zoom(current*(1.15 if upward else 1.0/1.15))
