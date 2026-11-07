class_name RPortalRenderer
extends RefCounted

static func paint(canvas: CanvasItem, animation_time: float) -> void:
	var center: Vector2 = RBalance.CENTER
	canvas.draw_circle(center,37.0,Color("#284339"))
	canvas.draw_circle(center,30.0,Color("#07100e"))
	canvas.draw_circle(center,19.0,Color("#010707"))
	var alpha: float = 0.3+sin(animation_time*1.1)*0.07
	var tint: Color = Color("#6d9681")
	tint.a = alpha
	canvas.draw_arc(center,40.0,0.0,TAU,48,tint,3.0,true)
