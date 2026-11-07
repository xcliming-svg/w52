class_name RWorldCoordinates
extends RefCounted

static func screen_to_world(screen: Vector2, scale: float, offset: Vector2) -> Vector2:
	return (screen-offset)/maxf(0.001,scale)

static func world_to_screen(world: Vector2, scale: float, offset: Vector2) -> Vector2:
	return offset+world*scale

static func inside_world(screen: Vector2, scale: float, offset: Vector2) -> bool:
	var local: Vector2=screen_to_world(screen,scale,offset)
	return Rect2(Vector2.ZERO,RBalance.WORLD_SIZE).has_point(local)
