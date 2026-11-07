class_name RDebrisSplit
extends RefCounted

static func scatter(sparks: Array[Dictionary], pool: RDebrisPool, where: Vector2, size: float, color: Color, rng: RandomNumberGenerator, quality: float) -> void:
	var count: int=clampi(int(4.0+size*0.8),4,12)
	if quality<0.3:
		count=4
	var cap: int=RBalance.MAX_DEBRIS_WEB if OS.has_feature("web") else RBalance.MAX_DEBRIS_PC
	for i in count:
		if sparks.size()>=cap:
			return
		var velocity: Vector2=Vector2.from_angle(rng.randf_range(0.0,TAU))*rng.randf_range(30.0,160.0)
		var shard: Dictionary=pool.borrow()
		shard.merge({"pos":where,"velocity":velocity,"life":rng.randf_range(0.35,1.25),"age":0.0,"color":color,"size":rng.randf_range(2.0,6.0),"rotation":0.0,"spin":rng.randf_range(-12.0,12.0),"ring":false},true)
		sparks.append(shard)
