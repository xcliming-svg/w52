class_name RDebrisPhysics
extends RefCounted

# Visual-only moving rectangles/rings: never feed collision or damage events.
static func step(spark: Dictionary, delta: float) -> void:
	spark.pos=Vector2(spark.pos)+Vector2(spark.velocity)*delta
	spark.velocity=Vector2(spark.velocity)*maxf(0.0,1.0-delta*2.3)
	spark.rotation=float(spark.get("rotation",0.0))+float(spark.get("spin",0.0))*delta
	var p: Vector2=spark.pos
	var v: Vector2=spark.velocity
	if p.x<0.0 or p.x>RBalance.WORLD_SIZE.x:
		v.x=-v.x*0.4
	if p.y<0.0 or p.y>RBalance.WORLD_SIZE.y:
		v.y=-v.y*0.4
	spark.velocity=v
	spark.pos=p.clamp(Vector2.ZERO,RBalance.WORLD_SIZE)
