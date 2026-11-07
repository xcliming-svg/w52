class_name RViewportAdapter
extends RefCounted

# The 1325x950 game world is letterboxed inside its assigned battlefield panel.
static func fit_world(available: Vector2) -> Dictionary:
	var w: float=maxf(1.0,available.x)
	var h: float=maxf(1.0,available.y)
	var factor: float=minf(w/RBalance.WORLD_SIZE.x,h/RBalance.WORLD_SIZE.y)
	var offset: Vector2=(Vector2(w,h)-RBalance.WORLD_SIZE*factor)*0.5
	return {"scale":factor,"offset":offset,"world_size":RBalance.WORLD_SIZE}

static func panel_split(width: float, ratio: float) -> Dictionary:
	var left: float=maxf(1.0,width)*clampf(ratio,0.25,0.45)
	return {"tree":left,"battle":maxf(1.0,width)-left}

static func is_supported_aspect(width: float, height: float) -> bool:
	var ratio: float=width/maxf(1.0,height)
	return ratio>=1.40 and ratio<=2.80
