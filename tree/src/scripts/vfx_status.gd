class_name RVfxStatus
extends RefCounted

static func paint(canvas: CanvasItem, enemy: Dictionary) -> void:
	var point: Vector2=enemy.pos
	var radius: float=maxf(7.0,float(enemy.get("size",14.0))*0.5)
	if not enemy.get("burn",[]).is_empty():
		canvas.draw_arc(point,radius+7.0,PI,TAU,10,Color("#ff763d"),1.6,true)
	if float(enemy.get("slow",0.0))>0.0:
		canvas.draw_arc(point,radius+5.0,0.0,PI,10,Color("#85e8ff"),1.6,true)
	if float(enemy.get("shield",0.0))>0.0:
		canvas.draw_arc(point,radius+4.0,0.0,TAU,16,Color("#a1fbff"),1.2,true)
