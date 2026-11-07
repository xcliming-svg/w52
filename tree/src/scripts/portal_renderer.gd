class_name RPortalRenderer
extends RefCounted

static func paint(canvas: CanvasItem, animation_time: float) -> void:
	var center: Vector2=RBalance.CENTER
	canvas.draw_colored_polygon(PackedVector2Array([
		center+Vector2(0.0,-24.0),center+Vector2(24.0,0.0),
		center+Vector2(0.0,24.0),center+Vector2(-24.0,0.0)
	]),Color("#000000"))
	var alpha: float=0.25+sin(animation_time*3.2)*0.08
	var tint: Color=Color("#8c5df1")
	tint.a=alpha
	canvas.draw_arc(center,33.0,0.0,TAU,32,tint,2.4,true)
