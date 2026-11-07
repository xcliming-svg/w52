class_name RHitFlash
extends RefCounted

static func add(flashes: Array[Dictionary], where: Vector2, low_flash: bool) -> void:
	if low_flash or flashes.size()>=40:
		return
	flashes.append({"pos":where,"age":0.0,"life":2.0/RBalance.TICK_RATE,"radius":14.0})

static func paint(canvas: CanvasItem, flashes: Array[Dictionary], low_flash: bool) -> void:
	if low_flash:
		return
	for flash in flashes:
		canvas.draw_circle(Vector2(flash.pos),float(flash.radius),Color(1.0,1.0,1.0,0.18))
