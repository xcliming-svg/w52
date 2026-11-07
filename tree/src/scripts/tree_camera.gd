class_name RTreeCamera
extends RefCounted

static func clamp_zoom(value: float) -> float:
	return clampf(value,0.20,1.60)

static func clamp_pan(value: Vector2) -> Vector2:
	return value.clamp(Vector2(-850.0,-850.0),Vector2(850.0,850.0))

static func to_screen(row: Dictionary, available: Vector2, pan: Vector2, zoom: float) -> Vector2:
	return available*0.50+(Vector2(float(row.get("x",0.0)),float(row.get("y",0.0)))+clamp_pan(pan))*clamp_zoom(zoom)

static func focus(row: Dictionary) -> Vector2:
	return clamp_pan(-Vector2(float(row.get("x",0.0)),float(row.get("y",0.0))))
