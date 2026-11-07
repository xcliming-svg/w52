class_name RRailRenderer
extends RefCounted

static func paint(canvas: CanvasItem) -> void:
	var path: PackedVector2Array=PackedVector2Array([
		RBalance.CORNERS[0],RBalance.CORNERS[1],
		RBalance.CORNERS[2],RBalance.CORNERS[3],RBalance.CORNERS[0]
	])
	canvas.draw_polyline(path,Color("#17364b"),15.0,true)
	canvas.draw_polyline(path,Color("#456b8b"),4.0,true)
	for arc in [0.0,1175.0,1950.0,3125.0]:
		var place: Vector2=RRailPath.point(arc)
		canvas.draw_circle(place,6.0,Color("#a0d7e3"))
