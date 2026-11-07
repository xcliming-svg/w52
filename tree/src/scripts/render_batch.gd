class_name RRenderBatch
extends RefCounted

static func draw_many_rects(canvas: CanvasItem, rectangles: Array, colors: Array[Color]) -> void:
	for i in mini(rectangles.size(),colors.size()):
		var rect: Rect2=rectangles[i]
		canvas.draw_rect(rect,colors[i])

static func draw_many_points(canvas: CanvasItem, points: Array, color: Color, size: float=2.0) -> void:
	for point in points:
		canvas.draw_circle(Vector2(point),size,color)
