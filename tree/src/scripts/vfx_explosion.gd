class_name RVfxExplosion
extends RefCounted

static func color_for(family: String) -> Color:
	match family:
		"flame","rocket","mortar":return Color("#ff835d")
		"frost":return Color("#7edfff")
		"tesla":return Color("#96f7f8")
		"support":return Color("#81f9a8")
		"shockwave":return Color("#ffdc8c")
	return Color("#fff28c")

static func add(sparks: Array[Dictionary], pool: RDebrisPool, center: Vector2, radius: float, family: String) -> void:
	var cap: int=RBalance.MAX_DEBRIS_WEB if OS.has_feature("web") else RBalance.MAX_DEBRIS_PC
	if sparks.size()>=cap:
		return
	var ring: Dictionary=pool.borrow()
	ring.merge({"pos":center,"velocity":Vector2.ZERO,"life":0.25,"age":0.0,"color":color_for(family),"size":radius,"rotation":0.0,"spin":0.0,"ring":true},true)
	sparks.append(ring)
