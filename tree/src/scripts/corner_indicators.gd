class_name RCornerIndicators
extends RefCounted

static func counts(field: REnemyField) -> Array[Dictionary]:
	var entries: Array[Dictionary]=[]
	for i in 4:
		entries.append({"count":0,"earliest":INF,"damage":0.0})
	for e in field.enemies:
		if str(e.state)!="alive":
			continue
		var corner: int=clampi(int(e.target),0,3)
		entries[corner].count=int(entries[corner].count)+1
		entries[corner].earliest=minf(float(entries[corner].earliest),RCornerTargeting.eta(e))
		entries[corner].damage=float(entries[corner].damage)+float(e.escape_damage)
	return entries

static func paint(canvas: CanvasItem, field: REnemyField, font: Font) -> void:
	var entries: Array[Dictionary]=counts(field)
	for i in 4:
		var where: Vector2=RBalance.CORNERS[i]
		var danger: Dictionary=entries[i]
		var number: int=int(danger.count)
		var tint: Color=Color("#fa6b87") if number>0 else Color("#537591")
		canvas.draw_circle(where,23.0,tint.darkened(0.65))
		canvas.draw_arc(where,28.0,0.0,TAU,24,tint,2.0,true)
		if number>0:
			var earliest: float=float(danger.earliest)
			canvas.draw_string(font,where+Vector2(-29.0,-34.0),"%d / %.1fs" % [number,earliest],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ffb4bf"))
