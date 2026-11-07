class_name RRailRenderer
extends RefCounted

# Collision remains on the original perimeter; this looks like a patrol route.
static func paint(canvas: CanvasItem) -> void:
	var path: PackedVector2Array = PackedVector2Array([
		RBalance.CORNERS[0],RBalance.CORNERS[1],
		RBalance.CORNERS[2],RBalance.CORNERS[3],RBalance.CORNERS[0]
	])
	canvas.draw_polyline(path,Color("#204540"),3.0,true)
	for arc in range(0,3900,65):
		var place: Vector2 = RRailPath.point(float(arc))
		canvas.draw_circle(place,2.5,Color("#447a67"))
	for corner in RBalance.CORNERS:
		canvas.draw_circle(corner,26.0,Color("#293e36"))
		canvas.draw_circle(corner,20.0,Color("#050b0c"))
		canvas.draw_arc(corner,24.0,0.0,TAU,32,Color("#668a65"),2.0,true)
